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

## 4. Point the app at the deployed backend
The Flutter app reads its backend URL from a compile-time define, so no code edit
is needed:

```bash
flutter build web --dart-define=API_BASE_URL=https://your-deployed-backend
# or for a device build, pass the same --dart-define
```

## Security checklist before going live
- [ ] **Rotate the Supabase database password** if it was ever shared, and update
      `DATABASE_URL`.
- [ ] Strong `JWT_SECRET` (≥ 32 bytes) — the startup guard enforces this.
- [ ] Restrict CORS in `app/main.py` from `*` to your app's origin.
- [ ] Consider rate limiting on `/auth/login` and `/api/ask`.
