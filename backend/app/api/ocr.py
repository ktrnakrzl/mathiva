from fastapi import APIRouter, Depends, File, HTTPException, UploadFile

from app.database.models import User
from app.services.auth_service import get_current_user
from app.services.ocr_service import image_to_latex
from app.services.solver_service import solve_problem_from_latex

router = APIRouter(
    prefix="/api",
    tags=["ocr"]
)


@router.post("/solve-image")
async def solve_image(
    image: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
):
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
