from datetime import datetime

from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Integer, JSON, String

from .db import Base


class User(Base):
    """A registered student account. Matches the `users` table in
    MATHIVA_SYSTEM_SPECIFICATION.md section 5."""

    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, nullable=False, index=True)
    password_hash = Column(String(255), nullable=False)
    full_name = Column(String(255), nullable=False)
    section = Column(String(100), nullable=True)
    enrollment_status = Column(String(50), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class QuizAttempt(Base):
    """One submitted practice problem. The active practice flow is always
    exactly one question per submission (no multi-question quiz session
    concept exists anywhere in the app), so this is a single flat table
    rather than a quiz_attempts/quiz_responses pair -- every stat the
    frontend needs (per-subject/topic/concept accuracy, streak, study time,
    best time, weekly activity) is a GROUP BY over this one table."""

    __tablename__ = "quiz_attempts"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)

    subject_id = Column(String(100), nullable=False, index=True)
    topic_id = Column(String(100), nullable=False, index=True)
    lesson_id = Column(String(100), nullable=False)
    concept_id = Column(String(100), nullable=False, index=True)
    difficulty = Column(String(20), nullable=False)

    selected_answer = Column(String(500), nullable=True)
    is_correct = Column(Boolean, nullable=False)
    elapsed_seconds = Column(Integer, nullable=False)

    # Links the attempt back to the server-generated question it answered, when
    # it came from the generated-quiz flow (GET /api/quiz/next). Nullable so
    # rows from the legacy client-trusted /api/quiz/submit path still fit.
    question_id = Column(Integer, ForeignKey("quiz_questions.id"), nullable=True, index=True)

    created_at = Column(DateTime, default=datetime.utcnow, index=True)


class QuizQuestion(Base):
    """One personalized question generated server-side for a specific student.

    This is what makes grading trustworthy: the question is built here (the
    numbers are randomized and the answer is COMPUTED in Python by a parametric
    template, then the wording is optionally rephrased by the LLM), the correct
    answer is stored in this row, and only the question text + shuffled choices
    are sent to the client. The client never sees `correct_answer` until after
    it submits, so it cannot fake the verdict -- the server grades the
    submitted choice against `correct_answer` itself."""

    __tablename__ = "quiz_questions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)

    subject_id = Column(String(100), nullable=False)
    topic_id = Column(String(100), nullable=False)
    lesson_id = Column(String(100), nullable=False)
    concept_id = Column(String(100), nullable=False, index=True)
    difficulty = Column(String(20), nullable=False)

    # Which parametric template produced this question -- useful for debugging
    # and for spotting a template that generates bad questions.
    template_id = Column(String(100), nullable=False)

    question_text = Column(String(1000), nullable=False)
    # The shuffled multiple-choice options actually shown to the student, and
    # the provably-correct one among them. Stored as JSON lists (SQLite keeps
    # these as TEXT; no extra setup needed).
    choices = Column(JSON, nullable=False)
    correct_answer = Column(String(500), nullable=False)
    steps = Column(JSON, nullable=False)

    # Set once the student answers, so a question can't be re-submitted to
    # rack up duplicate attempts (one generated question = one attempt).
    answered = Column(Boolean, nullable=False, default=False)

    created_at = Column(DateTime, default=datetime.utcnow, index=True)
