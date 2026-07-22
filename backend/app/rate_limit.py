"""Shared per-IP request limiter (slowapi).

One `Limiter` instance, imported by the routers that need throttling and wired
into the app in `main.py` (`app.state.limiter` + the 429 handler). It guards the
endpoints that are cheap to abuse and expensive to serve:

  * `/auth/register`, `/auth/login` -- account-spam and credential stuffing;
  * `/api/ask`, `/api/ask/stream`, `/api/solve-image` -- every call can reach the
    free-tier Gemini API, so an unthrottled endpoint drains the shared quota and
    takes the tutor down for everyone.

Keyed by client IP (`get_remote_address`). **Behind a reverse proxy** that key is
the *proxy's* IP unless uvicorn is started with `--proxy-headers` and
`--forwarded-allow-ips=...`; without those every user shares one bucket. See
DEPLOY.md.

Disabled when `settings.rate_limit_enabled` is False. The test suite sets
`RATE_LIMIT_ENABLED=false` before importing the app: with the limiter disabled
slowapi's decorator short-circuits *before* it looks up `app.state.limiter`, so
the decorated routes work on the bare app that conftest builds (which never sets
that state).
"""

from slowapi import Limiter
from slowapi.util import get_remote_address

from app.config import settings

limiter = Limiter(key_func=get_remote_address, enabled=settings.rate_limit_enabled)
