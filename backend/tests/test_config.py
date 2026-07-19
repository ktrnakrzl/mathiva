"""Tests for the central settings and its production guard.

validate_runtime() must be a no-op in development (so zero-setup defaults keep
working) and must reject an unsafe production configuration (dev JWT secret,
too-short secret, or SQLite) so a misconfigured deploy fails fast at startup.
"""

import pytest

from app.config import Settings

_STRONG_SECRET = "x" * 40
_PG_URL = "postgresql://user:pass@db.example.com:5432/mathiva"


def _settings(monkeypatch, **env):
    """Build a Settings from an explicit environment (env vars win over .env)."""
    for k, v in env.items():
        monkeypatch.setenv(k, v)
    return Settings()


def test_dev_validation_is_a_noop(monkeypatch):
    s = _settings(monkeypatch, ENVIRONMENT="development",
                  JWT_SECRET="dev-secret-change-in-production",
                  DATABASE_URL="sqlite:///./mathiva.db")
    s.validate_runtime()  # must not raise
    assert s.is_production is False
    assert s.is_sqlite is True


def test_production_rejects_dev_secret_and_sqlite(monkeypatch):
    s = _settings(monkeypatch, ENVIRONMENT="production",
                  JWT_SECRET="dev-secret-change-in-production",
                  DATABASE_URL="sqlite:///./mathiva.db")
    with pytest.raises(RuntimeError) as exc:
        s.validate_runtime()
    msg = str(exc.value)
    assert "JWT_SECRET" in msg
    assert "SQLite" in msg


def test_production_rejects_short_secret(monkeypatch):
    s = _settings(monkeypatch, ENVIRONMENT="production",
                  JWT_SECRET="tooshort", DATABASE_URL=_PG_URL)
    with pytest.raises(RuntimeError) as exc:
        s.validate_runtime()
    assert "32 bytes" in str(exc.value)


def test_production_accepts_strong_config(monkeypatch):
    s = _settings(monkeypatch, ENVIRONMENT="production",
                  JWT_SECRET=_STRONG_SECRET, DATABASE_URL=_PG_URL)
    s.validate_runtime()  # must not raise
    assert s.is_production is True
    assert s.is_sqlite is False
