from solver.math_solver import solve_equation, solve_latex
from app.config import settings
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

    # Cloud engine first -- it reads real photos and handwriting.
    if ocr_service.gemini_available():
        try:
            latex = ocr_service.gemini_to_latex(image_bytes)
            print(f"Gemini OCR read LaTeX: {latex}")
            result = solve_problem_from_latex(latex)
            if not result.get("success"):
                print(f"Gemini OCR solve failed: {result.get('error')}")
        except ocr_service.OCRServiceError as e:
            print(f"Gemini OCR failed: {e}")
            pass  # fall through to the local engine
    else:
        print("Gemini OCR skipped: GEMINI_API_KEY is not configured.")

    # Local pix2tex as an offline fallback: no key, or Gemini didn't solve. A
    # crash here (bad image, model error) is treated the same as an unreadable
    # scan so the caller still gets an honest failure.
    if not result.get("success") and settings.disable_pix2tex:
        print("pix2tex OCR skipped: DISABLE_PIX2TEX=true")
    elif not result.get("success"):
        try:
            pix_latex = ocr_service.pix2tex_to_latex(image_bytes)
            print(f"pix2tex OCR read LaTeX: {pix_latex}")
            latex = pix_latex
            result = solve_problem_from_latex(pix_latex)
            if not result.get("success"):
                print(f"pix2tex OCR solve failed: {result.get('error')}")
        except Exception as e:
            print(f"pix2tex OCR failed: {e}")
            pass  # keep the cloud/failure result

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
