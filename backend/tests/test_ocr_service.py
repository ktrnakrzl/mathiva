"""Tests for the Gemini OCR engine in ocr_service.

No live Gemini in the test environment, so these mock requests.post and verify
gemini_to_latex extracts + cleans the LaTeX and turns every failure mode into a
clean OCRServiceError. (The local-first/Gemini-fallback orchestration lives in
solver_service; see test_solver_service.)
"""

import pytest
import requests

from app.services import ocr_service
from app.services.ocr_service import OCRServiceError, gemini_to_latex


class _FakeResponse:
    def __init__(self, json_data=None, raise_on_json=False):
        self._json_data = json_data
        self._raise_on_json = raise_on_json

    def json(self):
        if self._raise_on_json:
            raise ValueError("no JSON")
        return self._json_data


def _patch_post(monkeypatch, response=None, exc=None):
    def fake_post(*args, **kwargs):
        if exc is not None:
            raise exc
        return response
    monkeypatch.setattr(ocr_service.requests, "post", fake_post)


def _gemini_reply(text):
    return {"candidates": [{"content": {"parts": [{"text": text}]}}]}


def test_returns_latex(monkeypatch):
    _patch_post(monkeypatch, _FakeResponse(_gemini_reply("2x + 5 = 13")))
    assert gemini_to_latex(b"imgbytes") == "2x + 5 = 13"


def test_output_is_cleaned_of_fences_and_delimiters(monkeypatch):
    _patch_post(monkeypatch, _FakeResponse(_gemini_reply("```latex\n\\(x^2 - 4 = 0\\)\n```")))
    assert gemini_to_latex(b"imgbytes") == "x^2 - 4 = 0"


def test_error_object_becomes_ocr_error(monkeypatch):
    _patch_post(monkeypatch, _FakeResponse({"error": {"message": "API key not valid"}}))
    with pytest.raises(OCRServiceError, match="API key not valid"):
        gemini_to_latex(b"imgbytes")


def test_no_candidates_becomes_ocr_error(monkeypatch):
    _patch_post(monkeypatch, _FakeResponse({"candidates": []}))
    with pytest.raises(OCRServiceError):
        gemini_to_latex(b"imgbytes")


def test_connection_error_becomes_ocr_error(monkeypatch):
    _patch_post(monkeypatch, exc=requests.ConnectionError("refused"))
    with pytest.raises(OCRServiceError):
        gemini_to_latex(b"imgbytes")
