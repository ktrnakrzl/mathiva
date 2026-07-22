from fastapi import APIRouter, Depends, File, HTTPException, Request, UploadFile

from app.database.models import User
from app.rate_limit import limiter
from app.services.auth_service import get_current_user
from app.services.solver_service import solve_image

router = APIRouter(
    prefix="/api",
    tags=["ocr"]
)


# `request: Request` is required by slowapi's limiter. OCR can fall back to the
# free-tier Gemini API, so throttle it per client IP alongside /api/ask.
@router.post("/solve-image")
@limiter.limit("20/minute")
async def solve_image_endpoint(
    request: Request,
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
