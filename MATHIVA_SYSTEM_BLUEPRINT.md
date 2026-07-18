# MATHIVA: System Blueprint & Architecture Documentation

> ⚠️ **This document describes the target architecture**, including components not yet built. See [Implementation Status](#implementation-status-as-of-2026-06-25) immediately below for what's actually running today vs. what's still planned.

## Executive Summary

This document provides detailed architectural blueprints, component interaction diagrams, deployment topology, and technical design rationale for MATHIVA. It complements the System Specification with visual representations and implementation-level detail.

---

## Implementation Status (as of 2026-06-25)

Everything in Sections 1–11 below describes the **full target design**. The table below is the source of truth for what's actually built right now vs. what's still planned — refer back to this section whenever a diagram or table elsewhere in this document implies something that isn't live yet.

### ✅ Built and working

| Component | Reality |
|---|---|
| FastAPI backend (`backend/app/main.py`) | Running, CORS configured, routers registered |
| `POST /api/ask` (RAG) | Real pipeline: SBERT (`all-MiniLM-L6-v2`) → FAISS top-k search → prompt assembly → generation |
| Text generation | **Answer cascade (as of 2026-07-19)** in `answer_service.py`: RAG context → **Phi-3 (primary) + fine-tuned T5 (backup)** both run as a combination → **Gemini free-tier** escalation only when the local answer is weak (empty/degenerate). Response carries `model_used`. Wired into `POST /api/ask`. (Phi-3 is preferred for now because Phase-3 eval showed T5 is the weaker generator at the current dataset size.) |
| `POST /solve` | SymPy-based solver, live |
| OCR endpoint (`api/ocr.py`) | Live (image → text for the solver flow) |
| Auth (`POST /auth/register`, `POST /auth/login`) | Real: bcrypt password hashing, JWT (HS256, 24h expiry). `get_current_user` dependency exists but **no other route requires login yet** |
| Database | SQLAlchemy ORM, but only the **`users`** table exists. Defaults to local SQLite (`DATABASE_URL` env var swaps to Postgres — not yet pointed at Supabase) |
| `POST /quiz` | Generation-only — randomly samples from `genmath_qa_pairs.json` (currently 74 raw Q&A pairs; 62 after quality-judging). No grading. |
| Frontend (Flutter) | Two screen trees: the active `lib/screens/*` (current, theme-aware) and a legacy `lib/presentation/screens/**` tree (still live-routed at `/quiz`, `/review`, `/mastery`, `/rewards`, `/tutor`) |
| Frontend Repository Pattern | Real, but only on the frontend (`lib/repositories/` — abstract + API/mock implementations) |
| Frontend state management | Riverpod is only used in the **legacy** screen tree (7 files); the active app flow uses plain `StatefulWidget` + `ValueNotifier` |

### 📋 Planned, not yet built

| Component | Status |
|---|---|
| T5 fine-tuned model | 🔄 **In progress** — full dataset pipeline built and `train.py` verified end-to-end; not yet trained-to-convergence or integrated into `/ask`. See [🔄 In progress: T5 fine-tuning pipeline](#-in-progress-t5-fine-tuning-pipeline-as-of-2026-07-18) below |
| ~~Phi-3 Mini fallback~~ | ✅ Built — Phi-3 is the primary local generator in the answer cascade (`answer_service.py`) |
| Cloud API fallback | ✅ Built as **Gemini free tier** (not Claude — respects the no-paid-API rule; reuses the OCR key). Bounded escalation, fires only when the local answer is weak |
| Fallback / Circuit Breaker pattern (§11.1.4) | ✅ Built — the answer cascade escalates on a cheap "is the output empty/degenerate?" guard |
| Adapter Pattern across models (§11.1.6) | Not implemented — no unified model interface exists yet |
| `POST /quiz/submit`, scoring, points/rewards persistence | Not implemented |
| DB tables: `sessions`, `quiz_attempts`, `quiz_responses`, `knowledge_base_metadata`, `faiss_indices` | Not implemented (only `users` exists) |
| Supabase Postgres + pgvector | Not connected — running on local SQLite |
| `GET /user/profile`, `GET /user/progress` | Not implemented |
| AWS EC2 deployment, Nginx, systemd, CI/CD (§4) | Not set up — runs locally only |
| Backend Repository Pattern (§11.1.3) | Not implemented — `api/auth.py` talks directly to a SQLAlchemy `Session` |
| MVC/Riverpod pattern (§11.1.2) | Only true for the legacy screen tree, not the active app |
| Monitoring/CloudWatch, rate limiting, `sessions` table (§7, §8) | Not implemented |
| Appendix A file structure | Describes the **target** repo layout, not the current one — actual backend lives at `backend/app/` with a flatter structure than shown |

**Runway:** thesis deadline is ~mid-August 2026 (6 weeks out as of this writing), so the planned items above are realistic to build before defense, not just aspirational — this section should be revisited and updated as each one lands.

---

### 🔄 In progress: T5 fine-tuning pipeline (as of 2026-07-18)

The fine-tuned transformer is a **required** thesis contribution — the abstract claims *"RAG with fine-tuned transformer models,"* so a trained model must exist. The full data + training pipeline is now built and the training script is verified end-to-end; what remains is a converged training run, evaluation, and integration into `/ask`. All model building uses **local, free tooling only** (Ollama + Hugging Face on a free Colab T4) — no paid APIs.

**Inference design — answer cascade (built 2026-07-19, `backend/app/services/answer_service.py`).** At `/ask`: RAG retrieves context → the **local layer (Phi-3 + fine-tuned T5) both generate** as a combination (neither waits for the other to fail) → the better local answer is chosen → **Gemini (free tier) escalation** only when that local answer is still "not great". "Not great" is a cheap, objective guard (`is_bad_answer`: empty or degenerate/repetition output), not a tuned confidence score — deliberately simple. Phi-3 is preferred over T5 for now because Phase-3 eval showed T5 is the weaker generator at 62 training pairs; the preference flips back to T5 once a larger dataset makes it competitive. The response carries `model_used` (`t5` / `phi3` / `gemini`) so the tier is visible. Note: `POST /api/ask/stream` still streams Phi-3 only, since token-streaming can't wait for the full answer the guard needs.

**Dataset engineering.** Two datasets feed a two-stage fine-tune:

1. **Curriculum QA set (domain + format aligned).** Built from the DepEd *General Mathematics* textbook:
   - `chunk_pdf.py` → **1,108** text chunks → SBERT (`all-MiniLM-L6-v2`) embeddings → FAISS index (`build_faiss.py`). Corpus is **General-Math-only** (other SHS subjects blocked by LRMDS access).
   - `generate_qa.py` — local **llama3** (Ollama) turns each cleaned chunk into 2–3 *self-contained* Q&A pairs. `text_clean.py` strips front-matter/boilerplate; regex validation rejects non-self-contained questions (e.g. "what is x?" with no equation) and ungrounded answers; questions are globally de-duplicated.
   - `judge_qa.py` — a second **llama3** pass (LLM-as-judge) scores every pair against its source chunk on three axes: *self-contained*, *grounded*, *correct*; only pairs passing all three are kept. Result so far: **74 raw → 62 kept (84%), 12 rejected.** This is the quality backstop before training.
   - `authored_qa_pairs.json` — **51** hand-authored, curriculum-aligned pairs covering strands the PDF extraction under-covers (logic, stocks/bonds, exponential/logarithmic). Kept separate pending source-chunk mapping.
   - `prepare_dataset.py` — assembles the training set so each example matches the **live inference distribution**: `input = instruction + top-3 retrieved context + question`, `target = answer`. Split is **grouped by source chunk** so no chunk's context leaks across train/val/test. Current build (from the judged pairs): **62 examples → train 50 / val 7 / test 5**. A measured retrieval-quality signal: the gold source chunk is retrieved in the top-3 only **48%** of the time (ties to the RAG corpus-quality gap; when it misses, the gold chunk is prepended so the target is always supported).

2. **Generic warm-up set (general math ability).** `ml/t5/deepmind/` — the **DeepMind Mathematics** dataset, **100,000** Q&A pairs streamed from Hugging Face across 5 modules (linear algebra, arithmetic, GCD), exported as CSV + JSONL (`input`/`target`), split **96k / 2k / 2k**. This is generic symbolic math (no curriculum, no context) — a Stage-A pre-fine-tune warm-up, **not** a substitute for the curriculum set.

**Training (`train.py`, verified end-to-end).** `flan-t5-base` in **fp32** (flan-t5 is NaN-unstable in fp16), 512-token input / 256-token target, `Seq2SeqTrainer` with early stopping on validation loss. **Two-stage plan:** Stage A on the 100k generic set → Stage B continues the same weights on the curriculum set. Real runs use a **free Colab T4** (`train_flan_t5.ipynb`, `train_flan_t5_deepmind.ipynb`); `flan-t5-small` trains locally on CPU as an offline fallback. A 1-epoch `flan-t5-small` smoke test has run clean end-to-end (tokenize → train → eval → save).

**Evaluation (`eval.py`, pending a trained model).** ROUGE-L / BLEU on the held-out test split, plus a **head-to-head of T5 vs Phi-3 on identical retrieved context** — this comparison is the core empirical contribution and the check on whether the simple output-sanity guards suffice.

**Open constraints.** The curriculum set is small (**~62**); the lever to grow it is finishing the textbook QA-generation pass (only **40 / 1,108** chunks processed so far). Corpus breadth is limited to General Mathematics.

---

## 1. System Architecture Layers

### 1.1 Layered Architecture Diagram

```
┌──────────────────────────────────────────────────────────────────────────┐
│                         PRESENTATION LAYER                                │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │                    Flutter Mobile Application                       │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌────────────┐  ┌──────────┐ │  │
│  │  │ Chat Screen  │  │ Solver Screen│  │Quiz Screen │  │Dashboard │ │  │
│  │  │  (/ask)      │  │  (/solve)    │  │ (/quiz)    │  │ (metrics)│ │  │
│  │  └──────────────┘  └──────────────┘  └────────────┘  └──────────┘ │  │
│  │  ┌────────────────────────────────────────────────────────────────┐ │  │
│  │  │  UI Components: KaTeX Renderer, Math Input (ML Kit v2/Pix2tex) │ │  │
│  │  │  State Management: Riverpod                                    │ │  │
│  │  └────────────────────────────────────────────────────────────────┘ │  │
│  └────────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────────┘
                               ↓ (HTTP REST)
┌──────────────────────────────────────────────────────────────────────────┐
│                      APPLICATION GATEWAY LAYER                            │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │                        FastAPI Server                              │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌────────┐ │  │
│  │  │  Middleware  │  │Request Router│  │ Rate Limiter │  │Logging │ │  │
│  │  │(CORS, Auth)  │  │  & Validator │  │   & CORS     │  │Monitor │ │  │
│  │  └──────────────┘  └──────────────┘  └──────────────┘  └────────┘ │  │
│  │  ┌────────────────────────────────────────────────────────────────┐ │  │
│  │  │  JWT Authentication & Session Management                       │ │  │
│  │  │  - Token generation/validation                                 │ │  │
│  │  │  - User context extraction                                     │ │  │
│  │  │  - Session caching                                             │ │  │
│  │  └────────────────────────────────────────────────────────────────┘ │  │
│  └────────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────────┘
                               ↓
┌──────────────────────────────────────────────────────────────────────────┐
│                      BUSINESS LOGIC LAYER                                 │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │                        RAG Pipeline Module                         │  │
│  │  ┌────────────────┐  ┌────────────────┐  ┌─────────────────────┐ │  │
│  │  │ Query Handler  │→ │ SBERT Embedder │→ │FAISS Vector Search │ │  │
│  │  └────────────────┘  └────────────────┘  └─────────────────────┘ │  │
│  │        ↓                                            ↓              │  │
│  │  ┌────────────────────────────────────────────────────────────┐  │  │
│  │  │ Context Assembly → Response Generator (T5 Fine-tuned)     │  │  │
│  │  │ ↓ Fallback: Phi-3 Mini → Claude API (optional)            │  │  │
│  │  │ ↓ Post-Processing: Citation Tracking, Format Validation   │  │  │
│  │  └────────────────────────────────────────────────────────────┘  │  │
│  └────────────────────────────────────────────────────────────────────┘  │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │                    Math Solver Module                             │  │
│  │  ┌─────────────────────────────────────────────────────────────┐ │  │
│  │  │ Problem Parser → SymPy/SciPy/NumPy → Step Generator       │ │  │
│  │  │ Operations:                                                 │ │  │
│  │  │  • Equation solving (linear, quadratic, polynomial)        │ │  │
│  │  │  • Derivative & integral computation                       │ │  │
│  │  │  • Expression simplification & factorization              │ │  │
│  │  │  • LaTeX formatting                                        │ │  │
│  │  └─────────────────────────────────────────────────────────────┘ │  │
│  └────────────────────────────────────────────────────────────────────┘  │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │                    Quiz Engine Module                             │  │
│  │  ┌──────────────────┐  ┌──────────────────┐  ┌───────────────┐   │  │
│  │  │Q&A Data Manager  │→ │ Quiz Generator   │→ │ Answer Checker│   │  │
│  │  │(genmath_qa.json) │  │(Difficulty Level)│  │ & Scorer      │   │  │
│  │  └──────────────────┘  └──────────────────┘  └───────────────┘   │  │
│  │        ↓                                            ↓              │  │
│  │  ┌────────────────────────────────────────────────────────────┐  │  │
│  │  │ Wrong Answer Detection → Item Analysis → Reward Calculator│  │  │
│  │  └────────────────────────────────────────────────────────────┘  │  │
│  └────────────────────────────────────────────────────────────────────┘  │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │                   User Service Module                             │  │
│  │  ┌──────────────────┐  ┌──────────────────┐  ┌────────────────┐  │  │
│  │  │Auth Manager      │→ │Profile Manager   │→ │Progress Tracker│  │  │
│  │  │(Registration,    │  │(User Data CRUD)  │  │(Analytics)     │  │  │
│  │  │Login, Bcrypt)    │  │                  │  │                │  │  │
│  │  └──────────────────┘  └──────────────────┘  └────────────────┘  │  │
│  └────────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────────┘
                               ↓
┌──────────────────────────────────────────────────────────────────────────┐
│                    DATA ACCESS & PERSISTENCE LAYER                        │
│  ┌─────────────────────────────────────────────────────────────────────┐ │
│  │            PostgreSQL (Supabase Managed Database)                   │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌─────────────────────────┐  │ │
│  │  │ User Table   │  │ Quiz Attempts│  │ Knowledge Base Metadata │  │ │
│  │  │  - Accounts  │  │  - Responses │  │   - PDF Inventory      │  │ │
│  │  │  - Sessions  │  │  - Scores    │  │   - Index Versions     │  │ │
│  │  │  - Profiles  │  │  - Analytics │  │   - Chunk Counts       │  │ │
│  │  └──────────────┘  └──────────────┘  └─────────────────────────┘  │ │
│  │  ┌────────────────────────────────────────────────────────────────┐ │ │
│  │  │             pgvector Extension                                 │ │ │
│  │  │  ┌─────────────────────────────────────────────────────────┐  │ │ │
│  │  │  │ FAISS Indices Table (Persistent)                       │  │ │ │
│  │  │  │  - Subject (General Math, Pre-Calculus, etc.)          │  │ │ │
│  │  │  │  - Chunk ID & Text                                     │  │ │ │
│  │  │  │  - SBERT Embeddings (384-dim vectors)                  │  │ │ │
│  │  │  │  - PDF Source & Page Number                            │  │ │ │
│  │  │  │  - Vector Index (IVFFlat for fast search)             │  │ │ │
│  │  │  └─────────────────────────────────────────────────────────┘  │ │ │
│  │  └────────────────────────────────────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────────────┘ │
│  ┌─────────────────────────────────────────────────────────────────────┐ │
│  │            FAISS Vector Store (In-Memory with Disk Persistence)     │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────────┐  │ │
│  │  │ Subject Index│  │ Subject Index│  │ Subject Index            │  │ │
│  │  │(General Math)│  │(Pre-Calculus)│  │ (Statistics, Bus. Math..)│  │ │
│  │  │1108 chunks   │  │(In Progress) │  │(In Progress)             │  │ │
│  │  └──────────────┘  └──────────────┘  └──────────────────────────┘  │ │
│  │  ┌────────────────────────────────────────────────────────────────┐ │ │
│  │  │ Operations:                                                    │ │ │
│  │  │  • Load indices on FastAPI startup                            │ │ │
│  │  │  • Cosine similarity search across all subject indices        │ │ │
│  │  │  • Persist/reload from PostgreSQL pgvector                   │ │ │
│  │  │  • Versioning & index refresh capability                     │ │ │
│  │  └────────────────────────────────────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────────┘
                               ↓
┌──────────────────────────────────────────────────────────────────────────┐
│                   INFRASTRUCTURE & DEPLOYMENT LAYER                       │
│  ┌─────────────────────────────────────────────────────────────────────┐ │
│  │                        AWS EC2 Instance                              │ │
│  │  (Ubuntu 24, Python 3.11, PyTorch, FastAPI, All Models)             │ │
│  └─────────────────────────────────────────────────────────────────────┘ │
│  ┌─────────────────────────────────────────────────────────────────────┐ │
│  │                    Supabase PostgreSQL Cluster                       │ │
│  │  (Managed, Automated Backups, SSL/TLS)                              │ │
│  └─────────────────────────────────────────────────────────────────────┘ │
│  ┌─────────────────────────────────────────────────────────────────────┐ │
│  │        Student Devices (Android/iOS) ← Flutter Client               │ │
│  └─────────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Component Interaction Diagrams

### 2.1 High-Level Component Relationships

```
┌─────────────────────────────────────────────────────────────────────┐
│                          EXTERNAL ENTITIES                           │
│  ┌──────────────┐                                                    │
│  │ Student User │                                                    │
│  └──────────────┘                                                    │
│        ↓↑ (HTTP/REST)                                               │
└─────────────────────────────────────────────────────────────────────┘
        ↓↑
┌─────────────────────────────────────────────────────────────────────┐
│                      MATHIVA SYSTEM BOUNDARY                         │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │                    Flutter Mobile App                          │ │
│  │  (Android Primary, iOS Secondary)                             │ │
│  └────────────────────────────────────────────────────────────────┘ │
│        ↓↑ (JSON/REST API Calls)                                    │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │                    FastAPI Backend Server                      │ │
│  │  Core Components:                                             │ │
│  │   ├─ Request Router & Validator                              │ │
│  │   ├─ JWT Auth Manager                                        │ │
│  │   ├─ Endpoint Handlers (/ask, /solve, /quiz, /auth, /user)  │ │
│  │   └─ Error Handler & Logger                                  │ │
│  └────────────────────────────────────────────────────────────────┘ │
│        ↓↑ (Internal Calls + Async Tasks)                            │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │              Business Logic Processors                         │ │
│  │  ├─ RAG Pipeline Orchestrator                                │ │
│  │  ├─ Math Solver Engine                                       │ │
│  │  ├─ Quiz Generator & Evaluator                              │ │
│  │  └─ User Service Manager                                     │ │
│  └────────────────────────────────────────────────────────────────┘ │
│        ↓↑ (CRUD Operations)                                         │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │            Data Layer (PostgreSQL + FAISS)                    │ │
│  │  ├─ PostgreSQL (User Data, Quiz History, Sessions)           │ │
│  │  ├─ pgvector (Persistent FAISS Index Metadata)               │ │
│  │  └─ FAISS In-Memory (Vector Search for RAG)                  │ │
│  └────────────────────────────────────────────────────────────────┘ │
│        ↓↑ (Internal ML Inference)                                   │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │              ML Model Layer (On EC2)                           │ │
│  │  ├─ SBERT (Embeddings)                                        │ │
│  │  ├─ T5 Fine-tuned (Primary Text Generation)                  │ │
│  │  ├─ Phi-3 Mini (Fallback)                                    │ │
│  │  ├─ SymPy (Math Solver)                                      │ │
│  │  └─ Claude API (Post-Defense Fallback)                       │ │
│  └────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

### 2.2 Detailed Component Interaction Matrix

| Component A | Component B | Interaction | Protocol | Frequency |
|---|---|---|---|---|
| Flutter App | FastAPI | API Calls | HTTP/REST JSON | Per user action |
| FastAPI | JWT Auth | Token validation | In-process | Every request |
| FastAPI | RAG Pipeline | Query processing | In-process function call | /ask endpoint |
| RAG Pipeline | SBERT | Embedding generation | In-process PyTorch | Per query |
| SBERT | FAISS | Vector search | In-memory indexed lookup | Per query |
| FAISS | PostgreSQL | Index persistence | Query on startup | App boot, periodic refresh |
| FastAPI | Math Solver | Problem solving | In-process SymPy | /solve endpoint |
| FastAPI | Quiz Engine | Q&A selection | In-process JSON load | /quiz endpoint |
| Quiz Engine | PostgreSQL | Score storage | SQL INSERT | Quiz submission |
| T5 Model | FastAPI | Text generation | In-process PyTorch | /ask endpoint |
| Phi-3 Mini | FastAPI | Fallback generation | In-process PyTorch | If T5 fails |
| Claude API | FastAPI | Last-resort generation | HTTP REST (future) | If Phi-3 fails |
| FastAPI | PostgreSQL | User CRUD | SQL queries | Auth, profile update |
| Flutter | KaTeX | Math rendering | Local JavaScript | Chat/solver display |

---

## 3. Data Flow Architecture

### 3.1 Complete End-to-End Flow: Student Asks a Math Question

```
┌─────────────────────────────────────────────────────────────────────┐
│ STUDENT INTERACTION                                                  │
│ "What is the derivative of 3x² + 5x + 2?"                          │
└─────────────────────────────────────────────────────────────────────┘
                                 ↓
        ╔════════════════════════════════════════╗
        ║ FLUTTER MOBILE APP (Client Side)       ║
        ║                                        ║
        ║ 1. User types question in Chat screen ║
        ║ 2. Validate input (non-empty)         ║
        ║ 3. Display "Thinking..." placeholder  ║
        ║ 4. Build JSON request:                ║
        ║    {                                   ║
        ║      "question": "What is the...",    ║
        ║      "subject": "general_math"        ║
        ║    }                                   ║
        ╚════════════════════════════════════════╝
                                 ↓
        ╔════════════════════════════════════════╗
        ║ HTTP POST /ask Request                 ║
        ║ + Authorization Header (JWT Token)    ║
        ║ + Content-Type: application/json      ║
        ╚════════════════════════════════════════╝
                                 ↓
        ╔════════════════════════════════════════╗
        ║ FASTAPI BACKEND (Server Side)          ║
        ║                                        ║
        ║ 1. Receive request                    ║
        ║ 2. CORS validation ✓                  ║
        ║ 3. Extract JWT token from header      ║
        ║ 4. Validate token (signature, exp.)   ║
        ║ 5. Decode to get user_id              ║
        ║ 6. Load user context from PostgreSQL  ║
        ║ 7. Rate limit check (user quota)      ║
        ║ 8. Log request                        ║
        ║ 9. Call RAG pipeline handler          ║
        ╚════════════════════════════════════════╝
                                 ↓
        ╔════════════════════════════════════════╗
        ║ RAG PIPELINE HANDLER                   ║
        ║                                        ║
        ║ 1. Receive: question, subject         ║
        ║ 2. Preprocess:                        ║
        ║    - Lowercase                        ║
        ║    - Remove special chars             ║
        ║    - Spelling check (optional)        ║
        ║ 3. Generate embedding:                ║
        ║    SBERT.encode(preprocessed_q)      ║
        ║    → 384-dim vector                   ║
        ║ 4. Call FAISS search:                 ║
        ║    faiss_index.search(vector, k=3)   ║
        ║    → [(chunk_id, similarity_score)...]║
        ║ 5. Retrieve chunks from FAISS         ║
        ║ 6. Assemble context:                  ║
        ║    context = combine(top_3_chunks)   ║
        ║ 7. Track sources:                     ║
        ║    sources = [                        ║
        ║      {chunk_id, pdf, page, sim_score}║
        ║    ]                                  ║
        ║ 8. Prepare prompt:                    ║
        ║    prompt = f"""                      ║
        ║    Context: {context}                 ║
        ║    Question: {question}               ║
        ║    Answer: """                        ║
        ║ 9. Call T5 generator                  ║
        ╚════════════════════════════════════════╝
                                 ↓
        ╔════════════════════════════════════════╗
        ║ T5 FINE-TUNED MODEL                    ║
        ║ (PRIMARY GENERATION)                   ║
        ║                                        ║
        ║ 1. Tokenize prompt                    ║
        ║ 2. Load model weights from disk       ║
        ║ 3. Forward pass (attention layers)    ║
        ║ 4. Generate tokens (beam search)      ║
        ║ 5. Decode to text:                    ║
        ║    "The derivative is 6x + 5"         ║
        ║ 6. Return (text, confidence)          ║
        ║                                        ║
        ║ IF TIMEOUT or ERROR:                  ║
        ║  → Fallback to Phi-3 Mini             ║
        ╚════════════════════════════════════════╝
                                 ↓
        ╔════════════════════════════════════════╗
        ║ RESPONSE POST-PROCESSING               ║
        ║                                        ║
        ║ 1. Receive answer from T5             ║
        ║ 2. Validate output (non-empty, safe)  ║
        ║ 3. Format response JSON:              ║
        ║    {                                   ║
        ║      "answer": "The derivative...",   ║
        ║      "sources": [{...}],              ║
        ║      "model_used": "t5_finetuned",    ║
        ║      "confidence": 0.92,              ║
        ║      "response_time_ms": 1200         ║
        ║    }                                   ║
        ║ 4. Store in PostgreSQL (log)          ║
        ║ 5. Return to FastAPI handler          ║
        ╚════════════════════════════════════════╝
                                 ↓
        ╔════════════════════════════════════════╗
        ║ HTTP RESPONSE (200 OK)                 ║
        ║ Content-Type: application/json        ║
        ║ Body: {...response JSON...}           ║
        ╚════════════════════════════════════════╝
                                 ↓
        ╔════════════════════════════════════════╗
        ║ FLUTTER APP (Client Side)              ║
        ║                                        ║
        ║ 1. Receive response                   ║
        ║ 2. Parse JSON                         ║
        ║ 3. Extract answer, sources            ║
        ║ 4. Update Riverpod chat state         ║
        ║ 5. Render answer with KaTeX           ║
        ║ 6. Display sources as citations       ║
        ║ 7. Show response time                 ║
        ║ 8. Remove "Thinking..." placeholder   ║
        ╚════════════════════════════════════════╝
                                 ↓
┌─────────────────────────────────────────────────────────────────────┐
│ STUDENT SEES RESPONSE IN CHAT                                        │
│ "The derivative is 6x + 5"                                          │
│ [Source: General_Math.pdf, Page 42]                                 │
└─────────────────────────────────────────────────────────────────────┘
```

### 3.2 Quiz Submission Data Flow

```
┌───────────────────────────────────────────────┐
│ STUDENT COMPLETES QUIZ & SUBMITS             │
│ - Selected answers for 10 questions          │
│ - Total time spent: ~15 minutes              │
└───────────────────────────────────────────────┘
                      ↓
┌───────────────────────────────────────────────┐
│ FLUTTER APP                                   │
│ 1. Gather all answers from state             │
│ 2. Build submission payload:                 │
│    {                                          │
│      "quiz_id": 101,                         │
│      "answers": [                            │
│        {"question_id": 1, "user_ans": "30"} │
│      ]                                        │
│    }                                          │
│ 3. POST to /quiz/submit                      │
└───────────────────────────────────────────────┘
                      ↓
┌───────────────────────────────────────────────┐
│ FASTAPI /QUIZ/SUBMIT ENDPOINT                │
│ 1. Validate JWT + user auth                  │
│ 2. Fetch quiz metadata from DB               │
│ 3. Load correct answers from genmath_qa.json │
│ 4. For each submitted answer:                │
│    - Compare with correct answer             │
│    - Mark is_correct (boolean)               │
│    - Log to quiz_responses table             │
│ 5. Calculate metrics:                        │
│    - correct_count = sum(is_correct)         │
│    - score = (correct / total) * 100         │
│    - points_earned = score_func(score, diff) │
│    - difficulty_multiplier = 1.0 (Basic),   │
│                            1.5 (Intermed.),  │
│                            2.0 (Advanced)    │
└───────────────────────────────────────────────┘
                      ↓
┌───────────────────────────────────────────────┐
│ QUIZ ENGINE                                   │
│ 1. Wrong answer detection:                   │
│    for each incorrect answer:                │
│      - Flag for re-practice                  │
│      - Store in user.wrong_answers set       │
│ 2. Item analysis:                            │
│    - Question-level accuracy                 │
│    - Difficulty analysis                     │
│    - Time per question                       │
│ 3. Generate feedback:                        │
│    - Correct answers                         │
│    - Explanations                            │
│    - Topics to review                        │
└───────────────────────────────────────────────┘
                      ↓
┌───────────────────────────────────────────────┐
│ DATABASE STORAGE                              │
│ 1. Insert into quiz_attempts:                │
│    INSERT INTO quiz_attempts (                │
│      user_id, difficulty_level,              │
│      total_questions, correct_answers,       │
│      score, points_earned, attempted_at      │
│    ) VALUES (...)                            │
│ 2. Insert into quiz_responses (batch):       │
│    INSERT INTO quiz_responses (              │
│      attempt_id, question_id, user_answer,   │
│      correct_answer, is_correct              │
│    ) VALUES (...), (...), ...                │
│ 3. Update users table:                       │
│    UPDATE users                              │
│    SET total_points += points_earned,        │
│        updated_at = NOW()                    │
│    WHERE id = user_id                        │
└───────────────────────────────────────────────┘
                      ↓
┌───────────────────────────────────────────────┐
│ RESPONSE TO FLUTTER                           │
│ {                                             │
│   "quiz_id": 101,                            │
│   "score": 85.0,                             │
│   "correct_answers": 8,                      │
│   "total_questions": 10,                     │
│   "points_earned": 75,                       │
│   "new_total_points": 325,                   │
│   "item_analysis": [                         │
│     {                                         │
│       "question_id": 1,                      │
│       "is_correct": true,                    │
│       "user_answer": "30",                   │
│       "correct_answer": "30"                 │
│     },                                        │
│     {                                         │
│       "question_id": 5,                      │
│       "is_correct": false,                   │
│       "user_answer": "42",                   │
│       "correct_answer": "50",                │
│       "flagged_for_repractice": true         │
│     }                                         │
│   ],                                          │
│   "feedback": "Great job! Review..."         │
│ }                                             │
└───────────────────────────────────────────────┘
                      ↓
┌───────────────────────────────────────────────┐
│ FLUTTER APP DISPLAYS RESULTS                  │
│ - Score card with points earned              │
│ - Item-by-item breakdown                     │
│ - Suggestions for review                     │
│ - Updated dashboard metrics                  │
└───────────────────────────────────────────────┘
```

---

## 4. Deployment Architecture

### 4.1 Current Deployment Topology

```
┌─────────────────────────────────────────────────────────────────┐
│                        INTERNET                                  │
└─────────────────────────────────────────────────────────────────┘
                              ↓↑
        ┌─────────────────────────────────────────┐
        │  STUDENT DEVICES                        │
        │  ┌──────────────────────────────────┐   │
        │  │ Android Phone (Flutter App)      │   │
        │  │ - Runs SQLite local cache        │   │
        │  │ - Displays KaTeX math            │   │
        │  │ - Communicates via HTTPS/REST    │   │
        │  └──────────────────────────────────┘   │
        │  ┌──────────────────────────────────┐   │
        │  │ iOS (iPad/iPhone) - Secondary    │   │
        │  │ - Same Flutter app                   │   │
        │  │ - Same functionality            │   │
        │  └──────────────────────────────────┘   │
        └─────────────────────────────────────────┘
                              ↓↑ (HTTPS)
┌─────────────────────────────────────────────────────────────────┐
│                    AWS EC2 Instance                              │
│  Region: (ap-southeast-1 recommended for PH)                   │
│  Instance Type: t3.medium (2 vCPU, 4GB RAM)                   │
│  OS: Ubuntu 22.04 LTS                                          │
│                                                                │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │ FastAPI Application (Port 8000)                          │  │
│  │                                                         │  │
│  │ Python 3.11.5                                          │  │
│  │ FastAPI 0.104.1                                        │  │
│  │ Uvicorn ASGI Server                                    │  │
│  │ Workers: 4 (via gunicorn)                              │  │
│  │ Timeout: 30s                                           │  │
│  └─────────────────────────────────────────────────────────┘  │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │ ML Model Inference (In-Process)                         │  │
│  │                                                         │  │
│  │ ├─ SBERT (sentence-transformers)                       │  │
│  │ │  - Model: all-MiniLM-L6-v2                           │  │
│  │ │  - Dimension: 384                                    │  │
│  │ │  - Loaded on startup                                │  │
│  │ │  - CPU: ~500MB RAM                                  │  │
│  │ │                                                     │  │
│  │ ├─ T5 Fine-tuned (PyTorch)                            │  │
│  │ │  - Base: google/flan-t5-base                        │  │
│  │ │  - Fine-tuned on math Q&A corpus                    │  │
│  │ │  - Loaded on first /ask call (lazy)               │  │
│  │ │  - GPU preferred, CPU fallback                     │  │
│  │ │  - ~1GB RAM minimum                                │  │
│  │ │                                                     │  │
│  │ ├─ Phi-3 Mini (PyTorch)                              │  │
│  │ │  - Quantized (4-bit or 8-bit)                      │  │
│  │ │  - ~2GB RAM (quantized)                            │  │
│  │ │  - Fallback if T5 times out                        │  │
│  │ │                                                     │  │
│  │ ├─ SymPy Symbolic Math                               │  │
│  │ │  - Lightweight, pure Python                        │  │
│  │ │  - No GPU needed                                   │  │
│  │ │  - Loaded on startup                              │  │
│  │ │                                                     │  │
│  │ └─ FAISS Vector Index (In-Memory)                    │  │
│  │    - Loaded from PostgreSQL on startup              │  │
│  │    - One index per subject                          │  │
│  │    - General Math: 1108 chunks loaded               │  │
│  │    - Others: lazy load per subject                  │  │
│  │    - Total: ~500MB for 4 subjects                   │  │
│  │                                                     │  │
│  │ TOTAL ML MEMORY: ~4.5–6 GB (GPU optional)           │  │
│  └─────────────────────────────────────────────────────────┘  │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │ Supporting Services                                    │  │
│  │                                                        │  │
│  │ ├─ Nginx Reverse Proxy (Port 80/443)                 │  │
│  │ │  - HTTPS termination (Let's Encrypt SSL)           │  │
│  │ │  - Load balancing (for future multi-worker)       │  │
│  │ │  - Static file serving                            │  │
│  │ │                                                    │  │
│  │ ├─ Systemd Service                                   │  │
│  │ │  - Persistent FastAPI process                     │  │
│  │ │  - Auto-restart on failure                        │  │
│  │ │  - Logging to syslog                              │  │
│  │ │                                                    │  │
│  │ ├─ Cron Jobs                                         │  │
│  │ │  - Daily FAISS index refresh                      │  │
│  │ │  - Weekly database backup                         │  │
│  │ │  - Monthly model update check                     │  │
│  │ │                                                    │  │
│  │ └─ Monitoring (Optional)                             │  │
│  │    - CloudWatch / Prometheus metrics                │  │
│  │    - Response time tracking                         │  │
│  │    - Error rate alerting                            │  │
│  └─────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              ↓↑ (PostgreSQL Wire Protocol)
┌─────────────────────────────────────────────────────────────────┐
│                  Supabase PostgreSQL                             │
│  Type: Managed PostgreSQL 14+                                   │
│  Region: ap-southeast-1 (same as EC2)                           │
│  Storage: 500GB (default, auto-scalable)                        │
│  Backups: Daily, 7-day retention                                │
│  Replication: Read replicas available                           │
│                                                                │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │ Core Databases                                          │  │
│  │                                                         │  │
│  │ ├─ users (Student accounts)                            │  │
│  │ │  ├─ id (PK)                                          │  │
│  │ │  ├─ email (UNIQUE)                                  │  │
│  │ │  ├─ password_hash (bcrypt)                          │  │
│  │ │  ├─ full_name                                       │  │
│  │ │  ├─ section (STEM-A, STEM-B, etc.)                 │  │
│  │ │  ├─ enrollment_status (active, inactive)            │  │
│  │ │  ├─ created_at, updated_at (TIMESTAMP)             │  │
│  │ │  └─ Indices: (email), (created_at)                │  │
│  │ │                                                      │  │
│  │ ├─ sessions (JWT + Session tracking)                  │  │
│  │ │  ├─ id (PK)                                         │  │
│  │ │  ├─ user_id (FK → users)                           │  │
│  │ │  ├─ token (UNIQUE, 500 chars)                       │  │
│  │ │  ├─ expires_at (TIMESTAMP)                         │  │
│  │ │  ├─ created_at (TIMESTAMP)                         │  │
│  │ │  └─ Indices: (user_id), (token), (expires_at)     │  │
│  │ │                                                      │  │
│  │ ├─ quiz_attempts (Quiz session records)              │  │
│  │ │  ├─ id (PK)                                         │  │
│  │ │  ├─ user_id (FK → users)                           │  │
│  │ │  ├─ difficulty_level (Basic, Intermed., Advanced) │  │
│  │ │  ├─ total_questions (INTEGER)                      │  │
│  │ │  ├─ correct_answers (INTEGER)                      │  │
│  │ │  ├─ score (FLOAT 0–100)                           │  │
│  │ │  ├─ points_earned (INTEGER)                        │  │
│  │ │  ├─ attempted_at (TIMESTAMP)                       │  │
│  │ │  └─ Indices: (user_id), (attempted_at)            │  │
│  │ │                                                      │  │
│  │ ├─ quiz_responses (Answer-level detail)              │  │
│  │ │  ├─ id (PK)                                         │  │
│  │ │  ├─ attempt_id (FK → quiz_attempts)               │  │
│  │ │  ├─ question_id (INTEGER)                          │  │
│  │ │  ├─ user_answer (TEXT)                            │  │
│  │ │  ├─ correct_answer (TEXT)                         │  │
│  │ │  ├─ is_correct (BOOLEAN)                          │  │
│  │ │  ├─ created_at (TIMESTAMP)                        │  │
│  │ │  └─ Indices: (attempt_id), (question_id)         │  │
│  │ │                                                      │  │
│  │ ├─ knowledge_base_metadata (PDF inventory)          │  │
│  │ │  ├─ id (PK)                                        │  │
│  │ │  ├─ subject (General Math, Pre-Calc, etc.)       │  │
│  │ │  ├─ pdf_filename                                 │  │
│  │ │  ├─ chunk_count (total chunks indexed)           │  │
│  │ │  ├─ faiss_index_version (for versioning)         │  │
│  │ │  ├─ created_at, updated_at                       │  │
│  │ │  └─ Indices: (subject)                           │  │
│  │ │                                                      │  │
│  │ └─ faiss_indices (Persistent vector store)          │  │
│  │    ├─ id (PK)                                        │  │
│  │    ├─ subject (FK → knowledge_base_metadata)       │  │
│  │    ├─ chunk_id                                      │  │
│  │    ├─ chunk_text (TEXT)                            │  │
│  │    ├─ embedding (vector(384) – pgvector)          │  │
│  │    ├─ pdf_source (filename)                        │  │
│  │    ├─ page_number                                  │  │
│  │    ├─ created_at                                   │  │
│  │    └─ Indices:                                      │  │
│  │       (subject, chunk_id)                          │  │
│  │       IVFFlat(embedding) – for cosine search       │  │
│  │                                                      │  │
│  └─────────────────────────────────────────────────────────┘  │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │ Extensions & Features                                   │  │
│  │                                                         │  │
│  │ ├─ pgvector (Vector similarity)                        │  │
│  │ │  CREATE EXTENSION IF NOT EXISTS vector;             │  │
│  │ │  FAISS index persisted as vector column             │  │
│  │ │  Cosine distance metric for retrieval               │  │
│  │ │                                                      │  │
│  │ ├─ Connection Pooling (PgBouncer)                     │  │
│  │ │  50 simultaneous connections                        │  │
│  │ │  Connection reuse for performance                   │  │
│  │ │                                                      │  │
│  │ └─ Automated Backups                                   │  │
│  │    Daily snapshots, 7-day retention                   │  │
│  │    Can restore to any point in time                   │  │
│  └─────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│              External Services (Optional)                        │
│                                                                │
│  ├─ Claude API (Post-Defense Fallback)                        │
│  │  - Used only if T5 + Phi-3 Mini both fail               │
│  │  - Requires API key (not included in thesis)            │
│  │                                                          │
│  ├─ Let's Encrypt SSL Certificates                          │
│  │  - HTTPS/TLS encryption for EC2 domain                 │
│  │  - Auto-renewal via certbot                            │
│  │                                                          │
│  └─ GitHub (Version Control)                                │
│     - Private repository: ktrnakrzl/mathiva                │
│     - Develop branch (active), main branch (stable)        │
│     - Used for code storage, not deployment               │
└─────────────────────────────────────────────────────────────────┘
```

### 4.2 Deployment Process (CI/CD Pipeline)

```
┌──────────────────────────────────────────────┐
│ Developer commits code to GitHub             │
│ (develop branch)                             │
└──────────────────────────────────────────────┘
                      ↓
        (Manual deployment currently)
                      ↓
┌──────────────────────────────────────────────┐
│ Pull from GitHub on EC2:                     │
│ $ git pull origin develop                    │
└──────────────────────────────────────────────┘
                      ↓
┌──────────────────────────────────────────────┐
│ Test locally:                                │
│ $ python -m pytest tests/                    │
│ $ flake8 app/                                │
└──────────────────────────────────────────────┘
                      ↓
┌──────────────────────────────────────────────┐
│ If tests pass:                               │
│ $ systemctl restart mathiva                  │
│ (FastAPI service)                            │
└──────────────────────────────────────────────┘
                      ↓
┌──────────────────────────────────────────────┐
│ Verify deployment:                           │
│ $ curl https://mathiva.api/health            │
│ Expected: HTTP 200 OK                        │
└──────────────────────────────────────────────┘
                      ↓
┌──────────────────────────────────────────────┐
│ Monitor logs:                                │
│ $ journalctl -u mathiva -f                   │
│ $ tail -f /var/log/mathiva.log               │
└──────────────────────────────────────────────┘

Note: Future improvement → GitHub Actions for 
automated testing + deployment
```

---

## 5. Scalability & Performance Considerations

### 5.1 Current Capacity Planning

| Component | Current | Bottleneck | Scaling Strategy |
|---|---|---|---|
| **EC2 Instance** | t3.medium (2 vCPU, 4GB) | CPU during ML inference | Upgrade to t3.large or GPU instance (g4dn.xlarge) |
| **FastAPI Workers** | 4 workers | Request queue buildup >50 users | Add more workers or horizontal scaling (load balancer) |
| **FAISS Indices** | 1108 chunks (General Math only) | Memory when loading multiple subjects | Lazy loading per subject, index sharding |
| **PostgreSQL** | Single instance | Connection pool exhaustion | Read replicas, connection pooling (PgBouncer) |
| **Student Concurrency** | 50–100 simultaneous | Network bandwidth, model inference time | Caching, CDN for static assets |

### 5.2 Response Time Targets (Non-Functional Requirements)

| Endpoint | Target | Status |
|---|---|---|
| `POST /ask` | < 3 sec (p95) | On track with T5 + FAISS |
| `POST /solve` | < 2 sec (p95) | SymPy is fast, well within target |
| `POST /quiz` | < 1 sec | Database query, easily achieved |
| `POST /auth/login` | < 500 ms | Password hashing + token gen |
| `GET /user/progress` | < 800 ms | Aggregation query |

### 5.3 Optimization Techniques Implemented

1. **FAISS Vector Search** — O(log n) complexity with IVFFlat indexing
2. **Response Caching** — Cache frequent Q&A pairs (Redis future)
3. **Database Indexing** — B-tree indices on user_id, email, timestamps
4. **Lazy Model Loading** — T5 loaded on first use, not startup
5. **Streaming Responses** — Large quiz results streamed incrementally (future)

---

## 6. Integration Points & Third-Party Dependencies

### 6.1 External Integrations

```
┌──────────────────┐
│  AWS EC2         │
│  - Compute       │
│  - Storage       │
└────────┬─────────┘
         ↓
┌──────────────────────────────────────────┐
│      MATHIVA Core System                  │
├──────────────────────────────────────────┤
│ FastAPI + ML Models + FAISS + PostgreSQL │
└────────┬─────────────────────────────────┘
         ↓
┌──────────────────┐
│ Supabase         │
│ PostgreSQL       │
│ pgvector         │
└────────┬─────────┘
         ↓
┌──────────────────┐
│ GitHub           │
│ (Version Control)│
└────────┬─────────┘
         ↓
┌──────────────────┐
│ Claude API       │
│ (Optional, Post- │
│  Defense)        │
└──────────────────┘
```

### 6.2 Dependency Matrix

| Library | Version | Purpose | Critical? |
|---|---|---|---|
| fastapi | 0.104+ | Web framework | **YES** |
| torch | 2.0+ | ML inference | **YES** |
| sentence-transformers | 2.2+ | SBERT embeddings | **YES** |
| faiss-cpu | 1.7.4 | Vector search | **YES** |
| sympy | 1.12 | Math solver | **YES** |
| pydantic | 2.0+ | Data validation | **YES** |
| sqlalchemy | 2.0+ | ORM | **YES** |
| psycopg2-binary | 2.9+ | PostgreSQL driver | **YES** |
| pyjwt | 2.8+ | JWT tokens | **YES** |
| bcrypt | 4.0+ | Password hashing | **YES** |
| flutter | 3.10+ | Mobile framework | **YES** |
| riverpod | Latest | State management | **YES** |
| http | Latest | HTTP client (Flutter) | **YES** |

---

## 7. Security Architecture

### 7.1 Security Layers

```
┌─────────────────────────────────────────────┐
│ Client (Flutter App)                        │
│ - Local SQLite encryption (future)          │
│ - No passwords stored locally               │
└─────────────────────────────────────────────┘
                      ↓ HTTPS/TLS
┌─────────────────────────────────────────────┐
│ Network Transport                           │
│ - SSL/TLS (Let's Encrypt)                   │
│ - Certificate pinning (future)              │
│ - CORS validation                           │
└─────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────┐
│ FastAPI Application Layer                   │
│ - JWT token validation on every request     │
│ - Rate limiting per user                    │
│ - Input sanitization & validation           │
│ - Error masking (no internal errors exposed)│
└─────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────┐
│ Database Access                             │
│ - Parameterized queries (SQLAlchemy ORM)    │
│ - Connection pooling with credentials       │
│ - No hardcoded secrets (env variables)      │
│ - Encrypted password storage (bcrypt)       │
└─────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────┐
│ Data at Rest                                │
│ - PostgreSQL encrypted backups              │
│ - Supabase managed encryption               │
│ - User PII protection (GDPR-ready)          │
└─────────────────────────────────────────────┘
```

### 7.2 Authentication Flow

```
┌──────────────────┐
│ Student enters   │
│ email + password │
└────────┬─────────┘
         ↓
┌────────────────────────────────────┐
│ POST /auth/login (HTTPS)           │
│ {email, password}                  │
└────────┬───────────────────────────┘
         ↓
┌────────────────────────────────────┐
│ FastAPI Validation                 │
│ - Email format check               │
│ - Password length check            │
│ - Rate limit (5 attempts/min)      │
└────────┬───────────────────────────┘
         ↓
┌────────────────────────────────────┐
│ Database Lookup                    │
│ SELECT password_hash FROM users    │
│ WHERE email = ?                    │
└────────┬───────────────────────────┘
         ↓
┌────────────────────────────────────┐
│ Password Verification              │
│ bcrypt.checkpw(input, stored_hash) │
└────────┬───────────────────────────┘
         ↓
      (Success)
         ↓
┌────────────────────────────────────┐
│ JWT Token Generation               │
│ payload = {user_id, email, exp}    │
│ token = jwt.encode(payload, SECRET)│
│ (24-hour expiry)                   │
└────────┬───────────────────────────┘
         ↓
┌────────────────────────────────────┐
│ Store in sessions table (optional) │
│ FOR auditing & revocation         │
└────────┬───────────────────────────┘
         ↓
┌────────────────────────────────────┐
│ Return token to client (HTTPS)     │
│ {access_token, token_type, exp}    │
└────────┬───────────────────────────┘
         ↓
┌────────────────────────────────────┐
│ Flutter stores token in memory     │
│ (NOT in SharedPreferences)         │
└────────┬───────────────────────────┘
         ↓
┌────────────────────────────────────┐
│ Subsequent requests include:       │
│ Authorization: Bearer {token}      │
│ (in HTTPS header)                  │
└────────┬───────────────────────────┘
         ↓
┌────────────────────────────────────┐
│ FastAPI middleware validates:      │
│ - Token signature (SECRET)         │
│ - Token expiry                     │
│ - Extract user_id                  │
│ (Per-request, stateless)           │
└────────────────────────────────────┘
```

---

## 8. Monitoring & Observability

### 8.1 Key Metrics to Track

| Category | Metric | Target | Tool |
|---|---|---|---|
| **Performance** | API response time (p95) | < 3 sec | CloudWatch / Prometheus |
| | Model inference latency | < 2 sec | Application logs |
| | Database query time (p95) | < 500 ms | PostgreSQL slow query log |
| **Availability** | Uptime | 99% | CloudWatch alarms |
| | Error rate | < 1% | Application logs |
| **Capacity** | Active concurrent users | < 100 | Application metrics |
| | EC2 CPU usage | < 70% | CloudWatch |
| | EC2 memory usage | < 80% | CloudWatch |
| | Database connections | < 40/50 | PostgreSQL monitoring |
| **Security** | Failed login attempts | Track | Application logs |
| | API rate limit hits | Track | Application logs |

### 8.2 Logging Strategy

```
Application Logs → Centralized Sink (CloudWatch / ELK)

Log Levels:
├─ ERROR: Exceptions, authentication failures, model errors
├─ WARN: Rate limit hits, fallback activations
├─ INFO: Request/response summary, quiz submissions
└─ DEBUG: Detailed traces (FAISS search, embeddings)

Log Retention:
├─ ERROR/WARN: 90 days
├─ INFO: 30 days
└─ DEBUG: 7 days (development only)
```

---

## 9. Disaster Recovery & Business Continuity

### 9.1 Backup Strategy

```
┌─────────────────────────────────┐
│ PostgreSQL Automated Backups    │
│ (Supabase)                      │
├─────────────────────────────────┤
│ Frequency: Daily (24-hour)      │
│ Retention: 7 days               │
│ RTO: 1 hour (restore from snap) │
│ RPO: 1 day (daily snapshots)    │
└─────────────────────────────────┘

┌─────────────────────────────────┐
│ FAISS Index Backups             │
│ (Stored in PostgreSQL pgvector) │
├─────────────────────────────────┤
│ Frequency: Weekly               │
│ Retention: 4 weeks              │
│ RTO: 30 minutes (reload)        │
│ RPO: 1 week (weekly snapshots)  │
└─────────────────────────────────┘

┌─────────────────────────────────┐
│ Code Backup                     │
│ (GitHub repository)             │
├─────────────────────────────────┤
│ Location: ktrnakrzl/mathiva     │
│ Access: Private (team only)     │
│ Retention: Indefinite           │
└─────────────────────────────────┘
```

### 9.2 Failure Scenarios & Recovery

| Scenario | Impact | Recovery | RTO |
|---|---|---|---|
| **EC2 instance crash** | API unavailable | Restart EC2 / failover to new instance | 5–10 min |
| **PostgreSQL down** | Data inaccessible | Supabase auto-recovery or restore from backup | 30 min |
| **FAISS indices corrupted** | RAG unavailable | Reload from PostgreSQL pgvector | 10 min |
| **Model inference failure** | T5 unavailable, trigger fallback Phi-3 | Automatic via fallback chain | < 5 sec |
| **Network connectivity loss** | All services down | Wait for ISP/cloud recovery | 30–60 min |

---

## 10. Technology Stack Justification

### 10.1 Why These Technologies?

| Component | Choice | Rationale |
|---|---|---|
| **Frontend** | Flutter | Cross-platform (Android + iOS), single codebase, fast development |
| **Backend** | FastAPI | High performance, async support, automatic API docs (Swagger), built-in validation |
| **Embeddings** | SBERT | Lightweight, fast, 384-dim vectors are good balance between speed & quality |
| **Vector DB** | FAISS | CPU-friendly, sub-millisecond search, no external service needed |
| **Text Generation** | T5 | Fine-tunable, smaller than GPT models, good for math Q&A |
| **Fallback Model** | Phi-3 Mini | Quantizable, runs on CPU, lower latency than larger models |
| **Math Solver** | SymPy | Pure Python, symbolic computation, no external API calls |
| **Database** | PostgreSQL | Mature, reliable, pgvector extension for vector search, free tier on Supabase |
| **Deployment** | AWS EC2 + Supabase | Cost-effective, control over infrastructure, managed database (less ops burden) |

---

## 11. Design Patterns Used

### 11.1 Architectural Patterns

```
1. LAYERED ARCHITECTURE
   ├─ Presentation (Flutter)
   ├─ Application (FastAPI)
   ├─ Business Logic (RAG, Solver, Quiz)
   ├─ Data Access (ORM, FAISS)
   └─ Data (PostgreSQL, FAISS)

2. MODEL-VIEW-CONTROLLER (MVC) in Flutter
   ├─ Model: Riverpod state + data classes
   ├─ View: Flutter UI widgets
   └─ Controller: Riverpod providers + business logic

3. REPOSITORY PATTERN (Data Access)
   ├─ Repository interface (abstract)
   └─ PostgreSQL implementation

4. FALLBACK / CIRCUIT BREAKER PATTERN
   ├─ Try T5 → On timeout, try Phi-3 → On failure, try Claude API
   └─ Graceful degradation

5. DEPENDENCY INJECTION
   ├─ FastAPI: Dependency() for auth, logging
   └─ Flutter: Riverpod for providers

6. ADAPTER PATTERN
   ├─ Multiple model adapters (T5, Phi-3, Claude)
   └─ Unified inference interface
```

### 11.2 Behavioral Patterns

```
1. SINGLETON
   ├─ FAISS indices (loaded once on startup)
   └─ Model instances (shared across requests)

2. STRATEGY PATTERN
   ├─ Multiple retrieval strategies (FAISS similarity)
   ├─ Multiple response generation strategies (T5, Phi-3)
   └─ Multiple solver strategies (SymPy for equations, etc.)

3. OBSERVER PATTERN
   ├─ Riverpod state listeners (UI updates when data changes)
   └─ Quiz submission → analytics generation (event-driven)

4. COMMAND PATTERN
   ├─ Quiz submission as a command object
   └─ Encapsulates request with parameters

5. CHAIN OF RESPONSIBILITY
   ├─ FastAPI middleware chain (auth → validation → logging)
   └─ Fallback model chain (T5 → Phi-3 → Claude)
```

---

## 12. Revision History

| Version | Date | Author | Changes |
|---|---|---|---|
| 1.0 | June 2026 | Kat | Initial system blueprint for thesis submission |
| 1.1 | 2026-06-25 | Kat | Added Implementation Status section distinguishing built vs. planned components |
| 1.2 | 2026-07-18 | Kat | Added "In progress: T5 fine-tuning pipeline" — dataset engineering (llama3 generation + LLM-judge, 62 curriculum pairs; DeepMind 100k warm-up), two-stage training, fallback-cascade inference design; updated T5 status row |
| 1.3 | 2026-07-19 | Kat | Answer cascade built (`answer_service.py`): RAG + T5 + Phi-3 + Gemini free-tier escalation, `model_used` field; two-stage T5 trained (Stage A on DeepMind 100k, Stage B on curriculum) and evaluated (T5 vs Phi-3 — Phi-3 currently stronger); updated status tables |

---

## Appendix A: File Structure

```
A:\mathiva\
├── README.md
├── requirements.txt
├── .env (contains API keys, DB credentials)
├── .gitignore
├── app/
│   ├── __init__.py
│   ├── main.py (FastAPI app entry point)
│   ├── config.py (settings, env variables)
│   ├── routes/
│   │   ├── __init__.py
│   │   ├── auth.py (POST /auth/login, /auth/register)
│   │   ├── ask.py (POST /ask)
│   │   ├── solve.py (POST /solve)
│   │   ├── quiz.py (POST /quiz, POST /quiz/submit)
│   │   └── user.py (GET /user/profile, /user/progress)
│   ├── models/
│   │   ├── user.py (Pydantic models for request/response)
│   │   ├── quiz.py
│   │   └── rag.py
│   ├── services/
│   │   ├── rag_pipeline.py (RAG logic)
│   │   ├── math_solver.py (SymPy wrapper)
│   │   ├── quiz_engine.py (Quiz generation & scoring)
│   │   ├── user_service.py (Auth, profile CRUD)
│   │   └── ml_models.py (SBERT, T5, Phi-3 loading & inference)
│   ├── db/
│   │   ├── database.py (PostgreSQL connection)
│   │   ├── models.py (SQLAlchemy ORM models)
│   │   └── crud.py (Database operations)
│   ├── utils/
│   │   ├── faiss_utils.py (FAISS loading, search)
│   │   ├── jwt_utils.py (Token generation, validation)
│   │   ├── password_utils.py (Bcrypt hashing)
│   │   └── logger.py (Logging config)
│   └── middleware/
│       ├── auth_middleware.py (JWT validation)
│       └── logging_middleware.py (Request/response logging)
├── ml/
│   ├── models/
│   │   ├── t5_finetuned/ (Weights & config)
│   │   ├── phi3_mini/ (Quantized weights)
│   │   └── sbert/ (Downloaded model)
│   ├── data/
│   │   ├── genmath_qa_pairs.json (373 Q&A pairs)
│   │   └── general_math.pdf (Original knowledge source)
│   ├── solver/
│   │   └── math_solver.py (SymPy-based solver)
│   └── rag/
│       ├── chunk_pdf.py (PDF chunking script)
│       ├── faiss_index.py (Index creation/search)
│       └── embedder.py (SBERT embedding)
├── tests/
│   ├── test_auth.py
│   ├── test_ask.py
│   ├── test_solve.py
│   ├── test_quiz.py
│   ├── test_rag_pipeline.py
│   └── test_math_solver.py
├── docs/
│   ├── MATHIVA_FLUTTER_GUIDE.md
│   ├── MATHIVA_SYSTEM_SPECIFICATION.md
│   ├── MATHIVA_SYSTEM_BLUEPRINT.md
│   └── API_REFERENCE.md
└── scripts/
    ├── deploy.sh (Deployment automation)
    ├── refresh_faiss.py (Periodic index refresh)
    └── backup_db.sh (Database backup)
```

---

**Document Classification:** Thesis Submission — CONFIDENTIAL  
**Last Updated:** June 2026  
**Next Review:** Post-Defense (Recommended)

---

## END OF SYSTEM BLUEPRINT DOCUMENT
