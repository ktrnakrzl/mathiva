# MATHIVA — AI Handoff / Context Memory

> **Paste this whole file into a new AI session to restore full context on the
> MATHIVA project.** It captures the current state, the decisions already made,
> what's done, and what's next. For the full technical system reference, also
> share `MATHIVA_SYSTEM_TECHNICAL.md`.

---

## What MATHIVA is (one line)

A mobile-first intelligent tutoring system for Philippine Senior High School math
(Grade 11–12 DepEd, 4 subjects): a **step-by-step solver** (typed + photo), a
**RAG-grounded AI tutor**, and **adaptive quiz practice**. It's a thesis project.
Stack: **Flutter** app → **FastAPI** backend → **Supabase Postgres**, with ML
services (SBERT+FAISS RAG, a fine-tuned FLAN-T5, Google Gemini free tier, SymPy,
pix2tex OCR, Phi-3 via Ollama for local dev).

## Who the user is

Building this as their undergraduate thesis. New-ish to testing/deployment.
Prefers: **comments-by-default in code, explain the *why* first, prioritize next
steps.** Values honesty over hype. Working on **Windows** (paths like
`A:\mathiva\...`, PowerShell + Git Bash). **Never add `Co-Authored-By` trailers to
commits in this repo.**

## Environment facts (important)

- Repo root: `A:\mathiva`. Python venv at `A:\mathiva\.venv` (**Python 3.14** local;
  the **Docker image runs Python 3.12** — that's the deployment target).
- Git branch: **`theme-v2`**. GitHub remote `ktrnakrzl/mathiva` is **PRIVATE**.
- There are typically **several local commits not yet pushed** — confirm with
  `git log origin/theme-v2..theme-v2` and push to back up + run CI.
- **170 backend pytest tests pass.** Run from `backend/`:
  `A:/mathiva/.venv/Scripts/python.exe -m pytest`.
- Gemini free tier gets exhausted by heavy testing (per-minute ~10–15, plus a
  daily cap); it resets. Don't mistake a 429 for a bug.

## Policy / constraints the user set

- **No PAID cloud APIs in the product** (Mathpix was rejected). FREE ones OK —
  **Gemini free tier is the production tutor + OCR**. (The user has ~$95 in
  Anthropic/Claude credits, usable for *offline* data-gen or an optional fallback,
  but that's their call — paid-in-product crosses the policy line.)
- Answers must be **computed** (SymPy), not LLM-guessed, wherever possible.

---

## Current state — what's built and working

- **Full backend** (auth/JWT, `/ask` tutor cascade, `/solve` + `/solve-image`,
  quiz + adaptive personalization, progress). 170 tests green.
- **Solver** handles equations, arithmetic, exact fractions, **inequalities**, and
  **systems of equations**, with garbled-OCR fail-safes.
- **OCR is Gemini-first** (pix2tex only as offline fallback — it garbles photos).
- **RAG** = SBERT + FAISS over ~1,108 General-Math chunks; grounds `/ask` only.
- **Fine-tuned FLAN-T5** retrained as a **standalone tutor** on **184 examples
  across 4 subjects** (was 62, General-Math-only). Eval on a real 22-example test
  set: ROUGE-L 0.330 / BLEU 9.86 / BERTScore-F1 0.855. **Honest finding: fluent but
  not numerically accurate at this data scale — degeneracy fixed via decoding
  guards. Disabled in production (Gemini is the tutor).** See `eval_report.json`.
- **Deployment-ready backend:** Docker image builds/boots (CPU-only, ~2.97 GB),
  CI/CD green (`.github/workflows/ci.yml`, publishes to GHCR on `main`), rate
  limiting, configurable CORS, `/ask` answer caching, graceful Gemini-rate-limit
  handling (503 "busy, try again" + Retry-After), compose healthcheck.
- **Adaptive quiz** fully wired into the Flutter app; **recent-scan activity** on
  the home screen is now real (persisted on-device), not hardcoded.

## What this session accomplished (recent commit arc on `theme-v2`)

1. Per-IP rate limiting + pinned backend deps.
2. Fixed the OCR solve path (explanation fell back to Gemini; degradation).
3. Arithmetic + inequalities + systems added to the solver.
4. Gemini-first OCR (pix2tex demoted to offline fallback).
5. Real recent-scan activity (replaced hardcoded samples).
6. CI/CD (GitHub Actions) + fixed the Docker CUDA-torch bloat bug.
7. **Rebuilt the T5 dataset (62→184, 4 subjects) + retrained flan-t5-base +
   decoding guards + `t5_service` aligned to the tutor prompt + eval_report.**
8. Configurable CORS, `/ask` caching, graceful Gemini limits, compose healthcheck.
9. Updated thesis/technical docs.

## The T5 dataset workflow (how more data gets added)

Data lives in `ml/retrieval/topic_qa_pairs.json` (list of `{topic, question,
answer}`), generated **per subject** by prompting an AI (see the prompt in the chat
history / `generate_qa.py` can also generate via Gemini/Claude/Ollama backends).
Then `python ml/t5/prepare_dataset.py` rebuilds `ml/t5/data/{train,val,test}.jsonl`
(tutor mode, stratified by topic, auto-includes the hand-authored pairs), and
`ml/t5/train.py` (or `train_flan_t5.ipynb` on Colab GPU) retrains. More data is the
#1 lever to make T5 actually accurate.

---

## What's pending / next steps (in priority order)

1. **Push `theme-v2`** to back up the local commits + run CI.
2. **Deployment** (backend is ready; remaining steps are the user's):
   - **Rotate the Supabase DB password** (it was exposed in dev chat — real blocker).
   - Pick a host with **≥1 GB RAM** (Render/Railway; free 512 MB tiers OOM on the
     torch+SBERT load). Set secrets: `GEMINI_API_KEY`, strong `JWT_SECRET`,
     `DATABASE_URL`, `DISABLE_T5=true`. Host provides HTTPS.
   - Add `--proxy-headers` to the uvicorn CMD so rate limiting keys correctly
     behind the host's proxy.
   - Distribute the app: **web build** (a link, instant, no install — but no camera
     scanner) and/or **APK** (full app, sideload).
3. **Optional T5 improvement:** grow the dataset further (more per-subject pairs) →
   retrain flan-t5-base on Colab → re-run `eval.py`.
4. **Optional hardening:** frontend tests, structured logging, a paid Gemini key or
   a second provider fallback for classroom-scale load.

## Gotchas an AI should know

- **Windows shell:** each Bash/PowerShell tool call starts fresh (no persisted cwd
  env). Use absolute paths and the venv python explicitly.
- **T5 model files** (`ml/t5/model/*.safetensors`) are gitignored (large). The
  Dockerfile excludes `ml/t5` entirely.
- **Don't oversell the T5** — it's fluent but often wrong; frame it as an honest
  in-domain experiment that validates delegating exact math to SymPy.
- **The strong parts of the thesis** are the SymPy solver, RAG grounding, adaptive
  personalization, and the working end-to-end app — not the T5.
- Two parallel Flutter architectures once existed; the **dead one was purged**.
  Live path is `frontend/lib/screens/` + `services/` + `repositories/api/` (real
  JWT). Curriculum content is local in `lib/data/local_mathiva_data.dart` (the
  backend has no content endpoints — a deliberate decision).

## Key files to read first

- `MATHIVA_SYSTEM_TECHNICAL.md` — full technical reference.
- `MATHIVA_THESIS_CONTEXT.md` — Chapters 1–3 framing + honest caveats.
- `backend/app/services/answer_service.py` — the `/ask` cascade.
- `backend/app/services/solver_service.py` + `ml/solver/math_solver.py` — solving.
- `ml/t5/prepare_dataset.py` + `eval_report.json` — the fine-tune.
- `DEPLOY.md` — deployment steps + the security checklist.
```
