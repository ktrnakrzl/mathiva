import io
import json

from PIL import Image

from app.config import settings
from app.services import openai_service

# Google's Gemini is a multimodal model with a genuinely free API tier (no card
# needed via Google AI Studio). Unlike pix2tex -- which only reads printed math
# and garbles real photos -- Gemini reads handwriting and photographed problems
# and can transcribe them to LaTeX. When GEMINI_API_KEY is set we use it;
# otherwise we fall back to the local pix2tex model so dev still works offline.

# Asks for bare LaTeX only, so the result feeds straight into solve_latex.
_OCR_PROMPT = (
    "You are an OCR engine for mathematics. Transcribe the mathematical "
    "expression or equation in this image into a single line of LaTeX. "
    "Output ONLY the LaTeX code -- no explanation, no surrounding text, no "
    "$ or \\( \\) delimiters, and no code fences. Preserve the '=' sign if the "
    "image shows an equation. Preserve every decimal point and digit; write "
    "decimals with a leading zero (0.5, not .5) and a plain point (1.5, not "
    "1{.}5). Do not confuse decimal points with multiplication dots."
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


class OCRUnavailableError(OCRServiceError):
    """The recognition service failed, rather than the photo being unreadable."""


class OCRRateLimitError(OCRUnavailableError):
    """Cloud recognition quota or request limit was reached."""


def openai_available() -> bool:
    return openai_service.openai_available()


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


def _post_openai_image(image_bytes: bytes, prompt: str) -> str:
    try:
        return openai_service.analyze_image(image_bytes, _detect_mime(image_bytes), prompt)
    except openai_service.OpenAIRateLimitError as e:
        raise OCRRateLimitError(str(e)) from e
    except openai_service.OpenAIServiceError as e:
        raise OCRUnavailableError("Could not reach the image recognition service.") from e


def openai_to_latex(image_bytes: bytes) -> str:
    """Send a camera/gallery image to OpenAI and return recognized LaTeX."""
    text = _post_openai_image(image_bytes, _OCR_PROMPT)
    latex = _clean_latex(text)
    if not latex:
        raise OCRServiceError("Couldn't read an equation from that image.")
    return latex


def openai_solve_image(image_bytes: bytes) -> dict:
    """Let OpenAI solve the photographed problem directly.

    This is a rescue path for real photos whose transcription is readable to a
    multimodal model but too messy for SymPy's strict parser.
    """
    text = _post_openai_image(image_bytes, _SOLVE_IMAGE_PROMPT)
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
