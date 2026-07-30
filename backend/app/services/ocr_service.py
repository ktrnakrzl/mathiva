import base64
import io
import json

import requests
from PIL import Image

from app.config import settings

# Google's Gemini is a multimodal model with a genuinely free API tier (no card
# needed via Google AI Studio). Unlike pix2tex -- which only reads printed math
# and garbles real photos -- Gemini reads handwriting and photographed problems
# and can transcribe them to LaTeX. When GEMINI_API_KEY is set we use it;
# otherwise we fall back to the local pix2tex model so dev still works offline.
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

_SOLVE_IMAGE_PROMPT = (
    "You are Mathiva, a careful math tutor. Read the math problem in this image "
    "and solve it. Return ONLY valid JSON with these keys: problem_latex, "
    "answer_latex, steps. problem_latex is the problem as a single LaTeX line. "
    "answer_latex is the final answer as LaTeX without dollar signs. steps is "
    "an array of short step-by-step explanation strings. If no math problem is "
    "visible, return problem_latex and answer_latex as empty strings and steps "
    "as an empty array."
)

_model = None


class OCRServiceError(RuntimeError):
    """Raised when OCR can't turn the image into LaTeX (Gemini unreachable,
    misconfigured, or returned nothing usable). The /solve-image endpoint
    surfaces this as a clear failure instead of leaking a raw error."""


def gemini_available() -> bool:
    return bool(settings.gemini_api_key)


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


def _clean_json(text: str) -> dict:
    t = text.strip()
    if t.startswith("```"):
        t = t.strip("`").strip()
        if t.lower().startswith("json"):
            t = t[len("json"):].strip()
    try:
        return json.loads(t)
    except ValueError:
        start = t.find("{")
        end = t.rfind("}")
        if start == -1 or end == -1 or end <= start:
            raise
        return json.loads(t[start:end + 1])


def _post_gemini_image(image_bytes: bytes, prompt: str, timeout: int = 30) -> dict:
    body = {
        "contents": [
            {
                "parts": [
                    {"text": prompt},
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
            GEMINI_URL.format(model=settings.gemini_model),
            params={"key": settings.gemini_api_key},
            json=body,
            timeout=timeout,
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
    return payload


def _extract_text(payload: dict) -> str:
    try:
        text = payload["candidates"][0]["content"]["parts"][0]["text"]
    except (KeyError, IndexError, TypeError):
        # No candidate usually means the prompt/image was blocked or empty.
        raise OCRServiceError("Couldn't read an equation from that image.")
    text = text.strip()
    if not text:
        raise OCRServiceError("Couldn't read an equation from that image.")
    return text


def gemini_to_latex(image_bytes: bytes) -> str:
    """Send the photo to Gemini and return the recognised LaTeX equation.

    Requires GEMINI_API_KEY in the environment (backend/.env); get a free key
    from https://aistudio.google.com. temperature=0 for a deterministic
    transcription rather than a creative one."""
    payload = _post_gemini_image(image_bytes, _OCR_PROMPT)
    text = _extract_text(payload)
    latex = _clean_latex(text)
    if not latex:
        raise OCRServiceError("Couldn't read an equation from that image.")
    return latex


def gemini_solve_image(image_bytes: bytes) -> dict:
    """Let Gemini solve the photographed problem directly.

    This is a rescue path for real photos whose transcription is readable to a
    multimodal model but too messy for SymPy's strict parser.
    """
    payload = _post_gemini_image(image_bytes, _SOLVE_IMAGE_PROMPT, timeout=45)
    text = _extract_text(payload)
    try:
        data = _clean_json(text)
    except ValueError as e:
        raise OCRServiceError("OCR service returned an invalid solve response") from e

    problem = str(data.get("problem_latex") or "").strip()
    answer = str(data.get("answer_latex") or "").strip()
    steps = data.get("steps")
    if not problem or not answer or not isinstance(steps, list):
        raise OCRServiceError("Couldn't solve a math problem from that image.")

    clean_steps = [str(step).strip() for step in steps if str(step).strip()]
    if not clean_steps:
        clean_steps = [f"Detected \\({problem}\\).", f"Final answer: \\({answer}\\)."]

    return {
        "problem": problem,
        "latex": problem,
        "variable": None,
        "solutions": [answer],
        "answer": f"\\({answer}\\)",
        "explanation": "\n".join(clean_steps),
        "success": True,
    }


def _get_model():
    global _model
    if _model is None:
        # Imported lazily so a Gemini-only deployment never loads pix2tex/torch,
        # and so importing this module (e.g. in tests) stays cheap.
        from pix2tex.cli import LatexOCR

        _model = LatexOCR()
    return _model


def pix2tex_to_latex(image_bytes: bytes) -> str:
    """Read the image with the local pix2tex model (printed math only)."""
    image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    return _get_model()(image)
