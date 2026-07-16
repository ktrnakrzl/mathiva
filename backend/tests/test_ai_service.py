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

from app.services.ai_service import AIServiceError, generate_answer, stream_answer


class _FakeResponse:
    """Stand-in for requests.Response: .json() returns preset data (or raises
    ValueError for a non-JSON body); .iter_lines() replays preset byte lines for
    the streaming path."""

    def __init__(self, json_data=None, raise_on_json=False, lines=None):
        self._json_data = json_data
        self._raise_on_json = raise_on_json
        self._lines = lines or []

    def json(self):
        if self._raise_on_json:
            raise ValueError("no JSON could be decoded")
        return self._json_data

    def iter_lines(self):
        return iter(self._lines)


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


# --- streaming path ---------------------------------------------------------

def test_stream_yields_pieces_in_order_and_stops_on_done(monkeypatch):
    lines = [
        b'{"response": "2x", "done": false}',
        b'',                                    # blank keep-alive line, skipped
        b'{"response": " = 8", "done": false}',
        b'not json',                            # malformed line, skipped
        b'{"response": ", so x = 4", "done": false}',
        b'{"done": true}',                      # end marker
        b'{"response": "IGNORED AFTER DONE"}',  # never reached
    ]
    _patch_post(monkeypatch, _FakeResponse(lines=lines))
    assert list(stream_answer("hi")) == ["2x", " = 8", ", so x = 4"]


def test_stream_connection_error_becomes_ai_service_error(monkeypatch):
    _patch_post(monkeypatch, exc=requests.ConnectionError("refused"))
    with pytest.raises(AIServiceError):
        # The request is issued when iteration starts, so drain the generator.
        list(stream_answer("hi"))
