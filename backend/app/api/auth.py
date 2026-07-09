from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, EmailStr, field_validator
from sqlalchemy.orm import Session

from app.database.db import get_db
from app.database.models import User
from app.services.auth_service import (
    create_access_token,
    get_current_user,
    hash_password,
    verify_password,
)

router = APIRouter(prefix="/auth", tags=["auth"])


class RegisterRequest(BaseModel):
    email: EmailStr
    password: str
    full_name: str
    section: str | None = None

    @field_validator("password")
    @classmethod
    def password_min_length(cls, value: str) -> str:
        if len(value) < 8:
            raise ValueError("Password must be at least 8 characters long")
        return value

    @field_validator("full_name")
    @classmethod
    def full_name_not_blank(cls, value: str) -> str:
        if not value.strip():
            raise ValueError("Full name is required")
        return value


class RegisterResponse(BaseModel):
    user_id: int
    email: str
    message: str


class LoginRequest(BaseModel):
    email: str
    password: str


class LoginResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int = 86400


@router.post("/register", response_model=RegisterResponse)
def register(request: RegisterRequest, db: Session = Depends(get_db)):
    if db.query(User).filter(User.email == request.email).first() is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="An account with this email already exists",
        )

    user = User(
        email=request.email,
        password_hash=hash_password(request.password),
        full_name=request.full_name,
        section=request.section,
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    return RegisterResponse(
        user_id=user.id,
        email=user.email,
        message="Registration successful",
    )


@router.post("/login", response_model=LoginResponse)
def login(request: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == request.email).first()

    if user is None or not verify_password(request.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
        )

    return LoginResponse(access_token=create_access_token(user.id))


class MeResponse(BaseModel):
    id: int
    email: str
    full_name: str
    section: str | None = None
    enrollment_status: str | None = None


@router.get("/me", response_model=MeResponse)
def me(current_user: User = Depends(get_current_user)):
    """Return the profile of the token's owner. The login response only carries
    the JWT, so this is how the app fetches the student's name/section after
    authenticating (e.g. to greet them on the home screen)."""
    return MeResponse(
        id=current_user.id,
        email=current_user.email,
        full_name=current_user.full_name,
        section=current_user.section,
        enrollment_status=current_user.enrollment_status,
    )
