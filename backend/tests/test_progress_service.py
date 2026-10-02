from datetime import datetime, timedelta
from collections import namedtuple

from app.services.progress_service import aggregate_progress


def test_progress_consumes_single_pass_history():
    today = datetime.now().replace(hour=12)
    Attempt = namedtuple("Attempt", "subject_id topic_id concept_id difficulty is_correct elapsed_seconds created_at")
    rows = [Attempt(
        subject_id="math", topic_id="algebra", concept_id="linear",
        difficulty="Easy", is_correct=i != 0, elapsed_seconds=5 + i,
        created_at=today - timedelta(days=i),
    ) for i in range(7)]
    result = aggregate_progress(iter(rows))
    assert result.total_attempts == 7
    assert result.total_correct == 6
    assert result.total_study_time_seconds == 56
    assert result.current_streak_days == 7
    assert result.points == 60
    assert result.best_time_by_concept[0].best_elapsed_seconds == 6
    assert [day.attempts for day in result.last_7_days] == [1] * 7
    assert next(a for a in result.achievements if a.id == "speed_demon").earned


def test_empty_history():
    result = aggregate_progress(iter(()))
    assert result.total_attempts == result.current_streak_days == 0
    assert result.overall_accuracy == 0
    assert result.by_subject == []
    assert not any(a.earned for a in result.achievements)
