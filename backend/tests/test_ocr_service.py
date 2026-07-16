"""Tests for the OCR engine selection + Mathpix parsing in ocr_service.

There's no live Mathpix (or camera) in the test environment, so these mock
requests.post and just verify that: Mathpix is used when configured, its LaTeX
is extracted, every failure mode becomes a clean OCRServiceError, and the local
pix2tex fallback is used when Mathpix isn't configured. pix2tex itself is
mocked so no model/torch is loaded.
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


def _configure_mathpix(monkeypatch):
    monkeypatch.setenv("MATHPIX_APP_ID", "test-id")
    monkeypatch.setenv("MATHPIX_APP_KEY", "test-key")


def _patch_post(monkeypatch, response=None, exc=None):
    def fake_post(*args, **kwargs):
        if exc is not None:
            raise exc
        return response
    monkeypatch.setattr(ocr_service.requests, "post", fake_post)


def test_uses_mathpix_and_returns_latex_when_configured(monkeypatch):
    _configure_mathpix(monkeypatch)
    _patch_post(monkeypatch, _FakeResponse({"latex_styled": "2x + 5 = 13"}))
    assert image_to_latex(b"imgbytes") == "2x + 5 = 13"


def test_mathpix_error_payload_becomes_ocr_error(monkeypatch):
    _configure_mathpix(monkeypatch)
    _patch_post(monkeypatch, _FakeResponse(
        {"error": "image_missing", "error_info": {"message": "no equation found"}}
    ))
    with pytest.raises(OCRServiceError, match="no equation found"):
        image_to_latex(b"imgbytes")


def test_mathpix_empty_result_becomes_ocr_error(monkeypatch):
    _configure_mathpix(monkeypatch)
    _patch_post(monkeypatch, _FakeResponse({"latex_styled": ""}))
    with pytest.raises(OCRServiceError):
        image_to_latex(b"imgbytes")


def test_mathpix_connection_error_becomes_ocr_error(monkeypatch):
    _configure_mathpix(monkeypatch)
    _patch_post(monkeypatch, exc=requests.ConnectionError("refused"))
    with pytest.raises(OCRServiceError):
        image_to_latex(b"imgbytes")


def test_falls_back_to_pix2tex_when_mathpix_unconfigured(monkeypatch):
    monkeypatch.delenv("MATHPIX_APP_ID", raising=False)
    monkeypatch.delenv("MATHPIX_APP_KEY", raising=False)
    # Mock the local engine so no torch/pix2tex model is loaded.
    monkeypatch.setattr(ocr_service, "_pix2tex_image_to_latex", lambda b: "PIX2TEX_LATEX")
    assert image_to_latex(b"imgbytes") == "PIX2TEX_LATEX"
