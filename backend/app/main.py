from fastapi import FastAPI, Response
from fastapi.middleware.cors import CORSMiddleware
import sys
import os

# Load backend/.env FIRST -- DATABASE_URL and JWT_SECRET are read from
# os.environ at import time by app.database.db / app.services.auth_service,
# so this must run before any app.* module is imported below.
from dotenv import load_dotenv
load_dotenv(os.path.join(os.path.dirname(__file__), "../.env"))

# Create app FIRST
app = FastAPI(title="Mathiva API")

# Register the shared per-IP rate limiter (slowapi) so the @limiter.limit
# decorators on the auth + Gemini-backed routes can find it on app.state, and a
# tripped limit returns a clean 429 instead of a 500. No-op when the limiter is
# disabled (tests / RATE_LIMIT_ENABLED=false). See app/rate_limit.py.
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded

from app.rate_limit import limiter
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# Add CORS Middleware SECOND. Origins come from settings (CORS_ORIGINS); default
# "*" is fine for local dev and native mobile (which doesn't enforce CORS), and a
# web deployment locks it to its origin(s). settings is already imported above via
# app.rate_limit, so reading it here loads nothing new.
from app.config import settings as _settings
app.add_middleware(
    CORSMiddleware,
    allow_origins=_settings.cors_origin_list,
    # Auth is Bearer-token in the Authorization header, not cookies, so we don't
    # need credentialed CORS -- and a wildcard origin with allow_credentials=True
    # is rejected by browsers anyway. Keeping this False makes "*" valid.
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],
)

# Add ML path THIRD (before importing routers/modules that depend on it)
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "../../ml"))

# Now import and include routers FOURTH
from app.api.solve import router as solve_router
app.include_router(solve_router)

from app.api.ocr import router as ocr_router
app.include_router(ocr_router)

from app.api.ask import router as ask_router
app.include_router(ask_router)

from app.api.auth import router as auth_router
app.include_router(auth_router)

from app.api.quiz import router as quiz_router
app.include_router(quiz_router)

from app.config import settings

# Fail fast on a misconfigured production deployment (dev secret / SQLite / weak
# key). No-op in development so the zero-setup defaults keep working.
settings.validate_runtime()

from app.database.db import Base, engine
# app.api.auth/app.api.quiz (imported above) already import
# app.database.models, which registers User/QuizAttempt on Base.
#
# On SQLite (local dev) we auto-create the tables so the app runs with zero
# setup. On Postgres (production) schema is managed by Alembic instead -- run
# `alembic upgrade head` before starting the server -- so we do NOT create_all
# there and let migrations be the single source of truth.
if settings.is_sqlite:
    Base.metadata.create_all(bind=engine)


@app.on_event("startup")
def warm_up_ollama():
    if settings.disable_ollama:
        print("Ollama warm-up skipped: DISABLE_OLLAMA=true")
        return

    # Pay Ollama's model-load-into-VRAM cost once at server startup instead
    # of on a real user's first /api/ask request — without this, the first
    # request after any 5+ minute gap (Ollama's default keep_alive) can take
    # minutes instead of seconds.
    from app.services.ai_service import generate_answer
    try:
        generate_answer("Say OK.")
    except Exception as e:
        print(f"Warning: Ollama warm-up failed (is Ollama running?): {e}")


@app.get("/")
def root():
    return {
        "name": "Mathiva API",
        "status": "ok",
        "health": "/health",
        "docs": "/docs",
    }


@app.head("/")
def root_head():
    return Response(status_code=200)


@app.get("/favicon.ico", include_in_schema=False)
def favicon():
    return Response(status_code=204)


@app.get("/health")
def health():
    return {"status": "ok"}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
