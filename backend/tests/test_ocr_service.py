"""Tests for OCR engine selection + Gemini parsing in ocr_service.

There's no live Gemini (or camera) in the test environment, so these mock
requests.post and verify: Gemini is used when configured, its LaTeX is
extracted and cleaned (fences/delimiters stripped), every failure mode becomes a
clean OCRServiceError, and the local pix2tex fallback is used when Gemini isn't
configured. pix2tex is mocked so no model/torch is loaded.
"""

import pytest
import requests

from app.services import ocr_service
from app.services.ocr_service import OCRServiceError, image_to_latex


class _FakeResponse:
    def __init__(self, json_data=None, raise_on_json=False):
        self._json_data = json_data
        self._raise_on_json = raise_on_json

    def json(self):
        if self._raise_on_json:
            raise ValueError("no JSON")
        return self._json_data


def _configure_gemini(monkeypatch):
    monkeypatch.setenv("GEMINI_API_KEY", "test-key")


def _patch_post(monkeypatch, response=None, exc=None):
    def fake_post(*args, **kwargs):
        if exc is not None:
            raise exc
        return response
    monkeypatch.setattr(ocr_service.requests, "post", fake_post)


def _gemini_reply(text):
    return {"candidates": [{"content": {"parts": [{"text": text}]}}]}


def test_uses_gemini_and_returns_latex_when_configured(monkeypatch):
    _configure_gemini(monkeypatch)
    _patch_post(monkeypatch, _FakeResponse(_gemini_reply("2x + 5 = 13")))
    assert image_to_latex(b"imgbytes") == "2x + 5 = 13"


def test_gemini_output_is_cleaned_of_fences_and_delimiters(monkeypatch):
    _configure_gemini(monkeypatch)
    _patch_post(monkeypatch, _FakeResponse(_gemini_reply("```latex\n\\(x^2 - 4 = 0\\)\n```")))
    assert image_to_latex(b"imgbytes") == "x^2 - 4 = 0"


def test_gemini_error_object_becomes_ocr_error(monkeypatch):
    _configure_gemini(monkeypatch)
    _patch_post(monkeypatch, _FakeResponse({"error": {"message": "API key not valid"}}))
    with pytest.raises(OCRServiceError, match="API key not valid"):
        image_to_latex(b"imgbytes")


def test_gemini_no_candidates_becomes_ocr_error(monkeypatch):
    _configure_gemini(monkeypatch)
    _patch_post(monkeypatch, _FakeResponse({"candidates": []}))
    with pytest.raises(OCRServiceError):
        image_to_latex(b"imgbytes")


def test_gemini_connection_error_becomes_ocr_error(monkeypatch):
    _configure_gemini(monkeypatch)
    _patch_post(monkeypatch, exc=requests.ConnectionError("refused"))
    with pytest.raises(OCRServiceError):
        image_to_latex(b"imgbytes")


def test_falls_back_to_pix2tex_when_gemini_unconfigured(monkeypatch):
    monkeypatch.delenv("GEMINI_API_KEY", raising=False)
    # Mock the local engine so no torch/pix2tex model is loaded.
    monkeypatch.setattr(ocr_service, "_pix2tex_image_to_latex", lambda b: "PIX2TEX_LATEX")
    assert image_to_latex(b"imgbytes") == "PIX2TEX_LATEX"
