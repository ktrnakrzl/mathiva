from solver.math_solver import solve_equation, solve_latex
from app.services import ocr_service
from app.services.tutor_service import explain_solution

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
    """OCR a photo and solve it, local-first with a cloud fallback.

    Reads the image with the local pix2tex model first (free, offline). Whether
    that read was good enough is decided by the solver itself: if solve_latex
    can turn it into a real answer, we're done and no API is called. Only when
    the local read fails -- pix2tex garbled it, or it wasn't solvable -- do we
    fall back to Gemini (which reads handwriting/photos), but just as with the
    T5 cascade, we accept Gemini only if *its* output actually solves.
    """
    latex = None
    result = {"success": False, "error": _UNREADABLE_MESSAGE}

    # Local engine first. A crash here (bad image, model error) is treated the
    # same as an unreadable scan so the Gemini fallback still gets a turn.
    try:
        latex = ocr_service.pix2tex_to_latex(image_bytes)
        result = solve_problem_from_latex(latex)
    except Exception:
        pass

    if not result.get("success") and ocr_service.gemini_available():
        try:
            gemini_latex = ocr_service.gemini_to_latex(image_bytes)
            latex = gemini_latex
            result = solve_problem_from_latex(gemini_latex)
        except ocr_service.OCRServiceError:
            pass  # keep the local failure result

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