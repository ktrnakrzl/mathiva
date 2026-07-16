from fastapi import APIRouter, Depends, File, HTTPException, UploadFile

from app.database.models import User
from app.services.auth_service import get_current_user
from app.services.solver_service import solve_image

router = APIRouter(
    prefix="/api",
    tags=["ocr"]
)


@router.post("/solve-image")
async def solve_image_endpoint(
    image: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
):
    try:
        image_bytes = await image.read()
        # Hybrid OCR: local pix2tex first, Gemini fallback only if that fails.
        return solve_image(image_bytes)

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=str(e)
        )
