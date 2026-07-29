# Deploying MATHIVA

This repo ships a **Dockerfile** for the FastAPI backend. The Flutter app is
built and distributed separately (see the last section).

## What the image contains
- The FastAPI backend + its RAG retrieval (SBERT + FAISS) and SymPy solver.
- The prebuilt FAISS index + course-material chunks (`ml/retrieval/`).
- CPU-only PyTorch and the SBERT embedding model (baked in).

**Not** in the image (by design): Ollama/Phi-3 and the ~1 GB fine-tuned T5 model.
In a hosted deployment the `/ask` cascade automatically uses **Google Gemini**, so
run with `DISABLE_T5=true` and a `GEMINI_API_KEY`.

> The image is inherently large (~2–3 GB) because RAG needs PyTorch + Transformers.
> That's expected for this stack.

## Prerequisites
- Docker installed and running.
- A **Supabase (PostgreSQL)** connection string for production.
- A free **Gemini API key** (https://aistudio.google.com).

## 1. Configure
Create `backend/.env` with production values:

```
ENVIRONMENT=production
DATABASE_URL=postgresql://postgres:<password>@<host>:5432/postgres
JWT_SECRET=<python -c "import secrets; print(secrets.token_hex(32))">
GEMINI_API_KEY=<your key>
DISABLE_T5=true
GOOGLE_CLIENT_ID=your-google-oauth-web-client-id.apps.googleusercontent.com
FRONTEND_URL=https://your-frontend-domain
SMTP_HOST=<your SMTP host>
SMTP_PORT=587
SMTP_USERNAME=<your SMTP username>
SMTP_PASSWORD=<your SMTP password>
SMTP_FROM_EMAIL=<verified sender email>
SMTP_FROM_NAME=Mathiva
SMTP_USE_TLS=true
```

Special characters in the DB password must be percent-encoded (e.g. `@` → `%40`).
`.env` is gitignored and is passed to the container at **runtime**, never baked in.

## 2. Build & run

**With docker compose (easiest):**
```bash
docker compose up --build
```

**Or with plain Docker:**
```bash
docker build -t mathiva-backend .
docker run --rm -p 8000:8000 --env-file backend/.env mathiva-backend
```

On start the container runs `alembic upgrade head` (set `RUN_MIGRATIONS=0` to
skip) and then serves on port 8000. Verify:

```bash
curl http://localhost:8000/health      # -> {"status":"ok"}
```

`http://localhost:8000/docs` shows the interactive API.

## 3. Deploy to a host
The image runs anywhere that accepts a container. Typical options:

- **Render / Railway / Fly.io** — point the service at this repo/Dockerfile, set
  the env vars from step 1 in the dashboard, expose port 8000. These read `$PORT`
  automatically (the CMD honors it).
- **A VPS** — `docker build` + `docker run` behind a reverse proxy (Caddy/Nginx)
  that terminates HTTPS.

The startup guard (`settings.validate_runtime()`) refuses to boot in production if
the JWT secret is weak/default or `DATABASE_URL` is still SQLite — a safety net.

### Rate limiting behind a proxy (important)
The auth and Gemini-backed endpoints are throttled **per client IP** (slowapi):
`/auth/register` 5/min, `/auth/login` 10/min, `/api/ask`, `/api/ask/stream`, and
`/api/solve-image` 20/min each. A tripped limit returns HTTP 429.

Almost every host above puts a reverse proxy in front of the container, so the
IP the app sees is the *proxy's* — which would make all users share one bucket.
The image starts uvicorn with `--proxy-headers` and
`--forwarded-allow-ips="${FORWARDED_ALLOW_IPS:-*}"` so PaaS deployments work
without a custom start command.

Use the default `*` only when the container is reachable *exclusively* through
your proxy (the usual PaaS/VPS-behind-Nginx case); otherwise a client could spoof
`X-Forwarded-For` to dodge the limit. Prefer setting `FORWARDED_ALLOW_IPS` to the
proxy's IP where you know it. To disable throttling entirely (not recommended in
production) set `RATE_LIMIT_ENABLED=false`.

## 4. Point the app at the deployed backend
The Flutter app reads its backend URL from a compile-time define, so no code edit
is needed:

```bash
flutter build web --dart-define=API_BASE_URL=https://your-deployed-backend --dart-define=GOOGLE_CLIENT_ID=your-google-oauth-web-client-id.apps.googleusercontent.com --web-define=GOOGLE_CLIENT_ID=your-google-oauth-web-client-id.apps.googleusercontent.com
# or for a device build, pass the same --dart-define
```

## Security checklist before going live
- [ ] **Rotate the Supabase database password** if it was ever shared, and update
      `DATABASE_URL`.
- [ ] Strong `JWT_SECRET` (≥ 32 bytes) — the startup guard enforces this.
- [ ] **Restrict CORS** — set `CORS_ORIGINS` to your app's origin(s), e.g.
      `CORS_ORIGINS="https://app.example.com"` (comma-separate multiple). Only
      needed for a *web* frontend; native mobile clients don't enforce CORS.
      Default `*` is otherwise safe here (Bearer-token auth, no cookies).
- [x] Rate limiting on `/auth/*` and the Gemini-backed routes — **enabled** (see
      "Rate limiting behind a proxy" above; set `FORWARDED_ALLOW_IPS` if your
      host requires a pinned proxy IP).
