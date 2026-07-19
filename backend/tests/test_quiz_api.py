"""Tests for the generated-quiz flow and progress aggregation.

The server owns the correct answer: /quiz/next must not leak it, /quiz/answer
grades against the stored value, and a question can't be answered twice. These
tests never hit Ollama -- /quiz/next asks for an LLM rephrase, but with Ollama
down the generator falls back to the template wording, which is fine here.
"""

import re

import pytest

from app.services import question_generator


@pytest.fixture(autouse=True)
def _deterministic_question_wording(monkeypatch):
    """Serve the template wording verbatim, never an LLM rephrase.

    These tests re-derive the correct answer from the question text, which only
    holds for the stable template wording. With Ollama running, /api/quiz/next
    reworded via phi could add stray numbers (e.g. "the mean of these 3 numbers:
    4, 8, 6") -- valid for a student but breaking the naive re-derivation here.
    Patching the rephrase to a no-op enforces this module's "never hit Ollama"
    assumption whether or not Ollama is actually up, so the tests are
    deterministic."""
    monkeypatch.setattr(
        question_generator, "_rephrase", lambda question, must_keep: question
    )


# A concept that has a template and an easily re-derivable answer.
CONCEPT = {
    "subject_id": "general_math",
    "topic_id": "statistics",
    "lesson_id": "central_tendency",
    "concept_id": "mean",
    "difficulty": "Easy",
}


def _mean_answer_from_question(question_text):
    values = [int(n) for n in re.findall(r"-?\d+", question_text)]
    return str(sum(values) // len(values))


def _get_next(client, headers):
    r = client.get("/api/quiz/next", params=CONCEPT, headers=headers)
    assert r.status_code == 200, r.text
    return r.json()


def test_next_question_hides_the_answer(client, auth_headers):
    q = _get_next(client, auth_headers)
    assert "question_id" in q
    assert len(q["choices"]) == 4
    # The whole point: the answer and worked steps must not be in the payload.
    assert "correct_answer" not in q
    assert "steps" not in q


def test_next_requires_auth(client):
    r = client.get("/api/quiz/next", params=CONCEPT)
    assert r.status_code == 401


def test_next_unknown_concept_returns_422(client, auth_headers):
    params = {**CONCEPT, "concept_id": "no_such_concept"}
    r = client.get("/api/quiz/next", params=params, headers=auth_headers)
    assert r.status_code == 422


def test_answer_grades_a_correct_submission(client, auth_headers):
    q = _get_next(client, auth_headers)
    correct = _mean_answer_from_question(q["question"])
    assert correct in q["choices"], "re-derived answer should be one of the choices"

    r = client.post(
        "/api/quiz/answer",
        json={"question_id": q["question_id"], "selected_answer": correct, "elapsed_seconds": 12},
        headers=auth_headers,
    )
    assert r.status_code == 200
    body = r.json()
    assert body["is_correct"] is True
    assert body["correct_answer"] == correct
    assert body["steps"], "grading response should reveal the worked steps"


def test_answer_grades_a_wrong_submission(client, auth_headers):
    q = _get_next(client, auth_headers)
    correct = _mean_answer_from_question(q["question"])
    wrong = next(c for c in q["choices"] if c != correct)

    r = client.post(
        "/api/quiz/answer",
        json={"question_id": q["question_id"], "selected_answer": wrong, "elapsed_seconds": 5},
        headers=auth_headers,
    )
    assert r.status_code == 200
    body = r.json()
    assert body["is_correct"] is False
    # Even on a wrong answer the server reveals the real answer for the result screen.
    assert body["correct_answer"] == correct


def test_a_question_cannot_be_answered_twice(client, auth_headers):
    q = _get_next(client, auth_headers)
    payload = {
        "question_id": q["question_id"],
        "selected_answer": q["choices"][0],
        "elapsed_seconds": 8,
    }
    assert client.post("/api/quiz/answer", json=payload, headers=auth_headers).status_code == 200
    # Replaying the same question must be blocked so stats can't be inflated.
    assert client.post("/api/quiz/answer", json=payload, headers=auth_headers).status_code == 409


def test_answering_someone_elses_question_is_not_found(client, auth_headers):
    q = _get_next(client, auth_headers)

    # A second, different user.
    other = {"email": "other@example.com", "password": "password123", "full_name": "Other"}
    client.post("/auth/register", json=other)
    other_token = client.post(
        "/auth/login", json={"email": other["email"], "password": other["password"]}
    ).json()["access_token"]
    other_headers = {"Authorization": f"Bearer {other_token}"}

    r = client.post(
        "/api/quiz/answer",
        json={"question_id": q["question_id"], "selected_answer": q["choices"][0], "elapsed_seconds": 3},
        headers=other_headers,
    )
    assert r.status_code == 404


def test_progress_starts_empty(client, auth_headers):
    r = client.get("/api/user/progress", headers=auth_headers)
    assert r.status_code == 200
    body = r.json()
    assert body["total_attempts"] == 0
    assert body["total_correct"] == 0
    assert body["points"] == 0
    first_steps = next(a for a in body["achievements"] if a["id"] == "first_steps")
    assert first_steps["earned"] is False


def test_progress_reflects_a_correct_answer(client, auth_headers):
    q = _get_next(client, auth_headers)
    correct = _mean_answer_from_question(q["question"])
    client.post(
        "/api/quiz/answer",
        json={"question_id": q["question_id"], "selected_answer": correct, "elapsed_seconds": 9},
        headers=auth_headers,
    )

    body = client.get("/api/user/progress", headers=auth_headers).json()
    assert body["total_attempts"] == 1
    assert body["total_correct"] == 1
    assert body["overall_accuracy"] == 100.0
    assert body["points"] == 10  # POINTS_PER_CORRECT
    # Attribution is taken from the stored question, so the requested subject
    # shows up in the per-subject breakdown.
    subjects = {s["subject_id"] for s in body["by_subject"]}
    assert CONCEPT["subject_id"] in subjects
    first_steps = next(a for a in body["achievements"] if a["id"] == "first_steps")
    assert first_steps["earned"] is True
