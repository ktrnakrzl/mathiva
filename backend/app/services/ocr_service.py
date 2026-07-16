import io
import json
import os

import requests
from PIL import Image

# Mathpix's text endpoint reads *handwritten* math -> LaTeX, which the local
# pix2tex model (trained on printed/typeset math only) can't do. When Mathpix
# credentials are configured we prefer it; otherwise we fall back to pix2tex so
# the app still works offline in development.
MATHPIX_URL = "https://api.mathpix.com/v3/text"

_model = None


class OCRServiceError(RuntimeError):
    """Raised when OCR can't turn the image into LaTeX (Mathpix unreachable,
    misconfigured, or returned no usable result). The /solve-image endpoint
    surfaces this as a clear failure instead of leaking a raw error."""


def _mathpix_configured() -> bool:
    return bool(os.getenv("MATHPIX_APP_ID") and os.getenv("MATHPIX_APP_KEY"))


def _mathpix_image_to_latex(image_bytes: bytes) -> str:
    """Send the photo to Mathpix and return the recognised LaTeX equation.

    Requires MATHPIX_APP_ID / MATHPIX_APP_KEY in the environment (backend/.env).
    We ask only for `latex_styled` -- the bare LaTeX of the equation -- which
    feeds straight into solver.math_solver.solve_latex.
    """
    try:
        response = requests.post(
            MATHPIX_URL,
            files={"file": ("image", image_bytes)},
            data={
                "options_json": json.dumps(
                    {
                        "formats": ["latex_styled"],
                        "data_options": {"include_latex": True},
                    }
                )
            },
            headers={
                "app_id": os.getenv("MATHPIX_APP_ID"),
                "app_key": os.getenv("MATHPIX_APP_KEY"),
            },
            timeout=30,
        )
    except requests.RequestException as e:
        raise OCRServiceError(f"Could not reach the OCR service: {e}") from e

    try:
        payload = response.json()
    except ValueError as e:
        raise OCRServiceError("OCR service returned a non-JSON response") from e

    # Mathpix reports failures in an `error` field rather than a non-2xx status.
    if payload.get("error"):
        detail = (payload.get("error_info") or {}).get("message") or payload["error"]
        raise OCRServiceError(str(detail))

    latex = payload.get("latex_styled") or payload.get("text")
    if not latex:
        raise OCRServiceError("Couldn't read an equation from that image.")
    return latex.strip()


def _get_model():
    global _model
    if _model is None:
        # Imported lazily so a Mathpix-only deployment never loads pix2tex/torch,
        # and so importing this module (e.g. in tests) stays cheap.
        from pix2tex.cli import LatexOCR

        _model = LatexOCR()
    return _model


def _pix2tex_image_to_latex(image_bytes: bytes) -> str:
    image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    return _get_model()(image)


def image_to_latex(image_bytes: bytes) -> str:
    """Turn a photo into a LaTeX string.

    Prefers Mathpix (handles handwriting) when MATHPIX_APP_ID/KEY are set; falls
    back to the local pix2tex model (printed math only) otherwise.
    """
    if _mathpix_configured():
        return _mathpix_image_to_latex(image_bytes)
    return _pix2tex_image_to_latex(image_bytes)
