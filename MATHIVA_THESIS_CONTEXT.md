# MATHIVA — Thesis Context Reference (Chapters 1–3)

> **Purpose of this file.** A factual, up-to-date description of the MATHIVA
> system to give an AI writing assistant (or yourself) accurate grounding when
> drafting **Chapter 1 (Introduction), Chapter 2 (Review of Related Literature),
> and Chapter 3 (Methodology)**. Everything below reflects what is *actually
> implemented* as of this writing. **Do not overclaim beyond what is stated in
> the "Limitations / honest current state" section** — the accuracy of those
> caveats is what keeps the thesis defensible.

---

## 1. What MATHIVA is (one-paragraph summary)

**MATHIVA** is a mobile-based intelligent mathematics learning assistant for
Senior High School students (Grade 11–12, following the Philippine DepEd
curriculum: General Mathematics, Statistics & Probability, Pre-Calculus, Basic
Calculus). It combines three capabilities in one app: (1) an **equation solver**
that reads typed *or* photographed/handwritten problems and shows step-by-step
solutions; (2) an **AI math tutor** that answers conceptual questions grounded in
course material using Retrieval-Augmented Generation (RAG) plus language models;
and (3) a **personalized practice system** that generates quizzes, adapts their
difficulty and topic to each student's performance history, tracks progress, and
schedules review of weak concepts. The stated research contribution is *"RAG with
fine-tuned transformer models"* applied to in-domain math tutoring.

---

## 2. Chapter 1 — Introduction material

### 2.1 Problem / motivation
- SHS students often lack immediate, personalized help with mathematics outside
  the classroom; static apps and generic chatbots don't adapt to the individual
  or ground answers in their actual curriculum.
- General-purpose LLMs can hallucinate and are not specialized to the DepEd
  syllabus; a system that *retrieves course material* and can *specialize a model
  to the domain* should give more relevant, trustworthy help.
- Practice apps typically serve fixed question banks rather than targeting a
  learner's specific weak spots.

### 2.2 General objective
Develop MATHIVA, a mobile intelligent tutoring system that provides
curriculum-grounded AI tutoring, automated step-by-step problem solving, and
personalized adaptive practice for senior-high-school mathematics.

### 2.3 Specific objectives (all implemented)
1. **Solve typed and photographed equations** with worked steps (OCR → symbolic
   math engine).
2. **Answer conceptual questions** via a RAG pipeline grounded in course
   material, using a fine-tuned transformer with a fallback to a general LLM.
3. **Generate personalized quizzes** whose *concept* and *difficulty* are chosen
   from the individual student's attempt history.
4. **Track progress and schedule spaced review** of concepts the student has not
   yet mastered.
5. **Support secure student accounts** (registration, login, per-user data).

### 2.4 Scope and delimitations
- **In scope:** Grade 11–12 SHS math; a working mobile app + backend + ML
  pipeline; the four subjects listed above, with the deepest content in **General
  Mathematics**.
- **Out of scope / delimitations:** not a replacement for a teacher; the fine-
  tuned model is trained on a small in-domain dataset (see limitations); the
  retrieval corpus currently covers **General Mathematics only**; no live public
  deployment at submission (runs locally / on a configured cloud database); the
  app targets **mobile** (some features such as camera capture are mobile-only).

### 2.5 Significance / target users
Primary users are **SHS students**; the system benefits self-study, homework
help, and targeted remediation. Secondary relevance to teachers (progress data)
and to research on domain-specialized RAG + small fine-tuned models.

---

## 3. Chapter 2 — Concepts & technologies to review (RRL fodder)

These are the technical concepts the system is built on; each is a legitimate
literature-review topic:

- **Intelligent Tutoring Systems (ITS)** and adaptive/personalized learning.
- **Retrieval-Augmented Generation (RAG):** combining a semantic retriever with a
  language model so answers are grounded in a document corpus.
- **Sentence embeddings & vector similarity search:** SBERT (Sentence-BERT) +
  FAISS for nearest-neighbour retrieval by cosine similarity.
- **Transformer fine-tuning for domain specialization:** adapting a pretrained
  seq2seq model (T5 / FLAN-T5) to an in-domain question→answer task.
- **Large Language Models as tutors:** small local models (Phi-3 via Ollama) and
  hosted models (Google Gemini) for natural-language explanation.
- **Optical Character Recognition for math:** converting printed/handwritten math
  images to machine-readable form (LaTeX) — local `pix2tex` and multimodal LLM OCR.
- **Symbolic computation / Computer Algebra Systems:** SymPy for exact,
  provably-correct equation solving (as opposed to LLM "guessing").
- **Adaptive item selection & difficulty adaptation** (a simplified mastery /
  performance-based policy).
- **Spaced repetition** for review scheduling.
- **Gamification of learning** (streaks, points, achievements).

---

## 4. Chapter 3 — System architecture

### 4.1 High-level architecture
Three tiers:

```
Flutter mobile app  ──HTTP/JSON──►  FastAPI backend  ──►  SQL database
   (presentation)                     (application)         (SQLite dev /
                                          │                  PostgreSQL prod)
                                          ▼
                          ML / AI services (in-process + external):
                          RAG (SBERT + FAISS), fine-tuned T5,
                          Phi-3 (Ollama), Google Gemini, SymPy, pix2tex
```

The backend is layered internally: **API routers** (thin request/response) →
**services** (business logic) → **data** (SQLAlchemy models + DB session).

### 4.2 Tools and technologies used (complete)

**Mobile application — Flutter / Dart**
| Package / tool | Purpose |
|---|---|
| **Flutter SDK, Dart** | Cross-platform mobile app framework and language |
| **go_router** | Declarative navigation / routing |
| **flutter_riverpod** | State management |
| **dio** | HTTP client (calls the backend REST API) |
| **flutter_math_fork** | Renders mathematical notation (LaTeX) in the UI |
| **google_fonts** | Typography (e.g. serif display fonts) |
| **flutter_svg** | Vector graphics / icons |
| **image_picker**, **image_cropper** | Capture and crop equation photos for the scanner |
| **flutter_local_notifications**, **timezone**, **flutter_timezone** | Local study-reminder notifications |
| **shared_preferences** | On-device storage of user preferences |
| **freezed_annotation**, **json_annotation** | Data-model and JSON code generation |
| **cupertino_icons** | Icon set |

**Backend — Python / FastAPI**
| Package / tool | Purpose |
|---|---|
| **FastAPI** | REST API web framework |
| **Uvicorn** | ASGI server that runs the app |
| **SQLAlchemy** | Object-Relational Mapper (database access) |
| **Alembic** | Database schema migrations (source of truth for the Postgres schema) |
| **Pydantic / pydantic-settings** | Request validation and typed, environment-based configuration |
| **python-dotenv** | Loads configuration from a `.env` file |
| **bcrypt** | Password hashing |
| **PyJWT** | JSON Web Token creation/verification (authentication) |
| **python-multipart** | Handles image file uploads |
| **email-validator** | Validates registration email addresses |
| **requests** | Server-side HTTP calls to Ollama and the Gemini API |
| **psycopg2-binary** | PostgreSQL database driver |
| **pgvector** | Postgres vector-column support (available for future vector storage) |

**Database & infrastructure**
| Tool | Purpose |
|---|---|
| **SQLite** | Local development database (zero-setup) |
| **PostgreSQL** | Production relational database |
| **Supabase** | Managed cloud PostgreSQL hosting for production (the app's production database is a Supabase Postgres instance) |
| **Git + GitHub** | Version control and code hosting |

**AI / Machine-learning components**
| Tool / model | Purpose |
|---|---|
| **sentence-transformers** (`all-MiniLM-L6-v2`) | Sentence embeddings for RAG retrieval |
| **FAISS** (`faiss-cpu`) | Vector similarity index (cosine search over course-material chunks) |
| **Hugging Face Transformers** | Loading/running (and fine-tuning) the T5 model |
| **PyTorch (torch)** | Deep-learning runtime for the models |
| **FLAN-T5-base** | The transformer that was **fine-tuned** for in-domain tutoring |
| **Ollama** running **Phi-3** (`phi`) | Local general-purpose LLM (tutor answers + question rephrasing) |
| **Google Gemini API** (`gemini-flash-latest`, free tier) | Hosted multimodal LLM for photo/handwriting OCR and tutor fallback |
| **SymPy** (+ `antlr4-python3-runtime`) | Exact symbolic equation solving and LaTeX parsing |
| **pix2tex** (+ **Pillow**) | Local image-to-LaTeX OCR for printed math |

**ML training & evaluation (development-time tools)**
| Tool | Purpose |
|---|---|
| **Hugging Face `datasets`, `accelerate`** | Data loading and training loop for fine-tuning |
| **Google Colab (T4 GPU)** | Cloud GPU environment used to fine-tune FLAN-T5-base |
| **Google DeepMind Mathematics dataset** | Large generic symbolic-math set used for optional warm-up training |
| **rouge_score, sacrebleu, bert_score** | Metrics for evaluating T5 vs. Phi-3 answers |
| **Google AI Studio** | Source of the free Gemini API key |

**Testing / quality**
| Tool | Purpose |
|---|---|
| **pytest** | Automated backend test suite — **154 tests, all passing** (auth, solver, OCR, quiz, answer cascade, adaptive personalization, config); ~1,390 lines of test code against ~2,700 lines of application code |
| **flutter_test** | Present but **not used**: the mobile app has no automated tests; the Flutter UI is verified manually |

### 4.3 Authentication & data
- **JWT-based auth** (HS256). Passwords hashed with **bcrypt**. Registration,
  login, and a `/me` profile endpoint.
- Core tables: `users`, `quiz_questions` (server-generated questions with their
  correct answers), `quiz_attempts` (every graded attempt, used for progress and
  personalization).
- **Config is centralized and environment-aware**: a typed settings object; a
  startup guard refuses to run in "production" mode with an insecure secret or a
  non-Postgres database. Migrations (Alembic) manage the production schema.

---

## 5. Chapter 3 — How each feature works (methodology detail)

### 5.1 Equation solver (typed + photo)
- **Typed:** the expression is parsed with SymPy (accepting natural student
  notation such as `2x + 3 = 13` and `x^2`), solved exactly, and a step-by-step
  explanation is produced. Because the answer is *computed*, it is trustworthy.
- **Photo (hybrid, local-first):** the image is read by the local `pix2tex`
  model first; if that read does not yield a *solvable* equation, the system
  falls back to **Gemini** (which reads handwriting and photographs) and accepts
  its output only if it, too, solves. Guards reject garbled scans instead of
  returning confidently-wrong answers.

### 5.2 AI tutor — RAG + model cascade
For a conceptual question:
1. **Retrieve** the most relevant course-material chunks (SBERT embedding of the
   question → FAISS cosine search).
2. **Generate** an answer from a shared "tutor prompt" (instruction + retrieved
   context + question). Multiple generators participate in a **cascade**. T5 and
   Phi-3 are both invoked locally, then ranked by preference:
   **Phi-3 (preferred) → fine-tuned T5 (backup) → Gemini (bounded escalation)**.
   Phi-3 is ranked first *empirically*, because it currently outperforms the T5
   fine-tune (§5.3); the ordering is a measured decision, not an architectural
   assumption, and would be revisited if a larger fine-tune wins.
3. A cheap, objective **quality guard** (`is_bad_answer`) rejects empty or
   degenerate (repetition-loop) output; escalation to the free Gemini tier
   happens *only* when the local answer is still bad, so quota isn't wasted.
4. The response reports which model tier answered (`model_used`).
- **Deployment note:** where no local Ollama exists (a hosted, no-GPU
  deployment), the cascade automatically uses **Gemini** as the tutor; locally it
  uses the full Phi-3 + T5 pipeline.

### 5.3 Fine-tuned T5 (the research contribution)
- A **FLAN-T5-base** model was fine-tuned on in-domain *(instruction + retrieved
  context → reference answer)* pairs so a small specialized model learns the exact
  inference task. A large generic symbolic-math set was used for optional warm-up
  (Stage A), then the curriculum pairs (Stage B).
- The pairs come from a *quality-judged* generation pipeline (auto-generate → LLM
  judge → keep survivors). **The judged set is small (62 examples).**
- **Why it is small — be precise about this.** The size is *not* a property of the
  corpus. The generation pass was run over only **40 of the 1,108 corpus chunks
  (3.6%)**, yielding 74 raw pairs of which the judge kept 62 (an 84% keep rate).
  At the observed rate of ~1.85 pairs/chunk, a full-corpus pass projects to
  roughly **1,700 usable pairs (~27×)** using the *existing* pipeline with no
  methodological change. A further ~51 hand-authored pairs exist but are not yet
  folded into the training set. The correct framing for the thesis is therefore
  *"results reported at an early dataset checkpoint,"* not *"the domain affords
  only 62 examples."*
- **Honest result:** at this dataset size the fine-tuned T5 **underperforms** the
  general-purpose Phi-3 — on several held-out questions it collapses into
  repetition loops (e.g. emitting `x 0 x 0 x 0 …` for a logarithmic-graph
  question) rather than merely answering imprecisely. The live cascade therefore
  *prefers* Phi-3/Gemini and keeps T5 as a backup, which means **the fine-tuned
  model does not currently contribute to answers the student sees.** This is
  itself a reportable finding: *a small in-domain fine-tune on limited data does
  not yet beat a generalist; growing the dataset is the identified path forward.*

### 5.4 Adaptive quiz generation (personalization)
- Questions are produced by **parametric templates** (11 concept generators) that
  randomize the numbers and **compute the correct answer in Python**, so grading
  is trustworthy; an LLM optionally rephrases only the wording (never the numbers
  or answer).
- **Server-side adaptive selection** decides what the student practices next from
  *their own attempt history* (not client-chosen):
  - **Concept:** weighted toward the concepts the student is weakest at (low
    accuracy) or has not tried, with a small floor so mastered concepts still
    resurface occasionally.
  - **Difficulty:** starts Easy; steps up after recent success, down when the
    student struggles (based on a recent-attempts window).
- The app surfaces this as **concept-scoped practice** (adaptive difficulty on a
  chosen concept) and **"Smart Practice"** (the server also chooses *which*
  concept in a lesson to drill).

### 5.5 Spaced-repetition review queue
- A **"Review"** action selects the concept the student most needs to revisit —
  one they have *attempted but not recently mastered* (recent-window accuracy
  below a mastery threshold) — weighted toward their weakest, then routes them
  into adaptive practice on it. Mastering a concept removes it from the queue
  (spaced-repetition-lite). Says "all caught up" when nothing is due.

### 5.6 Progress tracking & gamification
- Every attempt is graded **server-side** and stored per user. A progress
  endpoint aggregates: overall accuracy, per-subject / per-topic / per-concept
  stats, best times, current day-streak, total study time, points
  (fixed per correct answer), 7-day activity, and **achievements** (first
  problem, 7-day streak, speed, accuracy milestones, study-time, etc.).

### 5.7 Grading integrity
- For generated quizzes the **server owns the correct answer** and grades
  submissions (the client never sends "is this correct"), preventing cheating.

---

## 6. Data & evaluation (be precise in the thesis)

- **Retrieval corpus:** built from General-Mathematics course material; ~1,100
  unique text chunks. Other subjects are not yet in the corpus.
- **Fine-tune dataset:** 62 quality-judged (context→answer) pairs, split
  **50 train / 7 validation / 5 test**, grouped by source chunk so no chunk's
  context leaks across splits. A large generic symbolic-math set (~96k
  train / 2k val / 2k test) exists for Stage-A warm-up.
- **Evaluation done:** T5 vs. Phi-3 on the held-out set with ROUGE-L / BLEU /
  BERTScore (T5: ROUGE-L 0.154, BLEU 0.316, BERTScore-F1 0.698); qualitative
  degeneracy observed for T5. **Result: Phi-3 currently stronger.**
- **Treat these metrics as indicative, not conclusive.** The test split is
  **5 examples** — far too few for the differences to be statistically
  meaningful. The split also inherits two defects from the generation pass:
  some items are **not mathematics** (one asks what happens to the temperature
  of ice as it is heated — generated from non-math passages in the source PDF),
  and some are **circular**, restating the question as the answer (*"What is the
  equation of the graph y = log(x−1)+2?"* → *"The equation is y = log(x−1)+2."*).
  Front-matter boilerplate (e.g. publisher contact details) also survives the
  judge. A defensible comparison requires re-running evaluation on a larger,
  filtered, math-only test set after the full-corpus generation pass.
- **Not yet measured (state as limitation / future work):** OCR accuracy on real
  student photos; large-scale retrieval accuracy (an internal check found the
  gold chunk retrieved in the top results roughly half the time); live end-to-end
  answer-quality metrics.

---

## 7. Limitations / honest current state (for Scope & Limitations + Future Work)

- **Fine-tuned model is weak at current data size** — trained and integrated, but
  outperformed by the generalist, so it is ranked below Phi-3 in the cascade and
  does not currently affect student-visible answers. The honest framing is a
  demonstrated pipeline plus a negative-but-informative result. Crucially, the
  limiting factor is an **incomplete dataset-generation pass (40 of 1,108
  chunks)**, not a limit of the method — completing it is a known, mechanical
  next step rather than open-ended research.
- **The evaluation is under-powered** — a 5-example test split containing some
  non-mathematical and circular items cannot support a strong claim in either
  direction. Re-evaluation on a larger filtered set is required before the
  T5-vs-Phi-3 comparison should be reported as a finding.
- **Retrieval corpus is General-Mathematics only**, and is not yet filtered for
  front-matter/boilerplate, which propagates noise into generated QA pairs.
- **No automated testing of the mobile app and no continuous integration** — the
  backend suite is comprehensive but is run manually; the ~12,500-line Flutter
  codebase is validated only by manual use.
- **Quiz content coverage** is limited to the 11 templated concepts (the app's
  current curriculum concepts all map to these).
- **OCR accuracy is unmeasured** and depends on photo quality; the camera/OCR
  photo flow is **mobile-only**.
- **No public deployment at submission** — the app runs locally against a backend;
  the production database (Supabase PostgreSQL) and configuration are set up, and
  the backend URL is build-time configurable, but there is no hosted public URL.
- **External free services** are used within their free tiers (Google Gemini); no
  paid cloud APIs are required.

---

## 8. Design decisions worth citing (rationale = good methodology writing)
- **Cheap-first, cloud-on-failure** in both OCR (local pix2tex → Gemini) and
  tutoring (local models → Gemini) — conserves the free API quota and keeps the
  app usable offline for parts.
- **Computed answers, not generated ones**, for solving and quiz grading —
  trustworthiness over fluency.
- **Objective structural guards** (empty/degenerate checks) instead of tuned
  confidence thresholds — simplicity and defensibility.
- **Server-side personalization** using the authenticated student's real history
  — the "personalized" claim is backed by actual adaptive selection, not static
  content.
- **Graceful degradation** — a missing model, key, or GPU disables a tier rather
  than breaking the app.

---

## 9. One-line component glossary (quick reference)
- **RAG** = retrieve relevant course text, then let a model answer using it.
- **SBERT / FAISS** = turn text into vectors and find the closest chunks fast.
- **FLAN-T5** = the transformer being fine-tuned for the in-domain tutor.
- **Phi-3 (Ollama)** = local general LLM used as the tutor and question rephraser.
- **Gemini** = free hosted multimodal LLM for OCR + tutor fallback.
- **SymPy** = exact symbolic math engine for solving.
- **Adaptive selection** = pick concept + difficulty from the student's history.
- **Spaced repetition** = resurface not-yet-mastered concepts for review.
