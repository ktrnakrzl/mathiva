"""Progress calculations kept independent of HTTP routing.

Read only the columns needed for statistics, in batches, without constructing
ORM entities or retaining the student's entire attempt history in memory.
"""
from __future__ import annotations

from collections import defaultdict
from collections.abc import Iterable
from datetime import date, timedelta
from typing import List

from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.database.models import QuizAttempt

POINTS_PER_CORRECT = 10


def get_progress(db: Session, user_id: int) -> UserProgressResponse:
    attempts = db.query(
        QuizAttempt.subject_id, QuizAttempt.topic_id, QuizAttempt.concept_id,
        QuizAttempt.difficulty, QuizAttempt.is_correct,
        QuizAttempt.elapsed_seconds, QuizAttempt.created_at,
    ).filter(QuizAttempt.user_id == user_id).yield_per(500)
    return aggregate_progress(attempts)


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


def aggregate_progress(attempts: Iterable) -> UserProgressResponse:
    """Consume projected rows in the column order used by get_progress."""
    total_attempts = total_correct = total_study_time_seconds = 0
    day_counts = defaultdict(int)
    today = date.today()

    by_subject_raw = defaultdict(lambda: {"attempts": 0, "correct": 0, "total_elapsed_seconds": 0})
    by_topic_raw = defaultdict(lambda: {"attempts": 0, "correct": 0})
    by_topic_difficulty_raw = defaultdict(lambda: {"attempts": 0, "correct": 0})
    by_concept_raw = defaultdict(lambda: {"attempts": 0, "correct": 0})
    best_time_raw = {}

    for a in attempts:
        subject_id, topic_id, concept_id, difficulty, is_correct, elapsed_seconds, created_at = a
        total_attempts += 1
        total_correct += int(is_correct)
        total_study_time_seconds += elapsed_seconds
        day_counts[created_at.date()] += 1
        s = by_subject_raw[subject_id]
        s["attempts"] += 1
        s["correct"] += 1 if is_correct else 0
        s["total_elapsed_seconds"] += elapsed_seconds

        t = by_topic_raw[(subject_id, topic_id)]
        t["attempts"] += 1
        t["correct"] += 1 if is_correct else 0

        td = by_topic_difficulty_raw[(topic_id, difficulty)]
        td["attempts"] += 1
        td["correct"] += 1 if is_correct else 0

        c = by_concept_raw[concept_id]
        c["attempts"] += 1
        c["correct"] += 1 if is_correct else 0

        if is_correct:
            current_best = best_time_raw.get(concept_id)
            if current_best is None or elapsed_seconds < current_best:
                best_time_raw[concept_id] = elapsed_seconds

    overall_accuracy = _accuracy(total_correct, total_attempts)
    points = total_correct * POINTS_PER_CORRECT
    streak = 0
    cursor = today
    if cursor not in day_counts:
        cursor -= timedelta(days=1)
    while cursor in day_counts:
        streak += 1
        cursor -= timedelta(days=1)

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

    last_7_days = []
    for i in range(6, -1, -1):
        d = today - timedelta(days=i)
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
            earned=any(seconds < 10 for seconds in best_time_raw.values()),
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


