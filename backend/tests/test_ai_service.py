"""Tests for the Ollama client wrapper in app.services.ai_service.

generate_answer() is the single choke point between /api/ask and the local
Ollama server. It has no live Ollama in the test environment, so every case
here mocks requests.post -- what we're actually verifying is that each failure
mode Ollama can present is turned into a clean AIServiceError (so the endpoint
can say "the tutor is unavailable") instead of leaking a raw
ConnectionError/ValueError/KeyError.
"""

import pytest
import requests

from app.services.ai_service import AIServiceError, generate_answer


class _FakeResponse:
    """Stand-in for requests.Response: .json() returns preset data, or raises
    ValueError to simulate a non-JSON body."""

    def __init__(self, json_data=None, raise_on_json=False):
        self._json_data = json_data
        self._raise_on_json = raise_on_json

    def json(self):
        if self._raise_on_json:
            raise ValueError("no JSON could be decoded")
        return self._json_data


def _patch_post(monkeypatch, response=None, exc=None):
    """Point ai_service.requests.post at a fake that returns `response` or
    raises `exc`."""
    def fake_post(*args, **kwargs):
        if exc is not None:
            raise exc
        return response
    monkeypatch.setattr("app.services.ai_service.requests.post", fake_post)


def test_returns_the_completion_on_success(monkeypatch):
    _patch_post(monkeypatch, _FakeResponse({"response": "2 + 2 = 4"}))
    assert generate_answer("What is 2 + 2?") == "2 + 2 = 4"


def test_connection_error_becomes_ai_service_error(monkeypatch):
    # Ollama not running / connection refused.
    _patch_post(monkeypatch, exc=requests.ConnectionError("refused"))
    with pytest.raises(AIServiceError):
        generate_answer("hi")


def test_timeout_becomes_ai_service_error(monkeypatch):
    _patch_post(monkeypatch, exc=requests.Timeout("timed out"))
    with pytest.raises(AIServiceError):
        generate_answer("hi")


def test_non_json_body_becomes_ai_service_error(monkeypatch):
    _patch_post(monkeypatch, _FakeResponse(raise_on_json=True))
    with pytest.raises(AIServiceError):
        generate_answer("hi")


def test_error_payload_is_surfaced(monkeypatch):
    # Ollama returns 4xx with {"error": ...} and no "response" (e.g. model not pulled).
    _patch_post(monkeypatch, _FakeResponse({"error": "model 'phi' not found"}))
    with pytest.raises(AIServiceError, match="not found"):
        generate_answer("hi")


def test_missing_response_key_without_error(monkeypatch):
    _patch_post(monkeypatch, _FakeResponse({"something_else": 1}))
    with pytest.raises(AIServiceError):
        generate_answer("hi")
