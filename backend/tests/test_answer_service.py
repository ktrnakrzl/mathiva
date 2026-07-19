"""Tests for the /ask answer cascade (answer_service).

Two things matter here: the cheap "is this answer bad?" guard, and the cascade's
selection logic -- Phi-3 preferred, T5 backup, Gemini as a bounded escalation
only when the local answer is still bad. All generators and retrieval are mocked
so the tests never touch Ollama, the T5 weights, the Gemini API, or the RAG
models.
"""

import pytest

from app.services import answer_service
from app.services.ai_service import AIServiceError


# ---- the guard -------------------------------------------------------------

@pytest.mark.parametrize("text", [
    "",
    "   ",
    None,
    "x x 0 x 0 x 0 x 0 x 0 x 0 x 0 x 0 x 0 x 0 x 0",     # T5 repetition loop
    "T T - T - t - t - t - - t - - t - - - - - -",         # another loop
])
def test_is_bad_answer_flags_empty_and_degenerate(text):
    assert answer_service.is_bad_answer(text) is True


@pytest.mark.parametrize("text", [
    "x = 4",                                               # short but valid
    "-3",                                                  # a bare numeric answer
    "True if both p and q are true; False otherwise.",     # normal sentence
    "The domain is all real numbers x with x >= 5.",
])
def test_is_bad_answer_keeps_good_answers(text):
    assert answer_service.is_bad_answer(text) is False


# ---- cascade selection -----------------------------------------------------

@pytest.fixture
def wired(monkeypatch):
    """Mock retrieval + all three generators; return setters to control each."""
    monkeypatch.setattr(
        answer_service, "_retrieve",
        lambda q: {"chunks": ["ctx"], "indices": [0],
                   "all_chunks": [{"content": "some source chunk"}]},
    )

    state = {"phi": None, "t5": None, "gemini": None,
             "t5_available": True, "gemini_available": True}

    def set_phi(v): state["phi"] = v
    def set_t5(v): state["t5"] = v
    def set_gemini(v): state["gemini"] = v

    def fake_phi(prompt):
        if state["phi"] is None:
            raise AIServiceError("ollama down")
        return state["phi"]

    monkeypatch.setattr(answer_service, "generate_answer", fake_phi)
    monkeypatch.setattr(answer_service.t5_service, "t5_available",
                        lambda: state["t5_available"])
    monkeypatch.setattr(answer_service.t5_service, "t5_generate",
                        lambda ctx, q: state["t5"])
    monkeypatch.setattr(answer_service.gemini_service, "gemini_available",
                        lambda: state["gemini_available"])
    monkeypatch.setattr(answer_service.gemini_service, "gemini_generate",
                        lambda prompt: state["gemini"])

    state.update(set_phi=set_phi, set_t5=set_t5, set_gemini=set_gemini)
    return state


def test_phi_is_preferred_when_good(wired):
    wired["set_phi"]("Phi's clear answer.")
    wired["set_t5"]("T5's also-fine answer.")
    res = answer_service.answer_question("q")
    assert res["model_used"] == "phi3"
    assert res["answer"] == "Phi's clear answer."


def test_falls_back_to_t5_when_phi_is_bad(wired):
    wired["set_phi"]("")                       # phi degenerate/empty
    wired["set_t5"]("T5's good answer here.")
    res = answer_service.answer_question("q")
    assert res["model_used"] == "t5"
    assert res["answer"] == "T5's good answer here."


def test_escalates_to_gemini_when_both_local_are_bad(wired):
    wired["set_phi"]("")                        # both local weak
    wired["set_t5"]("x x x x x x x x x x")      # degenerate loop
    wired["set_gemini"]("Gemini's rescue answer.")
    res = answer_service.answer_question("q")
    assert res["model_used"] == "gemini"
    assert res["answer"] == "Gemini's rescue answer."


def test_gemini_not_called_when_local_answer_is_good(wired, monkeypatch):
    calls = {"n": 0}

    def spy(prompt):
        calls["n"] += 1
        return "should not be used"

    monkeypatch.setattr(answer_service.gemini_service, "gemini_generate", spy)
    wired["set_phi"]("A perfectly good local answer.")
    res = answer_service.answer_question("q")
    assert res["model_used"] == "phi3"
    assert calls["n"] == 0  # escalation skipped entirely


def test_raises_when_every_tier_fails(wired):
    wired["set_phi"](None)                      # ollama down -> AIServiceError
    wired["t5_available"] = False               # no T5 model
    wired["gemini_available"] = False           # no Gemini key
    with pytest.raises(AIServiceError):
        answer_service.answer_question("q")


def test_response_carries_sources(wired):
    wired["set_phi"]("Answer with sources.")
    res = answer_service.answer_question("q")
    assert res["sources"] == [{"chunk_id": 0, "content": "some source chunk"}]
