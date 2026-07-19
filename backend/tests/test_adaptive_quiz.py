"""Tests for the personalized quiz selection policy (adaptive_quiz).

These are pure-function tests over fake attempt rows -- no DB, no generation --
so they pin down the actual pedagogy: weak/unseen concepts are favoured, and
difficulty tracks recent performance.
"""

import random
from datetime import datetime, timedelta
from types import SimpleNamespace

import pytest

from app.services import adaptive_quiz


def _attempt(concept_id, is_correct, difficulty="Easy", minute=0):
    return SimpleNamespace(
        concept_id=concept_id,
        is_correct=is_correct,
        difficulty=difficulty,
        created_at=datetime(2026, 1, 1) + timedelta(minutes=minute),
    )


# ---- concept_score ---------------------------------------------------------

def test_unseen_concept_gets_the_unseen_score():
    assert adaptive_quiz.concept_score([], "mean") == pytest.approx(0.7)


def test_all_wrong_concept_scores_highest():
    attempts = [_attempt("mean", False), _attempt("mean", False)]
    assert adaptive_quiz.concept_score(attempts, "mean") == pytest.approx(1.0)


def test_mastered_concept_keeps_a_small_floor():
    attempts = [_attempt("mean", True) for _ in range(5)]
    # accuracy 1.0 -> 0.0, but floored so it can still resurface occasionally.
    assert adaptive_quiz.concept_score(attempts, "mean") == pytest.approx(0.05)


def test_half_right_scores_by_one_minus_accuracy():
    attempts = [_attempt("mean", True), _attempt("mean", False)]
    assert adaptive_quiz.concept_score(attempts, "mean") == pytest.approx(0.5)


# ---- select_concept (weighted toward weakness) -----------------------------

def test_single_candidate_is_returned():
    rng = random.Random(0)
    assert adaptive_quiz.select_concept([], ["mean"], rng) == "mean"


def test_weak_concept_is_chosen_far_more_often_than_a_mastered_one():
    # "weak" = never right (score 1.0); "strong" = always right (score 0.05).
    attempts = (
        [_attempt("weak", False) for _ in range(4)]
        + [_attempt("strong", True) for _ in range(4)]
    )
    rng = random.Random(42)
    picks = [adaptive_quiz.select_concept(attempts, ["weak", "strong"], rng)
             for _ in range(300)]
    weak = picks.count("weak")
    assert weak > picks.count("strong")
    assert weak > 200  # ~95% expected; comfortably above half


# ---- select_difficulty (adapts to recent performance) ----------------------

def test_new_concept_starts_easy():
    assert adaptive_quiz.select_difficulty([], "mean") == "Easy"


def test_doing_well_steps_difficulty_up():
    attempts = [_attempt("mean", True, "Easy", 0), _attempt("mean", True, "Easy", 1)]
    assert adaptive_quiz.select_difficulty(attempts, "mean") == "Medium"


def test_steps_up_through_medium_to_hard():
    attempts = [_attempt("mean", True, "Medium", 0), _attempt("mean", True, "Medium", 1)]
    assert adaptive_quiz.select_difficulty(attempts, "mean") == "Hard"


def test_hard_is_the_ceiling():
    attempts = [_attempt("mean", True, "Hard", 0), _attempt("mean", True, "Hard", 1)]
    assert adaptive_quiz.select_difficulty(attempts, "mean") == "Hard"


def test_struggling_steps_difficulty_down():
    attempts = [_attempt("mean", False, "Medium", i) for i in range(3)]
    assert adaptive_quiz.select_difficulty(attempts, "mean") == "Easy"


def test_middling_performance_holds_difficulty():
    attempts = [
        _attempt("mean", True, "Medium", 0),
        _attempt("mean", False, "Medium", 1),
    ]  # accuracy 0.5 -> neither up nor down
    assert adaptive_quiz.select_difficulty(attempts, "mean") == "Medium"


def test_single_correct_does_not_step_up():
    # Needs at least 2 recent attempts before promoting difficulty.
    attempts = [_attempt("mean", True, "Easy", 0)]
    assert adaptive_quiz.select_difficulty(attempts, "mean") == "Easy"


def test_only_recent_attempts_drive_difficulty():
    # Old failures shouldn't hold a now-improving student back: the window is the
    # last few attempts, which here are all correct -> step up.
    attempts = (
        [_attempt("mean", False, "Easy", i) for i in range(3)]        # old, wrong
        + [_attempt("mean", True, "Easy", 10 + i) for i in range(4)]  # recent, right
    )
    assert adaptive_quiz.select_difficulty(attempts, "mean") == "Medium"


# ---- choose_next -----------------------------------------------------------

def test_choose_next_ignores_concepts_without_templates():
    concept, difficulty = adaptive_quiz.choose_next(
        [], ["mean", "definitely_not_a_real_concept"], random.Random(0)
    )
    assert concept == "mean"  # the only template-backed candidate
    assert difficulty in adaptive_quiz.DIFFICULTY_LEVELS


def test_choose_next_raises_when_no_candidate_has_a_template():
    with pytest.raises(ValueError):
        adaptive_quiz.choose_next([], ["nope", "still_nope"], random.Random(0))
