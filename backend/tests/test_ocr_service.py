"""Tests for OpenAI-backed image understanding."""

import pytest
import requests

from app.services import openai_service
from app.services.ocr_service import (
    OCRRateLimitError,
    OCRServiceError,
    openai_solve_image,
    openai_to_latex,
)


class _FakeResponse:
    def __init__(self, json_data=None, status_code=200, raise_on_json=False, headers=None):
        self._json_data = json_data
        self.status_code = status_code
        self._raise_on_json = raise_on_json
        self.headers = headers or {}

    def json(self):
        if self._raise_on_json:
            raise ValueError("no JSON")
        return self._json_data


def _response(text):
    return {"output": [{"type": "message", "content": [
        {"type": "output_text", "text": text}
    ]}]}


def _patch_post(monkeypatch, response=None, exc=None):
    def fake_post(*args, **kwargs):
        if exc is not None:
            raise exc
        return response
    monkeypatch.setattr(openai_service.requests, "post", fake_post)
    monkeypatch.setattr(openai_service.settings, "openai_api_key", "test-key")


def test_returns_latex(monkeypatch):
    _patch_post(monkeypatch, _FakeResponse(_response("2x + 5 = 13")))
    assert openai_to_latex(b"imgbytes") == "2x + 5 = 13"


def test_sends_image_as_data_url(monkeypatch):
    captured = {}
    def fake_post(*args, **kwargs):
        captured.update(kwargs)
        return _FakeResponse(_response("x=1"))
    monkeypatch.setattr(openai_service.requests, "post", fake_post)
    monkeypatch.setattr(openai_service.settings, "openai_api_key", "test-key")
    openai_to_latex(b"image")
    image = captured["json"]["input"][0]["content"][1]
    assert image["type"] == "input_image"
    assert image["image_url"].startswith("data:image/jpeg;base64,")
    assert captured["headers"]["Authorization"] == "Bearer test-key"
    assert captured["json"]["model"] == "gpt-5.4-mini"
    assert captured["json"]["reasoning"] == {"effort": "low"}
    assert "temperature" not in captured["json"]


def test_output_delimiters_are_cleaned(monkeypatch):
    _patch_post(monkeypatch, _FakeResponse(_response(r"\(x^2 - 4 = 0\)")))
    assert openai_to_latex(b"imgbytes") == "x^2 - 4 = 0"


def test_api_error_becomes_ocr_error(monkeypatch):
    _patch_post(monkeypatch, _FakeResponse(
        {"error": {"message": "API key not valid"}}, status_code=401))
    with pytest.raises(OCRServiceError):
        openai_to_latex(b"imgbytes")


def test_quota_error_is_classified(monkeypatch):
    _patch_post(monkeypatch, _FakeResponse(
        {"error": {"message": "quota"}}, status_code=429,
        headers={"retry-after": "12"}))
    with pytest.raises(OCRRateLimitError):
        openai_to_latex(b"imgbytes")


def test_connection_error_becomes_ocr_error(monkeypatch):
    _patch_post(monkeypatch, exc=requests.ConnectionError("refused"))
    with pytest.raises(OCRServiceError):
        openai_to_latex(b"imgbytes")


def test_openai_solve_image_returns_problem_answer_and_steps(monkeypatch):
    payload = {
        "problem_latex": "2x + 5 = 13",
        "answer_latex": "x = 4",
        "steps": ["Subtract 5 from both sides.", "Divide by 2."],
    }
    import json
    _patch_post(monkeypatch, _FakeResponse(_response(json.dumps(payload))))
    result = openai_solve_image(b"imgbytes")
    assert result["success"] is True
    assert result["latex"] == "2x + 5 = 13"
    assert result["answer"] == r"\(x = 4\)"
    assert "Subtract 5" in result["explanation"]


def test_openai_solve_image_rejects_empty_problem(monkeypatch):
    _patch_post(monkeypatch, _FakeResponse(_response(
        '{"problem_latex":"","answer_latex":"","steps":[]}')))
    with pytest.raises(OCRServiceError):
        openai_solve_image(b"imgbytes")


def test_standalone_quadratic_is_solved_instead_of_repeated(monkeypatch):
    payload = {
        "problem_latex": "f(x)=3x^2+5x-4",
        "answer_latex": r"x=\\frac{-5\\pm\\sqrt{73}}{6}",
        "steps": [
            "Set the quadratic equal to zero.",
            "Apply the quadratic formula.",
        ],
    }
    import json
    _patch_post(monkeypatch, _FakeResponse(_response(json.dumps(payload))))

    result = openai_solve_image(b"imgbytes")

    assert result["success"] is True
    assert result["answer"] == r"\(x=\\frac{-5\\pm\\sqrt{73}}{6}\)"
    assert "quadratic formula" in result["explanation"].lower()


def test_repeated_transcription_is_not_accepted_as_final_answer(monkeypatch):
    payload = {
        "problem_latex": "f(x)=3x^2+5x-4",
        "answer_latex": "f(x)=3x^2+5x-4",
        "steps": ["The image shows a function definition."],
    }
    import json
    _patch_post(monkeypatch, _FakeResponse(_response(json.dumps(payload))))

    with pytest.raises(OCRServiceError, match="without solving"):
        openai_solve_image(b"imgbytes")

