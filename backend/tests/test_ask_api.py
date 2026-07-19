"""Tests for the /ask/stream endpoint's Ollama-or-Gemini behavior.

The streaming path normally forwards Ollama's tokens as they arrive. In a
Gemini-only deployment (no local Ollama) it must NOT return 503 -- it should
answer via the full cascade (which escalates to Gemini) and stream that answer
as a single chunk. Everything heavy (RAG, Ollama, the cascade internals) is
mocked, so these never touch the real models or the network.
"""

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient

from app.api import ask as ask_module
from app.services.ai_service import AIServiceError
from app.services.auth_service import get_current_user


@pytest.fixture
def stream_client(monkeypatch):
    # RAG retrieval is irrelevant to what these tests exercise; stub it so no
    # SBERT/FAISS models load and no real prompt-building happens.
    monkeypatch.setattr(
        ask_module, "_retrieve_and_build_prompt", lambda q: ("tutor prompt", {})
    )
    app = FastAPI()
    app.include_router(ask_module.router)
    # Bypass real auth -- any object stands in for the authenticated user.
    app.dependency_overrides[get_current_user] = lambda: object()
    return TestClient(app)


def _ollama_down(_prompt):
    """Stand-in for stream_answer when Ollama is unreachable: a generator that
    raises on the first token, exactly as the real one does on a failed connect."""
    raise AIServiceError("could not reach ollama")
    yield  # unreached -- the yield just makes this a generator function


def _ollama_streams(_prompt):
    """Stand-in for a healthy Ollama stream."""
    yield "Phi "
    yield "streamed "
    yield "answer."


def test_stream_falls_back_to_cascade_when_ollama_down(stream_client, monkeypatch):
    monkeypatch.setattr(ask_module, "stream_answer", _ollama_down)
    monkeypatch.setattr(
        ask_module, "answer_question",
        lambda q: {"question": q, "answer": "Gemini's answer.",
                   "model_used": "gemini", "sources": []},
    )
    r = stream_client.post("/api/ask/stream", params={"question": "hi"})
    assert r.status_code == 200
    assert r.text == "Gemini's answer."


def test_stream_forwards_ollama_tokens_when_available(stream_client, monkeypatch):
    monkeypatch.setattr(ask_module, "stream_answer", _ollama_streams)

    def _must_not_run(q):
        raise AssertionError("cascade must not run when streaming works")

    monkeypatch.setattr(ask_module, "answer_question", _must_not_run)
    r = stream_client.post("/api/ask/stream", params={"question": "hi"})
    assert r.status_code == 200
    assert r.text == "Phi streamed answer."


def test_stream_503_when_ollama_down_and_cascade_also_fails(stream_client, monkeypatch):
    monkeypatch.setattr(ask_module, "stream_answer", _ollama_down)

    def _every_tier_dead(q):
        raise AIServiceError("every tier failed")

    monkeypatch.setattr(ask_module, "answer_question", _every_tier_dead)
    r = stream_client.post("/api/ask/stream", params={"question": "hi"})
    assert r.status_code == 503
