import base64
import io
import json
import os

import requests
from PIL import Image

# Google's Gemini is a multimodal model with a genuinely free API tier (no card
# needed via Google AI Studio). Unlike pix2tex -- which only reads printed math
# and garbles real photos -- Gemini reads handwriting and photographed problems
# and can transcribe them to LaTeX. When GEMINI_API_KEY is set we use it;
# otherwise we fall back to the local pix2tex model so dev still works offline.
GEMINI_MODEL = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")
GEMINI_URL = (
    "https://generativelanguage.googleapis.com/v1beta/models/"
    "{model}:generateContent"
)

# Asks for bare LaTeX only, so the result feeds straight into solve_latex.
_OCR_PROMPT = (
    "You are an OCR engine for mathematics. Transcribe the mathematical "
    "expression or equation in this image into a single line of LaTeX. "
    "Output ONLY the LaTeX code -- no explanation, no surrounding text, no "
    "$ or \\( \\) delimiters, and no code fences. Preserve the '=' sign if the "
    "image shows an equation."
)

_model = None


class OCRServiceError(RuntimeError):
    """Raised when OCR can't turn the image into LaTeX (Gemini unreachable,
    misconfigured, or returned nothing usable). The /solve-image endpoint
    surfaces this as a clear failure instead of leaking a raw error."""


def _gemini_configured() -> bool:
    return bool(os.getenv("GEMINI_API_KEY"))


def _detect_mime(image_bytes: bytes) -> str:
    try:
        fmt = Image.open(io.BytesIO(image_bytes)).format
        return {
            "JPEG": "image/jpeg",
            "PNG": "image/png",
            "WEBP": "image/webp",
        }.get(fmt, "image/jpeg")
    except Exception:
        return "image/jpeg"


def _clean_latex(text: str) -> str:
    """Strip anything Gemini wraps around the bare LaTeX (code fences, $ or
    \\(...\\) delimiters), which parse_latex can't handle."""
    t = text.strip()
    if t.startswith("```"):
        t = t.strip("`").strip()
        if t.lower().startswith("latex"):
            t = t[len("latex"):].strip()
    for open_d, close_d in (("$$", "$$"), ("$", "$"), (r"\(", r"\)"), (r"\[", r"\]")):
        if t.startswith(open_d) and t.endswith(close_d) and len(t) > len(open_d) + len(close_d):
            t = t[len(open_d):-len(close_d)].strip()
    return t.strip()


def _gemini_image_to_latex(image_bytes: bytes) -> str:
    """Send the photo to Gemini and return the recognised LaTeX equation.

    Requires GEMINI_API_KEY in the environment (backend/.env); get a free key
    from https://aistudio.google.com. temperature=0 for a deterministic
    transcription rather than a creative one."""
    body = {
        "contents": [
            {
                "parts": [
                    {"text": _OCR_PROMPT},
                    {
                        "inline_data": {
                            "mime_type": _detect_mime(image_bytes),
                            "data": base64.b64encode(image_bytes).decode("ascii"),
                        }
                    },
                ]
            }
        ],
        "generationConfig": {"temperature": 0},
    }

    try:
        response = requests.post(
            GEMINI_URL.format(model=GEMINI_MODEL),
            params={"key": os.getenv("GEMINI_API_KEY")},
            json=body,
            timeout=30,
        )
    except requests.RequestException as e:
        raise OCRServiceError(f"Could not reach the OCR service: {e}") from e

    try:
        payload = response.json()
    except ValueError as e:
        raise OCRServiceError("OCR service returned a non-JSON response") from e

    # Gemini reports auth/quota errors in an `error` object.
    if isinstance(payload.get("error"), dict):
        raise OCRServiceError(payload["error"].get("message", "OCR service error"))

    try:
        text = payload["candidates"][0]["content"]["parts"][0]["text"]
    except (KeyError, IndexError, TypeError):
        # No candidate usually means the prompt/image was blocked or empty.
        raise OCRServiceError("Couldn't read an equation from that image.")

    latex = _clean_latex(text)
    if not latex:
        raise OCRServiceError("Couldn't read an equation from that image.")
    return latex


def _get_model():
    global _model
    if _model is None:
        # Imported lazily so a Gemini-only deployment never loads pix2tex/torch,
        # and so importing this module (e.g. in tests) stays cheap.
        from pix2tex.cli import LatexOCR

        _model = LatexOCR()
    return _model


def _pix2tex_image_to_latex(image_bytes: bytes) -> str:
    image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    return _get_model()(image)


def image_to_latex(image_bytes: bytes) -> str:
    """Turn a photo into a LaTeX string.

    Prefers Gemini (reads handwriting/photos) when GEMINI_API_KEY is set; falls
    back to the local pix2tex model (printed math only) otherwise.
    """
    if _gemini_configured():
        return _gemini_image_to_latex(image_bytes)
    return _pix2tex_image_to_latex(image_bytes)
