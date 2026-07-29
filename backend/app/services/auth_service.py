from datetime import datetime, timedelta, timezone
from email.message import EmailMessage
import hashlib
import smtplib
import secrets
from urllib.parse import urlencode

import bcrypt
import jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session

from app.config import settings
from app.database.db import get_db
from app.database.models import User

# Auth config comes from the central settings (backend/.env). The JWT_SECRET
# default is an insecure dev fallback so auth works out of the box locally;
# settings.validate_runtime() rejects it when ENVIRONMENT=production.
JWT_SECRET = settings.jwt_secret
JWT_ALGORITHM = settings.jwt_algorithm
ACCESS_TOKEN_EXPIRE = timedelta(minutes=settings.access_token_expire_minutes)
PASSWORD_RESET_EXPIRE = timedelta(minutes=30)

# tokenUrl points Swagger's "Authorize" button at the real login endpoint.
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login", auto_error=False)


def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")


def verify_password(password: str, password_hash: str) -> bool:
    return bcrypt.checkpw(password.encode("utf-8"), password_hash.encode("utf-8"))


def create_password_reset_token() -> str:
    return secrets.token_urlsafe(32)


def password_reset_token_hash(token: str) -> str:
    return hashlib.sha256(token.encode("utf-8")).hexdigest()


def password_reset_expires_at() -> datetime:
    return datetime.now(timezone.utc).replace(tzinfo=None) + PASSWORD_RESET_EXPIRE


def build_password_reset_url(token: str) -> str:
    base = settings.frontend_url.rstrip("/")
    return f"{base}/reset-password?{urlencode({'token': token})}"


def reset_email_configured() -> bool:
    return bool(settings.smtp_host and settings.smtp_from_email)


def send_password_reset_email(email: str, reset_url: str) -> None:
    """Send a password reset email via SMTP.

    SMTP is intentionally provider-neutral; Render env vars can point this at
    Gmail, Brevo, Mailgun, Resend SMTP, etc.
    """
    if not reset_email_configured():
        print("Password reset email skipped: SMTP is not configured.")
        return

    msg = EmailMessage()
    msg["Subject"] = "Reset your Mathiva password"
    msg["From"] = f"{settings.smtp_from_name} <{settings.smtp_from_email}>"
    msg["To"] = email
    msg.set_content(
        "Use this link to reset your Mathiva password. "
        "It expires in 30 minutes.\n\n"
        f"{reset_url}\n\n"
        "If you did not request this, you can ignore this email."
    )

    with smtplib.SMTP(settings.smtp_host, settings.smtp_port, timeout=20) as server:
        if settings.smtp_use_tls:
            server.starttls()
        if settings.smtp_username and settings.smtp_password:
            server.login(settings.smtp_username, settings.smtp_password)
        server.send_message(msg)


def google_sign_in_configured() -> bool:
    return bool(settings.google_client_id)


def verify_google_id_token(token: str) -> dict:
    """Verify a Google Sign-In ID token and return its claims.

    The audience check is what binds the token to Mathiva's OAuth client ID; a
    valid Google token minted for some other app must not be accepted here.
    """
    if not settings.google_client_id:
        raise ValueError("Google Sign-In is not configured")

    from google.auth.transport import requests as google_requests
    from google.oauth2 import id_token

    request = google_requests.Request()
    return id_token.verify_oauth2_token(
        token,
        request,
        settings.google_client_id,
    )


def create_access_token(user_id: int) -> str:
    expires_at = datetime.now(timezone.utc) + ACCESS_TOKEN_EXPIRE
    payload = {"sub": str(user_id), "exp": expires_at}
    return jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)


def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
) -> User:
    """Reusable dependency for any future endpoint that needs to require
    login (e.g. /user/profile, /quiz/submit) -- not used by any route yet."""
    credentials_error = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    if token is None:
        raise credentials_error

    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
        user_id = int(payload["sub"])
    except (jwt.PyJWTError, KeyError, ValueError):
        raise credentials_error

    user = db.query(User).filter(User.id == user_id).first()
    if user is None:
        raise credentials_error

    return user
