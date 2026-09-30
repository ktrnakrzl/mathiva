import logging

from solver.math_solver import solve_equation, solve_latex
from app.config import settings
from app.services import ocr_service
from app.services.tutor_service import explain_solution

logger = logging.getLogger(__name__)

# Shown when neither OCR engine could turn the photo into a solvable equation.
_UNREADABLE_MESSAGE = (
    "Sorry, I couldn't read a clear equation from that image. Try retaking the "
    "photo with good lighting and only the equation in the frame."
)


def solve_problem(equation: str):
    result = solve_equation(equation)

    if not result["success"]:
        return result

    explanation = explain_solution(
        equation,
        result["solutions"]
    )

    return {
        "problem": equation,
        "solutions": result["solutions"],
        "answer": result["answer"],
        "explanation": explanation,
        "success": True
    }


def solve_image(image_bytes: bytes):
    """OCR a photo and solve it, cloud-first with a local fallback.

    Gemini reads the image first: it handles photographed and handwritten math,
    which is the real use case. The local pix2tex model only reads *clean printed*
    math and garbles photos, so running it first just added latency before the
    inevitable Gemini retry. pix2tex now runs only as an offline fallback -- when
    no Gemini key is configured, or Gemini couldn't produce a solvable read -- so
    development still works without a key or network. As with the /ask cascade, an
    engine's output is accepted only if the solver can actually solve it.
    """
    latex = None
    result = {"success": False, "error": _UNREADABLE_MESSAGE}
    service_error = None

    # Cloud engine first -- it reads real photos and handwriting.
    if ocr_service.gemini_available():
        try:
            latex = ocr_service.gemini_to_latex(image_bytes)
            logger.info("Gemini OCR read LaTeX: %s", latex)
            result = solve_problem_from_latex(latex)
            if not result.get("success"):
                logger.info("Gemini OCR solve failed: %s", result.get("error"))
                try:
                    result = ocr_service.gemini_solve_image(image_bytes)
                    latex = result.get("latex") or latex
                    logger.info("Gemini direct image solve succeeded.")
                except ocr_service.OCRServiceError as e:
                    if isinstance(e, ocr_service.OCRUnavailableError):
                        service_error = e
                    logger.warning("Gemini direct image solve failed: %s", e)
        except ocr_service.OCRServiceError as e:
            logger.warning("Gemini OCR failed: %s", e)
            if isinstance(e, ocr_service.OCRUnavailableError):
                service_error = e
            else:
                # A missing/empty transcription can still be understood by the
                # image-solving prompt. Do not retry an outage or quota error.
                try:
                    result = ocr_service.gemini_solve_image(image_bytes)
                    latex = result.get("latex")
                except ocr_service.OCRServiceError as retry_error:
                    if isinstance(retry_error, ocr_service.OCRUnavailableError):
                        service_error = retry_error
    else:
        logger.info("Gemini OCR skipped: GEMINI_API_KEY is not configured.")
        service_error = ocr_service.OCRUnavailableError("Cloud OCR is not configured")

    # Local pix2tex as an offline fallback: no key, or Gemini didn't solve. A
    # crash here (bad image, model error) is treated the same as an unreadable
    # scan so the caller still gets an honest failure.
    if not result.get("success") and settings.disable_pix2tex:
        logger.info("pix2tex OCR skipped: DISABLE_PIX2TEX=true")
    elif not result.get("success"):
        try:
            pix_latex = ocr_service.pix2tex_to_latex(image_bytes)
            logger.info("pix2tex OCR read LaTeX: %s", pix_latex)
            latex = pix_latex
            result = solve_problem_from_latex(pix_latex)
            if not result.get("success"):
                logger.info("pix2tex OCR solve failed: %s", result.get("error"))
        except Exception as e:
            logger.warning("pix2tex OCR failed: %s", e)
            if latex is None and service_error is None:
                service_error = ocr_service.OCRUnavailableError("Local OCR failed")

    if not result.get("success") and service_error is not None and latex is None:
        limited = isinstance(service_error, ocr_service.OCRRateLimitError)
        result = {
            "success": False,
            "error_code": "ocr_rate_limited" if limited else "ocr_unavailable",
            "error": (
                "Image recognition has reached its usage limit. Please try again later "
                "or type the problem in chat."
                if limited else
                "Image recognition is unavailable right now. Please try again later "
                "or type the problem in chat."
            ),
        }

    if latex is not None:
        result["latex"] = latex
    return result


def solve_problem_from_latex(latex: str):
    result = solve_latex(latex)

    if not result["success"]:
        return result

    explanation = explain_solution(
        latex,
        result["solutions"]
    )

    return {
        "problem": latex,
        "variable": result["variable"],
        "solutions": result["solutions"],
        "answer": result["answer"],
        "explanation": explanation,
        "success": True
    }
