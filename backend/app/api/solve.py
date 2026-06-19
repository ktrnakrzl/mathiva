from fastapi import APIRouter, HTTPException, Query

from app.services.solver_service import solve_problem

router = APIRouter(
    prefix="/api",
    tags=["solve"]
)


@router.post("/solve")
def solve(equation: str = Query(...)):
    try:
        return solve_problem(equation)

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=str(e)
        )