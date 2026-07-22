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
    # "gemini-flash-latest" is an alias that always tracks Google's current free
    # flash model, so a specific version being retired (as gemini-2.5-flash was)
    # never breaks the tutor/OCR. Pin a concrete version here only if you need
    # reproducible behavior.
    gemini_model: str = Field(default="gemini-flash-latest", validation_alias="GEMINI_MODEL")

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

    # Skip the fine-tuned T5 tier in the /ask cascade. Set true in the hosted
    # (Gemini-backed, no-Ollama) deployment: with no Phi-3 there, T5 would be the
    # primary local generator, but at its current tiny-dataset quality it emits
    # degenerate/wrong answers that can slip past the is_bad_answer guard and
    # block Gemini. Leave false for local dev / the defense demo, where T5 is the
    # thesis contribution being showcased. Flip back to false once T5 is improved.
    disable_t5: bool = Field(default=False, validation_alias="DISABLE_T5")

    @property
    def cors_origin_list(self) -> list[str]:
        """Parse CORS_ORIGINS into a list. "*" (or empty) allows any origin."""
        raw = self.cors_origins.strip()
        if not raw or raw == "*":
            return ["*"]
        return [origin.strip() for origin in raw.split(",") if origin.strip()]

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
