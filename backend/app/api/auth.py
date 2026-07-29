from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Request, status
from pydantic import BaseModel, EmailStr, field_validator
from sqlalchemy.orm import Session
import secrets

from app.database.db import get_db
from app.database.models import PasswordResetToken, User
from app.rate_limit import limiter
from app.services.auth_service import (
    create_access_token,
    build_password_reset_url,
    create_password_reset_token,
    get_current_user,
    google_sign_in_configured,
    hash_password,
    password_reset_expires_at,
    password_reset_token_hash,
    send_password_reset_email,
    verify_google_id_token,
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


class GoogleLoginRequest(BaseModel):
    id_token: str


class ForgotPasswordRequest(BaseModel):
    email: EmailStr


class ResetPasswordRequest(BaseModel):
    token: str
    new_password: str

    @field_validator("new_password")
    @classmethod
    def password_min_length(cls, value: str) -> str:
        if len(value) < 8:
            raise ValueError("Password must be at least 8 characters long")
        return value


class MessageResponse(BaseModel):
    message: str


# `request: Request` is required by slowapi's limiter and is why the JSON body
# is bound to `payload` here (not the usual `request`). Limits are per client IP.
@router.post("/register", response_model=RegisterResponse)
@limiter.limit("5/minute")
def register(request: Request, payload: RegisterRequest, db: Session = Depends(get_db)):
    if db.query(User).filter(User.email == payload.email).first() is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="An account with this email already exists",
        )

    user = User(
        email=payload.email,
        password_hash=hash_password(payload.password),
        full_name=payload.full_name,
        section=payload.section,
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
@limiter.limit("10/minute")
def login(request: Request, payload: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == payload.email).first()

    if user is None or not verify_password(payload.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
        )

    return LoginResponse(access_token=create_access_token(user.id))


@router.post("/password/forgot", response_model=MessageResponse)
@limiter.limit("5/minute")
def forgot_password(
    request: Request, payload: ForgotPasswordRequest, db: Session = Depends(get_db)
):
    message = "If an account exists for that email, a reset link has been sent."
    user = db.query(User).filter(User.email == payload.email.lower()).first()
    if user is None:
        return MessageResponse(message=message)

    raw_token = create_password_reset_token()
    reset_token = PasswordResetToken(
        user_id=user.id,
        token_hash=password_reset_token_hash(raw_token),
        expires_at=password_reset_expires_at(),
    )
    db.add(reset_token)
    db.commit()

    try:
        send_password_reset_email(user.email, build_password_reset_url(raw_token))
    except Exception as e:
        print(f"Warning: password reset email failed: {e}")

    return MessageResponse(message=message)


@router.post("/password/reset", response_model=MessageResponse)
@limiter.limit("5/minute")
def reset_password(
    request: Request, payload: ResetPasswordRequest, db: Session = Depends(get_db)
):
    now = datetime.now(timezone.utc).replace(tzinfo=None)
    reset_token = (
        db.query(PasswordResetToken)
        .filter(PasswordResetToken.token_hash == password_reset_token_hash(payload.token))
        .first()
    )

    if (
        reset_token is None
        or reset_token.used_at is not None
        or reset_token.expires_at < now
    ):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="This reset link is invalid or has expired.",
        )

    user = db.query(User).filter(User.id == reset_token.user_id).first()
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="This reset link is invalid or has expired.",
        )

    user.password_hash = hash_password(payload.new_password)
    reset_token.used_at = now
    db.commit()
    return MessageResponse(message="Password reset successful. You can now log in.")


@router.post("/google", response_model=LoginResponse)
@limiter.limit("10/minute")
def google_login(
    request: Request, payload: GoogleLoginRequest, db: Session = Depends(get_db)
):
    if not google_sign_in_configured():
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Google Sign-In is not configured",
        )

    try:
        claims = verify_google_id_token(payload.id_token)
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate Google sign-in",
        )

    if claims.get("email_verified") is not True:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Google account email is not verified",
        )

    email = str(claims.get("email") or "").strip().lower()
    if not email:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Google account did not provide an email",
        )

    user = db.query(User).filter(User.email == email).first()
    if user is None:
        full_name = str(claims.get("name") or email.split("@")[0]).strip()
        user = User(
            email=email,
            password_hash=hash_password(secrets.token_urlsafe(32)),
            full_name=full_name or email,
        )
        db.add(user)
        db.commit()
        db.refresh(user)

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
