from fastapi import APIRouter, Depends, HTTPException, Query

from app.database.models import User
from app.services.auth_service import get_current_user
from app.services.solver_service import solve_problem

router = APIRouter(
    prefix="/api",
    tags=["solve"]
)


@router.post("/solve")
def solve(
    equation: str = Query(...),
    current_user: User = Depends(get_current_user),
):
    try:
        return solve_problem(equation)

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=str(e)
        )