from collections import defaultdict
from datetime import date, datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session
from typing import List, Optional

from app.database.db import get_db
from app.database.models import QuizAttempt, QuizQuestion, User
from app.services.auth_service import get_current_user
from app.services.question_generator import generate_question
from app.services.quiz_templates import has_template
from app.services import adaptive_quiz, quiz_templates

router = APIRouter(prefix="/api", tags=["quiz"])

# Simple fixed point value per correct answer -- no existing points model to
# reference, so defined here explicitly and kept as one tunable constant.
POINTS_PER_CORRECT = 10


class QuizSubmitRequest(BaseModel):
    subject_id: str
    topic_id: str
    lesson_id: str
    concept_id: str
    difficulty: str
    selected_answer: Optional[str] = None
    # Trusted as-is from the client: the problem bank (correct answers)
    # lives only in the Flutter app's static local data, with no backend
    # equivalent to validate against. Re-deriving correctness server-side
    # would mean duplicating the whole content tree into the backend, which
    # is out of scope here -- accepted limitation for a thesis-scope app.
    # The JWT at least ties every attempt to a real account.
    is_correct: bool
    elapsed_seconds: int


class QuizSubmitResponse(BaseModel):
    attempt_id: int
    recorded_at: datetime


@router.post("/quiz/submit", response_model=QuizSubmitResponse)
def submit_quiz_attempt(
    request: QuizSubmitRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """LEGACY path: trusts the client's is_correct (see QuizSubmitRequest).
    Superseded by the generated-quiz flow below (GET /api/quiz/next +
    POST /api/quiz/answer), where the server owns correctness. Kept working
    only until the frontend is moved over, then it should be removed."""
    try:
        attempt = QuizAttempt(
            user_id=current_user.id,
            subject_id=request.subject_id,
            topic_id=request.topic_id,
            lesson_id=request.lesson_id,
            concept_id=request.concept_id,
            difficulty=request.difficulty,
            selected_answer=request.selected_answer,
            is_correct=request.is_correct,
            elapsed_seconds=request.elapsed_seconds,
        )
        db.add(attempt)
        db.commit()
        db.refresh(attempt)
        return QuizSubmitResponse(attempt_id=attempt.id, recorded_at=attempt.created_at)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# --------------------------------------------------------------------------
# Generated-quiz flow -- the server owns both the question and the grading.
# --------------------------------------------------------------------------

class NextQuestionResponse(BaseModel):
    question_id: int
    subject_id: str
    topic_id: str
    lesson_id: str
    concept_id: str
    difficulty: str
    question: str
    choices: List[str]
    # Deliberately NO correct_answer / steps here -- the client must not see
    # them until after it answers (POST /api/quiz/answer).


@router.get("/quiz/next", response_model=NextQuestionResponse)
def next_question(
    subject_id: str,
    topic_id: str,
    lesson_id: str,
    concept_id: str,
    difficulty: str = "Easy",
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Generate a fresh personalized question for this student and concept,
    persist it (with its correct answer), and return everything except the
    answer."""
    if not has_template(concept_id):
        raise HTTPException(
            status_code=422,
            detail=f"No question template for concept '{concept_id}' yet.",
        )
    try:
        generated = generate_question(concept_id, difficulty)

        question = QuizQuestion(
            user_id=current_user.id,
            subject_id=subject_id,
            topic_id=topic_id,
            lesson_id=lesson_id,
            concept_id=concept_id,
            difficulty=difficulty,
            template_id=generated.template_id,
            question_text=generated.question_text,
            choices=generated.choices,
            correct_answer=generated.correct_answer,
            steps=generated.steps,
            answered=False,
        )
        db.add(question)
        db.commit()
        db.refresh(question)

        return NextQuestionResponse(
            question_id=question.id,
            subject_id=question.subject_id,
            topic_id=question.topic_id,
            lesson_id=question.lesson_id,
            concept_id=question.concept_id,
            difficulty=question.difficulty,
            question=question.question_text,
            choices=question.choices,
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


class AdaptiveNextRequest(BaseModel):
    subject_id: str
    topic_id: str
    lesson_id: str
    # The concepts available where the student currently is (the content tree
    # lives in the app, not the backend). The server picks the best one for THIS
    # student from these; if empty, it considers every concept it can generate.
    candidate_concepts: List[str] = []


@router.post("/quiz/next-adaptive", response_model=NextQuestionResponse)
def next_question_adaptive(
    request: AdaptiveNextRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Personalized counterpart to /quiz/next.

    Instead of the client choosing the concept and difficulty, the SERVER picks
    them from this student's own attempt history -- weighting toward weak/unseen
    concepts and adapting the difficulty to recent performance -- then generates,
    stores, and serves the question (minus the answer). The response reports which
    concept + difficulty were chosen so the UI can show what's being practiced.
    """
    # Candidate pool: the lesson's concepts we can actually generate; if none are
    # usable, fall back to every templated concept so the endpoint still works.
    pool = [c for c in request.candidate_concepts if has_template(c)]
    if not pool:
        pool = quiz_templates.list_concepts()

    attempts = (
        db.query(QuizAttempt).filter(QuizAttempt.user_id == current_user.id).all()
    )
    concept_id, difficulty = adaptive_quiz.choose_next(attempts, pool)

    try:
        generated = generate_question(concept_id, difficulty)

        question = QuizQuestion(
            user_id=current_user.id,
            subject_id=request.subject_id,
            topic_id=request.topic_id,
            lesson_id=request.lesson_id,
            concept_id=concept_id,
            difficulty=difficulty,
            template_id=generated.template_id,
            question_text=generated.question_text,
            choices=generated.choices,
            correct_answer=generated.correct_answer,
            steps=generated.steps,
            answered=False,
        )
        db.add(question)
        db.commit()
        db.refresh(question)

        return NextQuestionResponse(
            question_id=question.id,
            subject_id=question.subject_id,
            topic_id=question.topic_id,
            lesson_id=question.lesson_id,
            concept_id=question.concept_id,
            difficulty=question.difficulty,
            question=question.question_text,
            choices=question.choices,
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


class AnswerRequest(BaseModel):
    question_id: int
    selected_answer: str
    elapsed_seconds: int


class AnswerResponse(BaseModel):
    attempt_id: int
    is_correct: bool
    correct_answer: str
    steps: List[str]


@router.post("/quiz/answer", response_model=AnswerResponse)
def answer_question(
    request: AnswerRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Grade a previously-served question. The server compares the submitted
    choice against the answer it stored at generation time -- the client never
    supplies is_correct -- then records the attempt and reveals the answer +
    steps for the result screen."""
    question = (
        db.query(QuizQuestion)
        .filter(
            QuizQuestion.id == request.question_id,
            QuizQuestion.user_id == current_user.id,
        )
        .first()
    )
    if question is None:
        raise HTTPException(status_code=404, detail="Question not found.")
    if question.answered:
        # One generated question = one attempt; block replay so stats can't be
        # inflated by re-submitting the same question.
        raise HTTPException(status_code=409, detail="Question already answered.")

    try:
        is_correct = request.selected_answer.strip() == question.correct_answer.strip()

        # Subject/topic/lesson/concept/difficulty are taken from the stored
        # question, not the request, so the client can't misattribute an attempt.
        attempt = QuizAttempt(
            user_id=current_user.id,
            subject_id=question.subject_id,
            topic_id=question.topic_id,
            lesson_id=question.lesson_id,
            concept_id=question.concept_id,
            difficulty=question.difficulty,
            selected_answer=request.selected_answer,
            is_correct=is_correct,
            elapsed_seconds=request.elapsed_seconds,
            question_id=question.id,
        )
        question.answered = True
        db.add(attempt)
        db.commit()
        db.refresh(attempt)

        return AnswerResponse(
            attempt_id=attempt.id,
            is_correct=is_correct,
            correct_answer=question.correct_answer,
            steps=question.steps,
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


class SubjectStat(BaseModel):
    subject_id: str
    attempts: int
    correct: int
    accuracy: float
    total_elapsed_seconds: int


class TopicStat(BaseModel):
    subject_id: str
    topic_id: str
    attempts: int
    correct: int
    accuracy: float


class TopicDifficultyStat(BaseModel):
    topic_id: str
    difficulty: str
    attempts: int
    correct: int
    accuracy: float


class ConceptStat(BaseModel):
    concept_id: str
    attempts: int
    correct: int
    accuracy: float


class ConceptBestTime(BaseModel):
    concept_id: str
    best_elapsed_seconds: int


class DayActivity(BaseModel):
    date: str
    attempts: int


class Achievement(BaseModel):
    id: str
    label: str
    description: str
    earned: bool


class UserProgressResponse(BaseModel):
    total_attempts: int
    total_correct: int
    overall_accuracy: float
    current_streak_days: int
    total_study_time_seconds: int
    points: int
    by_subject: List[SubjectStat]
    by_topic: List[TopicStat]
    by_topic_difficulty: List[TopicDifficultyStat]
    by_concept: List[ConceptStat]
    best_time_by_concept: List[ConceptBestTime]
    last_7_days: List[DayActivity]
    achievements: List[Achievement]


def _accuracy(correct: int, attempts: int) -> float:
    return round(100 * correct / attempts, 1) if attempts else 0.0


def _aggregate_progress(attempts: List[QuizAttempt]) -> UserProgressResponse:
    total_attempts = len(attempts)
    total_correct = sum(1 for a in attempts if a.is_correct)
    overall_accuracy = _accuracy(total_correct, total_attempts)
    total_study_time_seconds = sum(a.elapsed_seconds for a in attempts)
    points = total_correct * POINTS_PER_CORRECT

    # Streak: distinct active days, walked backward from today. If today
    # has no activity yet, start from yesterday so an in-progress streak
    # isn't shown as broken before the day is even over.
    active_days = {a.created_at.date() for a in attempts}
    streak = 0
    cursor = date.today()
    if cursor not in active_days:
        cursor -= timedelta(days=1)
    while cursor in active_days:
        streak += 1
        cursor -= timedelta(days=1)

    by_subject_raw = defaultdict(lambda: {"attempts": 0, "correct": 0, "total_elapsed_seconds": 0})
    by_topic_raw = defaultdict(lambda: {"attempts": 0, "correct": 0})
    by_topic_difficulty_raw = defaultdict(lambda: {"attempts": 0, "correct": 0})
    by_concept_raw = defaultdict(lambda: {"attempts": 0, "correct": 0})
    best_time_raw = {}

    for a in attempts:
        s = by_subject_raw[a.subject_id]
        s["attempts"] += 1
        s["correct"] += 1 if a.is_correct else 0
        s["total_elapsed_seconds"] += a.elapsed_seconds

        t = by_topic_raw[(a.subject_id, a.topic_id)]
        t["attempts"] += 1
        t["correct"] += 1 if a.is_correct else 0

        td = by_topic_difficulty_raw[(a.topic_id, a.difficulty)]
        td["attempts"] += 1
        td["correct"] += 1 if a.is_correct else 0

        c = by_concept_raw[a.concept_id]
        c["attempts"] += 1
        c["correct"] += 1 if a.is_correct else 0

        if a.is_correct:
            current_best = best_time_raw.get(a.concept_id)
            if current_best is None or a.elapsed_seconds < current_best:
                best_time_raw[a.concept_id] = a.elapsed_seconds

    by_subject = [
        SubjectStat(
            subject_id=subject_id,
            attempts=v["attempts"],
            correct=v["correct"],
            accuracy=_accuracy(v["correct"], v["attempts"]),
            total_elapsed_seconds=v["total_elapsed_seconds"],
        )
        for subject_id, v in by_subject_raw.items()
    ]

    by_topic = [
        TopicStat(
            subject_id=subject_id,
            topic_id=topic_id,
            attempts=v["attempts"],
            correct=v["correct"],
            accuracy=_accuracy(v["correct"], v["attempts"]),
        )
        for (subject_id, topic_id), v in by_topic_raw.items()
    ]

    by_topic_difficulty = [
        TopicDifficultyStat(
            topic_id=topic_id,
            difficulty=difficulty,
            attempts=v["attempts"],
            correct=v["correct"],
            accuracy=_accuracy(v["correct"], v["attempts"]),
        )
        for (topic_id, difficulty), v in by_topic_difficulty_raw.items()
    ]

    by_concept = [
        ConceptStat(
            concept_id=concept_id,
            attempts=v["attempts"],
            correct=v["correct"],
            accuracy=_accuracy(v["correct"], v["attempts"]),
        )
        for concept_id, v in by_concept_raw.items()
    ]

    best_time_by_concept = [
        ConceptBestTime(concept_id=concept_id, best_elapsed_seconds=seconds)
        for concept_id, seconds in best_time_raw.items()
    ]

    day_counts = defaultdict(int)
    for a in attempts:
        day_counts[a.created_at.date()] += 1
    last_7_days = []
    for i in range(6, -1, -1):
        d = date.today() - timedelta(days=i)
        last_7_days.append(DayActivity(date=d.isoformat(), attempts=day_counts.get(d, 0)))

    by_topic_lookup = {t.topic_id: t for t in by_topic}
    achievements = [
        Achievement(
            id="first_steps",
            label="First Steps",
            description="Solve your first problem",
            earned=total_attempts >= 1,
        ),
        Achievement(
            id="seven_day_streak",
            label="7-Day Streak",
            description="Practice 7 days in a row",
            earned=streak >= 7,
        ),
        Achievement(
            id="speed_demon",
            label="Speed Demon",
            description="Solve a problem in under 10 seconds",
            earned=any(a.is_correct and a.elapsed_seconds < 10 for a in attempts),
        ),
        Achievement(
            id="perfect_ten",
            label="On a Roll",
            description="Get 10 correct answers",
            earned=total_correct >= 10,
        ),
        Achievement(
            id="topic_master",
            label="Topic Master",
            description="Reach 90% accuracy in any topic (5+ attempts)",
            earned=any(t.accuracy >= 90 and t.attempts >= 5 for t in by_topic_lookup.values()),
        ),
        Achievement(
            id="dedicated_learner",
            label="Dedicated Learner",
            description="Log 1 hour of total study time",
            earned=total_study_time_seconds >= 3600,
        ),
    ]

    return UserProgressResponse(
        total_attempts=total_attempts,
        total_correct=total_correct,
        overall_accuracy=overall_accuracy,
        current_streak_days=streak,
        total_study_time_seconds=total_study_time_seconds,
        points=points,
        by_subject=by_subject,
        by_topic=by_topic,
        by_topic_difficulty=by_topic_difficulty,
        by_concept=by_concept,
        best_time_by_concept=best_time_by_concept,
        last_7_days=last_7_days,
        achievements=achievements,
    )


@router.get("/user/progress", response_model=UserProgressResponse)
def get_user_progress(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    try:
        attempts = (
            db.query(QuizAttempt)
            .filter(QuizAttempt.user_id == current_user.id)
            .all()
        )
        return _aggregate_progress(attempts)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
