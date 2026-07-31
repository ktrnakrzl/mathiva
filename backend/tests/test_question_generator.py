"""Tests for the hybrid generator's LLM-rephrase guard.

The parametric template already guarantees the math; the generator only lets an
LLM reword the *wording*, and only if every number survives. These tests pin
that guard by monkeypatching the LLM call so they never touch Ollama.
"""

import pytest

from app.services import question_generator
from app.services.question_generator import ServedQuestion, generate_question


def _patch_llm(monkeypatch, reply):
    """Make the generator's LLM return `reply` (a str, or an Exception to raise)."""
    def fake(prompt):
        if isinstance(reply, Exception):
            raise reply
        return reply
    monkeypatch.setattr(question_generator, "generate_answer", fake)


ORIGINAL = "Find the mean of 4, 8, 6."
MUST_KEEP = ["4", "8", "6"]


def test_good_reword_is_accepted(monkeypatch):
    _patch_llm(monkeypatch, "What is the average of 4, 8, and 6?")
    out = question_generator._rephrase(ORIGINAL, MUST_KEEP)
    assert out == "What is the average of 4, 8, and 6?"


def test_reword_dropping_a_number_falls_back(monkeypatch):
    # Missing the 6 -> unanswerable, must fall back to the original.
    _patch_llm(monkeypatch, "What is the average of 4 and 8?")
    assert question_generator._rephrase(ORIGINAL, MUST_KEEP) == ORIGINAL


def test_reword_with_unicode_superscript_falls_back(monkeypatch):
    _patch_llm(monkeypatch, "Find the mean of 4, 8, 6 and note x².")
    assert question_generator._rephrase(ORIGINAL, MUST_KEEP) == ORIGINAL


def test_overlong_reword_falls_back(monkeypatch):
    _patch_llm(monkeypatch, "4 8 6 " + "very " * 100 + "long")
    assert question_generator._rephrase(ORIGINAL, MUST_KEEP) == ORIGINAL


def test_preamble_label_is_stripped(monkeypatch):
    _patch_llm(monkeypatch, "Sure! Here is the question: Compute the mean of 4, 8, 6.")
    assert question_generator._rephrase(ORIGINAL, MUST_KEEP) == "Compute the mean of 4, 8, 6."


def test_llm_failure_falls_back_to_original(monkeypatch):
    _patch_llm(monkeypatch, RuntimeError("Ollama down"))
    assert question_generator._rephrase(ORIGINAL, MUST_KEEP) == ORIGINAL


def test_generate_question_without_rephrase_uses_template_text(monkeypatch):
    # rephrase=False must not call the LLM at all.
    def boom(prompt):
        raise AssertionError("LLM must not be called when rephrase=False")
    monkeypatch.setattr(question_generator, "generate_answer", boom)

    q = generate_question("mean", "Easy", rephrase=False)
    assert isinstance(q, ServedQuestion)
    assert q.template_id == "mean"
    assert q.correct_answer in q.choices
    assert len(q.choices) == 4
    assert "mean" in q.question_text.lower() or "average" in q.question_text.lower()


def test_generate_question_unknown_concept_raises(monkeypatch):
    with pytest.raises(KeyError):
        generate_question("no_such_concept", "Easy", rephrase=False)
