# MATHIVA — Complete Technical System Reference

> A full, accurate technical description of the MATHIVA system as it actually
> exists in the codebase. Written to give you (or any AI/reviewer) complete
> grounding for the thesis and for continued development. Pairs with
> `MATHIVA_THESIS_CONTEXT.md` (Chapters 1–3 framing) and `MATHIVA_AI_HANDOFF.md`
> (current project state / what to do next).

---

## 1. What MATHIVA is

A mobile-first intelligent tutoring system for Philippine Senior High School
mathematics (Grade 11–12 DepEd: General Mathematics, Statistics & Probability,
Pre-Calculus, Basic Calculus). Three capabilities in one app:

1. **Equation solver** — reads typed *or* photographed math and returns
   step-by-step, *computed* (not guessed) solutions.
2. **AI math tutor** — answers conceptual questions, grounded in course material
   via Retrieval-Augmented Generation (RAG) plus a cascade of language models.
3. **Adaptive practice** — generates quizzes whose concept and difficulty adapt
   to the student's own performance history, with spaced-repetition review.

Stated research contribution: *"RAG with a fine-tuned transformer"* for in-domain
math tutoring. (See §9 for the honest state of the fine-tune.)

---

## 2. Architecture (three tiers)

```
Flutter mobile app ──HTTP/JSON──► FastAPI backend ──► SQL database
  (presentation)                   (application)       (SQLite dev /
        │                               │               Supabase Postgres prod)
        │                               ▼
        │              ML / AI services (in-process + external):
        │              • RAG: SBERT (all-MiniLM-L6-v2) + FAISS
        │              • Fine-tuned flan-t5 (local tutor model)
        │              • Phi-3 via Ollama (local generalist, dev only)
        │              • Google Gemini (free tier — production tutor + OCR)
        │              • SymPy (exact symbolic solving)
        │              • pix2tex (local image→LaTeX OCR, offline fallback)
```

Backend is layered: **API routers** (thin request/response) → **services**
(business logic) → **data** (SQLAlchemy models + session).

---

## 3. Technology stack

**Mobile (Flutter/Dart):** go_router (nav), flutter_riverpod (state), dio (HTTP),
flutter_math_fork (LaTeX render), image_picker/image_cropper (scan capture),
flutter_local_notifications (study reminders), shared_preferences (on-device
storage: JWT + recent-scan history), google_fonts, flutter_svg.

**Backend (Python/FastAPI):** FastAPI, Uvicorn, SQLAlchemy, Alembic (migrations),
Pydantic / pydantic-settings (typed config), bcrypt (password hash), PyJWT (auth),
python-multipart (uploads), slowapi (rate limiting), requests (Ollama/Gemini),
psycopg2-binary + pgvector (Postgres).

**ML/AI:** sentence-transformers (`all-MiniLM-L6-v2`), faiss-cpu, transformers,
torch (CPU), FLAN-T5 (fine-tuned), Ollama+Phi-3 (local), Google Gemini
(`gemini-flash-latest`), SymPy + antlr4 (solve + LaTeX parse), pix2tex + Pillow (OCR).

**Infra:** SQLite (dev), Supabase PostgreSQL (prod), Docker, GitHub Actions (CI/CD).

---

## 4. Repository layout

```
backend/
  app/
    main.py               # app factory: CORS, rate limiter, routers, startup guard
    config.py             # typed Settings (env-driven) + validate_runtime()
    rate_limit.py         # shared slowapi limiter
    api/                  # thin routers: ask, ocr, solve, auth, quiz
    services/             # business logic (see §5–§10)
    database/             # models.py (User/QuizQuestion/QuizAttempt), db.py
  tests/                  # 170 pytest tests
  alembic/                # DB migrations (source of truth for the Postgres schema)
  requirements.txt        # pinned runtime deps
  requirements-dev.txt    # pytest + httpx (test-only)
  ARCHITECTURE.md         # backend walkthrough
frontend/                 # Flutter app (lib/screens + lib/services = live path)
ml/
  retrieval/              # RAG corpus + QA generation + FAISS build
  solver/math_solver.py   # the SymPy symbolic solver
  t5/                     # fine-tune: prepare_dataset.py, train.py, eval.py, model/
Dockerfile, docker-compose.yml, DEPLOY.md
.github/workflows/ci.yml  # CI/CD
```

---

## 5. The AI tutor — `/ask` answer cascade

**File:** `backend/app/services/answer_service.py` (`answer_question`).
**Only path that uses RAG.**

Flow for a conceptual question:

1. **Cache check** — normalized-question key; a hit returns immediately (no model
   call). Bounded LRU (256), toggle `ANSWER_CACHE_ENABLED`. *This is the main
   lever for staying under Gemini's free-tier limit.*
2. **RAG retrieve** — SBERT embeds the question → FAISS cosine search → top-k
   chunks become the "Course Material" in the shared tutor prompt.
3. **Local layer** — the fine-tuned **T5** (skipped if `DISABLE_T5`) and **Phi-3**
   (Ollama) *both* attempt. **Phi-3 is preferred** when good (currently the
   stronger local generator); T5 is the backup. `is_bad_answer()` flags empty or
   degenerate (repetition-loop) output.
4. **Bounded Gemini escalation** — Gemini is called *only* if the local answer is
   still bad, so the free tier isn't spent per question.
5. **Resilience** — a Gemini **429** raises `GeminiRateLimitError`; if that was
   the only option, the cascade raises `TutorBusyError` and `/ask` returns a 503
   *"tutor is busy, try again in a moment"* + `Retry-After` header (not a raw error).
6. Response carries `model_used` (phi3 / t5 / gemini) and `sources`.

**Ranking is empirical, not architectural** — Phi-3 is preferred over T5 because
it currently wins the eval; flip once T5 improves.

`/ask/stream` streams Ollama tokens live; with no Ollama (hosted) it falls back to
the full cascade (→ Gemini) delivered as one chunk.

---

## 6. The solver — `/solve-image` (photo) and `/solve` (typed)

**Files:** `backend/app/services/solver_service.py`, `ocr_service.py`,
`tutor_service.py`, `ml/solver/math_solver.py`. **Does NOT use RAG.**

**Photo path (`solve_image`):**
```
photo → Gemini OCR (gemini_to_latex)  ← cloud-first: handles real photos/handwriting
        └─ on failure → pix2tex (local, offline)   ← garbles photos; last resort
      → solve_latex()  (SymPy: exact computation)
      → explain_solution()  (Ollama → Gemini → plain statement of the answer)
```
Correctness comes from **SymPy (exact)**, never from an LLM. The explanation
degrades gracefully (a rate-limited Gemini still yields the correct answer with a
plain explanation). OCR is **Gemini-first** because pix2tex only reads clean
printed math and mangles photographs.

**Typed path (`/solve` → `solve_equation`):** parses student notation (`2x`, `x^2`)
and solves with SymPy.

### Solver capabilities (`ml/solver/math_solver.py`)
- **Equations** (one unknown): `2x + 3 = 13` → `x = 5`; quadratics → real roots.
- **Arithmetic** (no unknown): `89 + 82` → `171`; exact fractions `½ + ⅓` → `⅚`.
- **Inequalities**: `2x + 3 > 7` → `x > 2`; bounded `x² − 4 ≤ 0` → `−2 ≤ x ≤ 2`.
- **Systems**: `x + y = 5, x − y = 1` → `x = 3, y = 2` (comma/`\\`/cases; 2–3 unknowns).
- **Bare expression** → solved against zero (roots), by convention.
- **Garbled-OCR guards** — stray-symbol / non-math-command detection, real-number
  guard, and "only concrete finite real solutions" — so a bad scan fails safe
  ("couldn't read a clear equation") instead of returning a confident wrong answer.

---

## 7. RAG pipeline

**File:** `backend/app/services/rag_service.py`; corpus in `ml/retrieval/`.

- **Corpus:** ~1,108 unique text chunks from the General Mathematics DepEd module
  (PDF-extracted, symbol-recovered/cleaned via `text_clean.py`). **General Math only**
  — the other three subjects have no PDF corpus (LRMDS access was blocked).
- **Retrieval:** SBERT `all-MiniLM-L6-v2` embeddings → **FAISS cosine** search →
  top-k chunks. Index is prebuilt and cached; the same mechanics are reused in
  `ml/t5/prepare_dataset.py`'s RAG mode.
- RAG grounds the `/ask` tutor only. The solver and quiz do not use it.

---

## 8. Quiz & adaptive personalization

**Files:** `question_generator.py`, `quiz_templates.py`, `adaptive_quiz.py`.

- **Parametric templates** (11 concept generators) randomize the numbers and
  **compute the correct answer in Python**, so grading is trustworthy; an LLM may
  optionally rephrase wording only (never numbers/answer). Server owns the answer
  (no client-side "is this correct").
- **Server-side adaptive selection** (`adaptive_quiz.py`) reads the student's
  `QuizAttempt` history:
  - *Concept:* weighted toward weakest / unseen (mastered concepts floored low for
    light spaced repetition).
  - *Difficulty:* starts Easy; steps up on recent success, down on struggling.
- Endpoints: `POST /quiz/next-adaptive` (server picks concept+difficulty from the
  authenticated user's history), `POST /quiz/review-next` (spaced-repetition:
  weakest attempted-but-not-mastered concept). Fully wired into the Flutter app
  (concept-scoped "Start Practice" + lesson "Smart Practice" + home "Review").

---

## 9. The fine-tuned T5 (research contribution — honest state)

**Files:** `ml/t5/{prepare_dataset,train,eval}.py`, `model/`, `eval_report.json`;
served by `backend/app/services/t5_service.py`.

- **Model:** FLAN-T5 fine-tuned as a **standalone SHS math tutor** — input is
  `question → answer` (no retrieved context; RAG grounds the *other* cascade tiers).
- **Dataset (current):** **184 examples across all 4 subjects** (`ml/retrieval/
  topic_qa_pairs.json` + hand-authored pairs), split **140 train / 22 val / 22 test**,
  stratified by topic. Built in "tutor" mode (`DATASET_MODE=tutor`, the default).
  A corpus-grounded RAG build is preserved under `DATASET_MODE=rag`.
- **Training:** early stopping on val loss, best checkpoint kept (fp32 — flan-t5 is
  NaN-prone in fp16). Runs on Colab T4 GPU (`train_flan_t5.ipynb`); CPU works for
  flan-t5-small.
- **Serving:** `t5_service` feeds the tutor prompt + **decoding guards**
  (`no_repeat_ngram_size=3`, `repetition_penalty=1.4`) so it can't degenerate.
- **Evaluation (flan-t5-base, 22-example test set):** ROUGE-L **0.330**,
  BLEU **9.86**, BERTScore-F1 **0.855** (distilbert scorer). See `eval_report.json`.

**HONEST FINDING (put this in the thesis):** the fine-tune **eliminated the earlier
repetition degeneracy** and produces **fluent, worked-solution-formatted answers**,
but **184 in-domain examples cannot instill reliable symbolic computation** — answers
are coherent but often numerically wrong. This is a defensible, informative result
that *validates the architecture*: exact math is delegated to **SymPy**, tutoring to
the **generalist cascade**, and T5 is the *experimental in-domain tier*. In
production `DISABLE_T5=true`, so T5's inaccuracy never reaches users. **Do not sell
T5 as "the model that makes the app smart" — sell it as an honest experiment with a
clear conclusion.** The genuinely strong pieces are the SymPy solver, the RAG
grounding, and the working app.

---

## 10. Authentication & database

**Auth:** JWT (HS256), passwords bcrypt-hashed. `POST /auth/register`, `/auth/login`,
`GET /auth/me`. Flutter attaches the JWT via an `AuthInterceptor`.

**Schema** (`backend/app/database/models.py`; Alembic-managed on Postgres):
- **users** — id, email (unique), password_hash, full_name, section,
  enrollment_status, timestamps.
- **quiz_questions** — server-generated questions with `correct_answer`, `choices`
  (JSON), `steps` (JSON), template_id, concept/difficulty, `answered`.
- **quiz_attempts** — every graded attempt (user_id, concept_id, difficulty,
  is_correct, elapsed_seconds, question_id, created_at) — the source data for
  progress stats *and* adaptive selection.

On SQLite (dev) tables are auto-created; on Postgres (prod) **Alembic migrations are
the single source of truth** (`alembic upgrade head` runs on container start).

---

## 11. API reference

| Method | Path | Purpose |
|---|---|---|
| POST | `/auth/register` | Create account |
| POST | `/auth/login` | Get JWT |
| GET | `/auth/me` | Current user profile |
| POST | `/api/ask` | Tutor answer (RAG + cascade) |
| POST | `/api/ask/stream` | Streaming tutor answer |
| POST | `/api/solve-image` | OCR a photo + solve (Gemini→pix2tex→SymPy) |
| POST | `/solve` | Solve typed input (SymPy) |
| POST | `/api/quiz/submit` | Submit a generated quiz set |
| GET | `/api/quiz/next` | Next question (client-specified) |
| POST | `/api/quiz/next-adaptive` | Server picks concept+difficulty from history |
| POST | `/api/quiz/review-next` | Spaced-repetition review question |
| POST | `/api/quiz/answer` | Grade one answer (server owns correctness) |
| GET | `/api/user/progress` | Aggregated stats + achievements |
| GET | `/health` | Liveness probe |

Rate-limited (per client IP, slowapi): register 5/min, login 10/min, ask + solve-image 20/min.

---

## 12. Configuration (environment variables)

Typed in `config.py`; `validate_runtime()` refuses to boot production with a weak
JWT secret or a SQLite DB.

| Env var | Default | Meaning |
|---|---|---|
| `ENVIRONMENT` | development | `production` flips the strict startup guard |
| `DATABASE_URL` | sqlite:///./mathiva.db | Postgres (Supabase) URL in prod |
| `JWT_SECRET` | dev default | Must be ≥32 bytes in prod |
| `GEMINI_API_KEY` | — | Free Gemini key (tutor fallback + OCR) |
| `GEMINI_MODEL` | gemini-flash-latest | Tracks Google's current free flash model |
| `DISABLE_T5` | false | `true` in the hosted (no-Ollama) deploy |
| `RATE_LIMIT_ENABLED` | true | Per-IP throttling (tests set false) |
| `CORS_ORIGINS` | `*` | Lock to app origin(s) for a web deploy |
| `ANSWER_CACHE_ENABLED` | true | `/ask` answer cache (tests set false) |

---

## 13. Deployment

- **Dockerfile** (`python:3.12-slim`): installs **CPU-only torch+torchvision** from
  the PyTorch index (default wheels bundle ~2 GB CUDA), then pinned requirements,
  bakes the SBERT model, and — by design — **excludes `ml/t5`** (T5 disabled in the
  hosted deploy; Gemini is the tutor). Image ≈ **2.97 GB**. CMD runs
  `alembic upgrade head` then `uvicorn … --port $PORT`.
- **CI/CD** (`.github/workflows/ci.yml`): `backend-tests` (pytest on **Python 3.12**,
  deployment parity), `flutter-analyze` (errors only), `docker` (builds every run,
  publishes to **GHCR** on `main`).
- **Resilience:** rate limiting, `/ask` caching, graceful Gemini-limit handling,
  compose healthcheck.
- **Runtime notes:** needs **≥1 GB RAM** (torch+SBERT load — 512 MB free tiers OOM);
  behind a proxy, run uvicorn with `--proxy-headers` for correct rate-limit keying;
  TLS is provided by the host (Render/Railway).
- **Frontend:** built separately; backend URL via
  `flutter build … --dart-define=API_BASE_URL=https://<backend>`. Distribute as an
  APK, or a hosted **web build** (a link, no install — but the camera scanner is
  mobile-only).

---

## 14. Testing

170 pytest tests (`backend/tests/`), all passing — auth, solver (equations,
arithmetic, inequalities, systems, garbled-scan rejection), OCR routing, quiz,
answer cascade + resilience (rate limit, cache), adaptive personalization, config.
Test-to-code ratio ~50%. **The Flutter app has no automated tests** (one placeholder).

---

## 15. Design decisions worth defending (good methodology writing)

- **Computed answers, not generated** — SymPy for solving and Python for quiz
  grading. Trustworthiness over fluency.
- **Cheap-first, cloud-on-failure** — local models/OCR first, Gemini only on
  escalation, to conserve the free API quota and keep parts working offline.
- **Objective structural guards** (`is_bad_answer`, garbled-scan detection)
  instead of tuned confidence thresholds — simple and defensible.
- **Server-side personalization** from the authenticated student's real history —
  the "personalized" claim is backed by actual adaptive selection.
- **Graceful degradation** — a missing model/key/GPU disables a tier rather than
  breaking the app; a rate limit becomes a "try again" message.

---

## 16. Honest limitations / current state (for Scope & Future Work)

- **Fine-tuned T5** is fluent but not accurate at 184 examples (see §9); disabled
  in production; growing the dataset is the identified path forward.
- **RAG corpus is General-Mathematics only**; other subjects lack a PDF corpus.
- **Quiz content** covers 11 templated concepts.
- **OCR accuracy is unmeasured**; pix2tex is effectively a no-op on real photos
  (Gemini does the real work). Camera/scan is **mobile-only**.
- **Gemini free tier** ≈ 10 solves/min shared across all users (2 calls per solve);
  mitigated by caching + graceful handling; a paid key lifts it.
- **No frontend tests, no public deployment yet**; the DB password exposed in
  development must be rotated before launch.
```
