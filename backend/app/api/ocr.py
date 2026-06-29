from fastapi import APIRouter, File, HTTPException, UploadFile

from app.services.ocr_service import image_to_latex
from app.services.solver_service import solve_problem_from_latex

router = APIRouter(
    prefix="/api",
    tags=["ocr"]
)


@router.post("/solve-image")
async def solve_image(image: UploadFile = File(...)):
    try:
        image_bytes = await image.read()
        latex = image_to_latex(image_bytes)

        result = solve_problem_from_latex(latex)
        result["latex"] = latex

        return result

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=str(e)
        )
