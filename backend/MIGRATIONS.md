# Backend configuration & database migrations

## Configuration (`app/config.py`)

All environment-driven settings live in one typed place — the `settings`
singleton — instead of scattered `os.getenv` calls. Modules import `settings`.

Environment variables (set in `backend/.env`, or the real environment):

| Variable | Default | Notes |
|---|---|---|
| `ENVIRONMENT` | `development` | Set to `production` to enable the startup guard below |
| `DATABASE_URL` | `sqlite:///./mathiva.db` | Point at Postgres (e.g. Supabase) for a real deploy |
| `JWT_SECRET` | *(insecure dev default)* | Must be ≥ 32 bytes in production |
| `JWT_ALGORITHM` | `HS256` | |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | `1440` | Token lifetime |
| `GEMINI_API_KEY` | *(unset)* | Enables the Gemini answer/OCR fallback; absent = tier skipped |
| `GEMINI_MODEL` | `gemini-2.5-flash` | |

**Startup guard.** `main.py` calls `settings.validate_runtime()`. In production it
fails fast if the JWT secret is the dev default or too short, or if `DATABASE_URL`
still points at SQLite. In development it is a no-op, so the app runs with zero
setup.

Generate a strong secret:

```bash
python -c "import secrets; print(secrets.token_urlsafe(48))"
```

## Migrations (Alembic)

Schema is versioned with Alembic (`alembic/`). The migration environment reads
`DATABASE_URL` from `settings`, so migrations always hit the same database the app
does.

**Dev (SQLite):** tables are auto-created by `create_all` at startup for
zero-setup convenience, so you don't strictly need Alembic locally.

**Production (Postgres):** `main.py` does *not* auto-create tables — Alembic is the
single source of truth. Run migrations before starting the server:

```bash
alembic upgrade head
```

### Common commands (run from `backend/`)

```bash
alembic upgrade head                          # apply all migrations
alembic current                               # show the DB's current revision
alembic revision --autogenerate -m "message"  # create a migration from model changes
alembic downgrade -1                           # roll back one migration
alembic stamp head                             # mark an existing DB as up-to-date
```

After changing a model in `app/database/models.py`, run the `--autogenerate`
command, **review the generated file** in `alembic/versions/`, then `upgrade head`.

## Switching to Supabase Postgres (next infra step)

1. Create a Supabase project and copy its connection string.
2. In `backend/.env`:
   ```
   ENVIRONMENT=production
   DATABASE_URL=postgresql://postgres:<password>@<host>:5432/postgres
   JWT_SECRET=<a strong 32+ byte secret>
   ```
3. `alembic upgrade head` to create the schema on Postgres.
4. Start the server — `validate_runtime()` will confirm the config is safe.
