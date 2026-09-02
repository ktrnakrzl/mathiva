"""Central application settings.

Every environment-driven value the backend needs is declared here once, typed and
validated, instead of scattered `os.getenv` calls. Modules import the singleton
`settings` rather than reading the environment directly.

Values come from real environment variables first, then `backend/.env` as a
fallback (the app also calls `load_dotenv()` at startup, so in practice the
values are already in the environment by the time this loads). Defaults keep the
app runnable with zero setup for local development and tests.

Call `settings.validate_runtime()` once at startup (main.py) so a misconfigured
*production* deployment fails fast and loudly instead of silently running with a
dev secret or a throwaway SQLite file.
"""

from pathlib import Path

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict

# backend/.env, resolved from this file's location so it works regardless of the
# process's current working directory.
_ENV_FILE = Path(__file__).resolve().parent.parent / ".env"

_DEV_JWT_SECRET = "dev-secret-change-in-production"


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=str(_ENV_FILE),
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # "development" (default) | "production". Flips the strict validation below.
    environment: str = Field(default="development", validation_alias="ENVIRONMENT")

    # Database. Defaults to a local SQLite file so auth works with zero setup;
    # set DATABASE_URL to a Postgres URL (e.g. Supabase) for a real deployment.
    database_url: str = Field(default="sqlite:///./mathiva.db", validation_alias="DATABASE_URL")

    # Auth / JWT.
    jwt_secret: str = Field(default=_DEV_JWT_SECRET, validation_alias="JWT_SECRET")
    jwt_algorithm: str = Field(default="HS256", validation_alias="JWT_ALGORITHM")
    access_token_expire_minutes: int = Field(
        default=24 * 60, validation_alias="ACCESS_TOKEN_EXPIRE_MINUTES"
    )

    # Gemini free-tier fallback (also used by OCR). Optional: absent key just
    # disables the Gemini tier.
    gemini_api_key: str | None = Field(default=None, validation_alias="GEMINI_API_KEY")
    # Stable Gemini model used by tutor fallback and OCR. Keep this pinned so a
    # non-existent/latest alias cannot break the hosted demo unexpectedly.
    gemini_model: str = Field(default="gemini-2.5-flash", validation_alias="GEMINI_MODEL")

    # Google Sign-In OAuth web client ID. The frontend obtains a Google ID
    # token and /auth/google verifies that its audience matches this client ID
    # before issuing Mathiva's own JWT.
    google_client_id: str | None = Field(default=None, validation_alias="GOOGLE_CLIENT_ID")

    # Public frontend origin used to build password-reset links in emails.
    frontend_url: str = Field(default="http://localhost:3000", validation_alias="FRONTEND_URL")

    # SMTP settings for transactional emails such as password reset. If these
    # are absent, reset emails are skipped but the public API response stays
    # generic so account existence is never leaked.
    brevo_api_key: str | None = Field(default=None, validation_alias="BREVO_API_KEY")
    resend_api_key: str | None = Field(default=None, validation_alias="RESEND_API_KEY")
    email_from: str | None = Field(default=None, validation_alias="EMAIL_FROM")
    smtp_host: str | None = Field(default=None, validation_alias="SMTP_HOST")
    smtp_port: int = Field(default=587, validation_alias="SMTP_PORT")
    smtp_username: str | None = Field(default=None, validation_alias="SMTP_USERNAME")
    smtp_password: str | None = Field(default=None, validation_alias="SMTP_PASSWORD")
    smtp_from_email: str | None = Field(default=None, validation_alias="SMTP_FROM_EMAIL")
    smtp_from_name: str = Field(default="Mathiva", validation_alias="SMTP_FROM_NAME")
    smtp_use_tls: bool = Field(default=True, validation_alias="SMTP_USE_TLS")

    # Second cloud fallback for the /ask cascade -- the backstop's backstop,
    # used only when Gemini is rate-limited or failing. Optional: absent key
    # just disables the tier. The endpoint is OpenAI-compatible, so
    # FALLBACK_BASE_URL can point at any compatible provider without code
    # changes. Default: Cerebras' free tier (1M tokens/day, no card) serving
    # Llama 3.3 70B.
    fallback_api_key: str | None = Field(default=None, validation_alias="FALLBACK_API_KEY")
    fallback_model: str = Field(default="gpt-oss-120b", validation_alias="FALLBACK_MODEL")
    fallback_base_url: str = Field(
        default="https://api.cerebras.ai/v1", validation_alias="FALLBACK_BASE_URL"
    )

    # Per-IP request throttling (slowapi) on the auth + Gemini-backed endpoints.
    # On by default everywhere, including local dev, so the limits are exercised
    # before production. The test suite sets RATE_LIMIT_ENABLED=false so the API
    # tests aren't throttled (see backend/tests/conftest.py and app/rate_limit.py).
    rate_limit_enabled: bool = Field(default=True, validation_alias="RATE_LIMIT_ENABLED")

    # Allowed CORS origins for browser clients, comma-separated. Default "*" is
    # safe for this app because auth is a Bearer token (not cookies) and native
    # mobile clients don't enforce CORS at all. For a *web* deployment, lock this
    # to your app's origin(s), e.g. CORS_ORIGINS="https://app.example.com".
    cors_origins: str = Field(default="*", validation_alias="CORS_ORIGINS")

    # Cache /ask answers per (normalized) question so repeated questions don't
    # re-hit the model backends -- the main lever for staying under Gemini's
    # free-tier limit. On by default; the test suite sets it off (conftest.py) so
    # a cached answer can't leak between tests.
    answer_cache_enabled: bool = Field(default=True, validation_alias="ANSWER_CACHE_ENABLED")

    # Skip the fine-tuned T5 tier in the /ask cascade. Set true in the hosted
    # (Gemini-backed, no-Ollama) deployment: with no Phi-3 there, T5 would be the
    # primary local generator, but at its current tiny-dataset quality it emits
    # degenerate/wrong answers that can slip past the is_bad_answer guard and
    # block Gemini. Leave false for local dev / the defense demo, where T5 is the
    # thesis contribution being showcased. Flip back to false once T5 is improved.
    disable_t5: bool = Field(default=False, validation_alias="DISABLE_T5")

    # Skip local Ollama/Phi-3 calls in hosted deployments that do not run an
    # Ollama sidecar. This avoids waiting on localhost:11434 before falling back
    # to cloud APIs.
    disable_ollama: bool = Field(default=False, validation_alias="DISABLE_OLLAMA")

    # Use true streaming from local Ollama only when explicitly enabled. Hosted
    # deployments should stream the cloud cascade as a single text chunk instead
    # of probing localhost and risking a 503 in the web chat.
    enable_ollama_stream: bool = Field(
        default=False, validation_alias="ENABLE_OLLAMA_STREAM"
    )

    # Skip local pix2tex OCR fallback. Hosted deployments should normally use
    # Gemini OCR only: pix2tex downloads ~100 MB of weights on first use and is
    # poor on real camera photos, which can make Render requests stall.
    disable_pix2tex: bool = Field(default=False, validation_alias="DISABLE_PIX2TEX")

    @property
    def cors_origin_list(self) -> list[str]:
        """Parse CORS_ORIGINS into a list. "*" (or empty) allows any origin."""
        raw = self.cors_origins.strip()
        if not raw or raw == "*":
            return ["*"]
        origins = [origin.strip() for origin in raw.split(",") if origin.strip()]
        # Keep local Flutter web usable even when production CORS is locked to
        # the deployed frontend. These origins do not weaken token auth; they
        # only let Chrome finish local-dev preflight requests.
        for origin in (
            "http://localhost:5173",
            "http://127.0.0.1:5173",
            "http://localhost:5000",
            "http://127.0.0.1:5000",
        ):
            if origin not in origins:
                origins.append(origin)
        return origins

    @property
    def is_production(self) -> bool:
        return self.environment.strip().lower() in ("production", "prod")

    @property
    def is_sqlite(self) -> bool:
        return self.database_url.startswith("sqlite")

    def validate_runtime(self) -> None:
        """Fail fast on a misconfigured *production* deployment. No-op in dev/test
        so the zero-setup defaults keep working."""
        if not self.is_production:
            return
        problems = []
        if self.jwt_secret == _DEV_JWT_SECRET:
            problems.append("JWT_SECRET is still the insecure dev default.")
        if len(self.jwt_secret.encode("utf-8")) < 32:
            problems.append("JWT_SECRET must be at least 32 bytes for HS256.")
        if self.is_sqlite:
            problems.append("DATABASE_URL points at SQLite; use Postgres in production.")
        if problems:
            raise RuntimeError(
                "Invalid production configuration:\n  - " + "\n  - ".join(problems)
            )


# Import-time singleton: read the environment once, reuse everywhere.
settings = Settings()
