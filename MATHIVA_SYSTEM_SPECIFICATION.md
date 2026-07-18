# MATHIVA: System Specification Document

> ⚠️ **This document specifies the target system**, including requirements not yet fully met. See [Implementation Status](#implementation-status-as-of-2026-06-25) immediately below for what's actually running today vs. what's still planned.

## Executive Summary

MATHIVA is a RAG-based mathematics tutoring application designed for STEM strand students (Grades 11–12) at Upper Bicutan National High School (UBNHS). The system provides personalized mathematics instruction through a combination of Retrieval-Augmented Generation (RAG) with fine-tuned transformer models, delivering answers, step-by-step solutions, and adaptive quizzes with performance analytics.

**Full Title:** MATHIVA: A RAG-Based Mathematics Tutoring Application for STEM Strand Students of Upper Bicutan National High School

---

## Implementation Status (as of 2026-06-25)

This document specifies the **full target system** (Sections 1–12 below). This section is the source of truth for what's actually implemented vs. still planned — see [MATHIVA_SYSTEM_BLUEPRINT.md](./MATHIVA_SYSTEM_BLUEPRINT.md#implementation-status-as-of-2026-06-25) for the matching architecture-level breakdown.

**§5 Database Schema** — only the `users` table (§5.1 `users`) exists today. `sessions`, `quiz_attempts`, `quiz_responses`, `knowledge_base_metadata`, and `faiss_indices` (pgvector) are all specified but not yet created. Currently running on local SQLite, not the specified Supabase Postgres.

**§6 API Specification** — implemented vs. specified:

| Endpoint | Status |
|---|---|
| `POST /auth/register`, `POST /auth/login` | ✅ Live (bcrypt + JWT, 24h expiry) |
| `POST /ask` (as `/api/ask`) | ✅ Live — SBERT → FAISS → **answer cascade** (Phi-3 primary + fine-tuned T5 backup + Gemini free-tier escalation; returns `model_used`). `/api/ask/stream` still streams Phi-3 only. |
| `POST /solve` | ✅ Live (SymPy) |
| `POST /quiz` | 🟡 Partial — generates questions from `genmath_qa_pairs.json`, but no scoring |
| `POST /quiz/submit` | ❌ Not implemented |
| `GET /user/profile`, `GET /user/progress` | ❌ Not implemented |

**§3 Architecture / §9 Deployment** — running locally (FastAPI dev server), not deployed to AWS EC2 + Supabase as specified. No Nginx, systemd, or CI/CD pipeline yet.

**T5 fine-tuning (FR-RAG-04) — 🔄 pipeline built, not yet integrated (as of 2026-07-18).** The full training pipeline exists and `train.py` is verified end-to-end, but the model is not yet trained-to-convergence or wired into `/ask` (which still calls Ollama "phi" only). Two datasets are prepared: a **curriculum QA set** (DepEd General Mathematics textbook → llama3 generation → llama3 LLM-judge → **62 kept pairs**, RAG-augmented and grouped-split into 50/7/5) and a **DeepMind Mathematics warm-up set** (100k generic Q&A, split 96k/2k/2k). Planned training is two-stage (generic warm-up → curriculum), `flan-t5-base` on a free Colab T4, evaluated with ROUGE-L/BLEU and a T5-vs-Phi-3 comparison. Full detail: [BLUEPRINT → In progress: T5 fine-tuning pipeline](./MATHIVA_SYSTEM_BLUEPRINT.md#-in-progress-t5-fine-tuning-pipeline-as-of-2026-07-18).

**Runway:** thesis deadline is ~mid-August 2026 (6 weeks out as of this writing) — the gaps above are this stretch's actual work, not just documentation debt. Update this section as each lands.

---

## 1. System Overview

### 1.1 Purpose and Scope

MATHIVA serves as a supplementary tutoring tool for STEM students, addressing:
- **Knowledge gaps** in core mathematics subjects (General Math, Pre-Calculus, Statistics, Business Math, Basic Calculus)
- **Self-paced learning** with 24/7 availability
- **Personalized practice** through adaptive quizzes with wrong-answer detection and difficulty levels
- **Performance tracking** with item analysis and reward-based gamification

**Target Users:** STEM strand Grade 11–12 students at UBNHS (approximately 100–150 students)

**In Scope:**
- Student-facing web and mobile application
- Mathematics content delivery and problem-solving
- Quiz generation and performance analytics
- User authentication and session management

**Out of Scope:**
- Teacher or administrator dashboards (post-MVP consideration)
- Parent/guardian interfaces
- LMS integration with DepEd systems
- College-level or JHS content

### 1.2 Key Constraints

- **Curriculum:** DepEd SHS STEM core mathematics subjects only
- **Deployment:** Hybrid (AWS EC2 + Supabase with local model inference)
- **Thesis Scope:** Local models only (RAG + T5 fine-tuned + Phi-3 Mini); Claude API as optional post-defense fallback
- **Timeline:** Thesis submission by end of June 2026
- **Hardware:** Target Android (primary) + iOS secondary; Windows development

---

## 2. System Requirements

### 2.1 Functional Requirements

#### 2.1.1 Content Management & Knowledge Base

| ID | Requirement | Description |
|---|---|---|
| FR-KB-01 | Subject PDFs | System must support uploading and indexing mathematics subject PDFs (General Math, Pre-Calculus, Statistics, Business Math, Basic Calculus) |
| FR-KB-02 | PDF Chunking | System must chunk PDFs into logical segments using recursive character splitting (overlap: 150 chars, chunk size: 1000 chars) |
| FR-KB-03 | Vector Indexing | System must create and persist FAISS vector indices for all subject PDFs with SBERT embeddings |
| FR-KB-04 | Index Persistence | System must store FAISS indices in PostgreSQL (pgvector) with versioning and update capabilities |

#### 2.1.2 RAG Pipeline & Query Processing

| ID | Requirement | Description |
|---|---|---|
| FR-RAG-01 | Ask Endpoint | System must provide `/ask` endpoint accepting user questions and returning curated answers with citations |
| FR-RAG-02 | Semantic Search | System must perform semantic similarity search across FAISS indices using SBERT embeddings |
| FR-RAG-03 | Context Retrieval | System must retrieve top-K relevant chunks (K=3 default) and rank by relevance |
| FR-RAG-04 | Answer Cascade | ✅ Built. With retrieved context, Phi-3 and the fine-tuned T5 both generate (a combination, not a wait-to-fail chain); the better local answer is chosen, and **Gemini (free tier)** is a bounded escalation used only when the local answer is empty/degenerate. Simple output-sanity guard, not a tuned confidence score. Phi-3 is preferred over T5 for now (T5 weaker at current data size). |
| FR-RAG-05 | Citation Tracking | System must track and return source citations for all RAG responses |

#### 2.1.3 Mathematics Solver

| ID | Requirement | Description |
|---|---|---|
| FR-SOLVER-01 | Equation Solving | System must solve linear, quadratic, and polynomial equations using SymPy |
| FR-SOLVER-02 | Calculus | System must compute derivatives and integrals symbolically |
| FR-SOLVER-03 | Simplification | System must simplify mathematical expressions and equations |
| FR-SOLVER-04 | Factorization | System must factor polynomials and expressions |
| FR-SOLVER-05 | Step-by-Step Solutions | System must provide `/solve` endpoint returning step-by-step walkthroughs (post-MVP: reveal mechanism) |

#### 2.1.4 Quiz & Assessment

| ID | Requirement | Description |
|---|---|---|
| FR-QUIZ-01 | Quiz Generation | System must generate quizzes using 373 real Q&A pairs from `genmath_qa_pairs.json` (not template-based) |
| FR-QUIZ-02 | Difficulty Levels | System must support configurable difficulty levels (Basic, Intermediate, Advanced) |
| FR-QUIZ-03 | Wrong Answer Detection | System must detect incorrect answers and flag for re-practice |
| FR-QUIZ-04 | Performance Tracking | System must track quiz responses, scores, and item analysis per user |
| FR-QUIZ-05 | Reward System | System must implement point/reward system based on quiz performance (panel requirement) |

#### 2.1.5 User Management & Authentication

| ID | Requirement | Description |
|---|---|---|
| FR-AUTH-01 | Student Registration | System must allow student sign-up with email and password |
| FR-AUTH-02 | Session Management | System must maintain secure user sessions with JWT tokens |
| FR-AUTH-03 | User Profile | System must store and manage student profiles (name, section, enrollment status) |
| FR-AUTH-04 | Data Persistence | System must persist user data, quiz attempts, and progress in PostgreSQL |

#### 2.1.6 Frontend UI/UX

| ID | Requirement | Description |
|---|---|---|
| FR-UI-01 | Chat Interface | System must provide intuitive chat screen for `/ask` interactions with KaTeX math rendering |
| FR-UI-02 | Solution Display | System must render step-by-step solutions with proper mathematical notation |
| FR-UI-03 | Quiz Interface | System must provide quiz screen with configurable difficulty and progress tracking |
| FR-UI-04 | Performance Dashboard | System must display student performance metrics, points, and learning history |
| FR-UI-05 | Cross-Platform | System must work on Android (primary) and iOS with responsive Flutter UI |
| FR-UI-06 | Math Input | System must support handwritten math input via Google ML Kit v2 or Pix2tex |

### 2.2 Non-Functional Requirements

| ID | Category | Requirement | Target |
|---|---|---|---|
| NFR-01 | Performance | API response time for `/ask` | < 3 seconds (p95) |
| NFR-02 | Performance | API response time for `/solve` | < 2 seconds (p95) |
| NFR-03 | Performance | Quiz load time | < 1 second |
| NFR-04 | Availability | System uptime | 99% (during school hours) |
| NFR-05 | Scalability | Concurrent users supported | 50–100 simultaneous |
| NFR-06 | Security | Password storage | bcrypt with salt |
| NFR-07 | Security | API authentication | JWT with 24-hour expiry |
| NFR-08 | Data Integrity | FAISS index verification | Checksum validation on load |
| NFR-09 | Usability | Mobile-first design | 320px minimum width support |
| NFR-10 | Reliability | Model fallback latency | Trigger Phi-3 if RAG+T5 fails |

---

## 3. System Architecture

### 3.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    CLIENT LAYER                          │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Flutter Mobile App (Android + iOS)              │  │
│  │  - Chat Screen (Ask/Answer)                      │  │
│  │  - Solver Screen (Step-by-Step Solutions)        │  │
│  │  - Quiz Screen (Adaptive Quizzes)                │  │
│  │  - Dashboard (Performance Metrics)               │  │
│  │  - Math Input (Handwriting Recognition)          │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                          ↓ (HTTP/REST)
┌─────────────────────────────────────────────────────────┐
│                  API GATEWAY LAYER                       │
│  ┌──────────────────────────────────────────────────┐  │
│  │  FastAPI Backend (Python)                        │  │
│  │  - JWT Authentication & Session Management       │  │
│  │  - Request Routing & Validation                  │  │
│  │  - Rate Limiting & CORS                          │  │
│  │  - Logging & Monitoring                          │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                 APPLICATION LAYER                        │
│  ┌──────────────────┐  ┌──────────────────────────────┐ │
│  │  RAG Pipeline    │  │  Query Processors            │ │
│  │  - SBERT         │  │  - Math Solver (SymPy)       │ │
│  │  - FAISS Index   │  │  - Text Generation (T5)      │ │
│  │  - Retrieval     │  │  - Fallback (Phi-3 Mini)     │ │
│  └──────────────────┘  └──────────────────────────────┘ │
│  ┌──────────────────┐  ┌──────────────────────────────┐ │
│  │  Quiz Engine     │  │  User Service                │ │
│  │  - Q&A DB Mgmt   │  │  - Auth & Registration       │ │
│  │  - Scoring       │  │  - Profile Management        │ │
│  │  - Analytics     │  │  - Progress Tracking         │ │
│  └──────────────────┘  └──────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│               DATA & PERSISTENCE LAYER                   │
│  ┌──────────────────┐  ┌──────────────────────────────┐ │
│  │  PostgreSQL      │  │  FAISS Vector Store          │ │
│  │  - User Data     │  │  - Persistent Indices        │ │
│  │  - Quiz History  │  │  - Embedding Cache           │ │
│  │  - Sessions      │  │  - Subject PDFs Metadata     │ │
│  │  - pgvector      │  │                              │ │
│  └──────────────────┘  └──────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│              DEPLOYMENT INFRASTRUCTURE                   │
│  AWS EC2 + Supabase (PostgreSQL) + Local Model Serving  │
└─────────────────────────────────────────────────────────┘
```

### 3.2 Component Descriptions

#### Client Layer
- **Flutter Mobile App:** Cross-platform frontend built with Flutter, using Riverpod for state management
- **KaTeX Integration:** Mathematical formula rendering
- **Google ML Kit v2 + Pix2tex:** Handwritten math input recognition
- **HTTP Client:** RESTful communication with FastAPI backend

#### API Gateway Layer
- **FastAPI Server:** Python web framework handling all HTTP requests
- **Endpoints:**
  - `POST /ask` — Query processing with RAG
  - `POST /solve` — Mathematical problem solving
  - `POST /quiz` — Quiz generation and submission
  - `POST /auth/register` — Student registration
  - `POST /auth/login` — Authentication
  - `GET /user/profile` — User profile retrieval
  - `GET /user/progress` — Performance metrics

#### Application Layer
- **RAG Pipeline:**
  - SBERT (Sentence-BERT) for semantic embeddings
  - FAISS for vector similarity search
  - Retrieval and ranking of top-K relevant chunks
  - T5 fine-tuned model for answer generation

- **Query Processors:**
  - SymPy-based math solver (equations, calculus, simplification, factorization)
  - T5 text generation as primary response model
  - Phi-3 Mini as fallback for complex queries
  - Claude API as optional post-defense fallback

- **Quiz Engine:**
  - 373 real Q&A pairs from `genmath_qa_pairs.json`
  - Configurable difficulty levels
  - Wrong-answer detection and re-practice flagging
  - Point/reward calculation

- **User Service:**
  - JWT-based authentication
  - Student profile and enrollment management
  - Progress tracking and analytics

#### Data & Persistence Layer
- **PostgreSQL + pgvector:**
  - User accounts and authentication data
  - Quiz attempts and responses
  - Session management
  - FAISS index metadata and versioning

- **FAISS Vector Store:**
  - Persistent embeddings for all subject PDFs
  - In-memory loading with disk persistence
  - Subject-based index organization

#### Deployment Infrastructure
- **AWS EC2:** Backend server hosting FastAPI application
- **Supabase (PostgreSQL):** Managed database service
- **Local Model Serving:** On-device inference for T5 and Phi-3 Mini on EC2

---

## 4. Data Flow Diagrams

### 4.1 Ask Endpoint Flow (User Query)

```
User Input (Chat)
      ↓
[FastAPI /ask endpoint]
      ↓
┌─────────────────────────────┐
│  1. Query Preprocessing     │
│  - Tokenize & normalize     │
│  - Spelling correction      │
└─────────────────────────────┘
      ↓
┌─────────────────────────────┐
│  2. Semantic Embedding      │
│  - SBERT encoding           │
│  - Generate query vector    │
└─────────────────────────────┘
      ↓
┌─────────────────────────────┐
│  3. FAISS Retrieval         │
│  - Search top-K chunks      │
│  - Rank by similarity       │
│  (K=3 default)              │
└─────────────────────────────┘
      ↓
┌─────────────────────────────┐
│  4. Context Assembly        │
│  - Combine retrieved chunks │
│  - Track sources/citations  │
└─────────────────────────────┘
      ↓
┌─────────────────────────────┐
│  5. Response Generation     │
│  PRIMARY: T5 (fine-tuned)   │
│  FALLBACK: Phi-3 Mini       │
│  LAST: Claude API (optional)│
└─────────────────────────────┘
      ↓
┌─────────────────────────────┐
│  6. Post-Processing         │
│  - Format response          │
│  - Add citations            │
│  - Validate output          │
└─────────────────────────────┘
      ↓
[Response sent to client]
      ↓
[KaTeX rendering in Chat UI]
```

### 4.2 Solve Endpoint Flow (Step-by-Step Solutions)

```
User Problem Input
      ↓
[FastAPI /solve endpoint]
      ↓
┌─────────────────────────────┐
│  1. Problem Parsing         │
│  - Extract equation/expr    │
│  - Validate syntax          │
└─────────────────────────────┘
      ↓
┌─────────────────────────────┐
│  2. Solution Generation     │
│  - Use SymPy solver         │
│  - Generate intermediate    │
│    steps                    │
└─────────────────────────────┘
      ↓
┌─────────────────────────────┐
│  3. Step Formatting         │
│  - Convert to LaTeX         │
│  - Add explanations         │
│  - Structure response       │
└─────────────────────────────┘
      ↓
[Step-by-step response]
      ↓
[Rendered with KaTeX]
```

### 4.3 Quiz Endpoint Flow (Quiz Generation & Submission)

```
┌─ QUIZ GENERATION ─────────────────┐
│                                   │
│ User requests quiz                │
│ ↓                                 │
│ Select difficulty level           │
│ ↓                                 │
│ Fetch from genmath_qa_pairs.json  │
│ ↓                                 │
│ Randomly select N questions       │
│ ↓                                 │
│ Return quiz to client             │
│                                   │
└───────────────────────────────────┘

┌─ QUIZ SUBMISSION ─────────────────┐
│                                   │
│ User submits answers              │
│ ↓                                 │
│ [FastAPI /quiz endpoint]          │
│ ↓                                 │
│ Compare answers (exact match)     │
│ ↓                                 │
│ Calculate score                   │
│ ↓                                 │
│ Detect wrong answers for re-prac. │
│ ↓                                 │
│ Calculate points/rewards          │
│ ↓                                 │
│ Store attempt in PostgreSQL       │
│ ↓                                 │
│ Generate item analysis report     │
│ ↓                                 │
│ Return feedback to client         │
│                                   │
└───────────────────────────────────┘
```

---

## 5. Database Schema

### 5.1 Core Tables

#### users
```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    section VARCHAR(100),
    enrollment_status VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### sessions
```sql
CREATE TABLE sessions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    token VARCHAR(500) UNIQUE NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### quiz_attempts
```sql
CREATE TABLE quiz_attempts (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    difficulty_level VARCHAR(50),
    total_questions INTEGER,
    correct_answers INTEGER,
    score FLOAT,
    points_earned INTEGER,
    attempted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### quiz_responses
```sql
CREATE TABLE quiz_responses (
    id SERIAL PRIMARY KEY,
    attempt_id INTEGER REFERENCES quiz_attempts(id),
    question_id INTEGER,
    user_answer TEXT,
    correct_answer TEXT,
    is_correct BOOLEAN,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### knowledge_base_metadata
```sql
CREATE TABLE knowledge_base_metadata (
    id SERIAL PRIMARY KEY,
    subject VARCHAR(100),
    pdf_filename VARCHAR(255),
    chunk_count INTEGER,
    faiss_index_version VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### faiss_indices (pgvector)
```sql
CREATE TABLE faiss_indices (
    id SERIAL PRIMARY KEY,
    subject VARCHAR(100),
    chunk_id INTEGER,
    chunk_text TEXT,
    embedding vector(384),  -- SBERT embedding dimension
    pdf_source VARCHAR(255),
    page_number INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_faiss_embedding ON faiss_indices USING ivfflat (embedding vector_cosine_ops);
```

---

## 6. API Specification

### 6.1 Authentication Endpoints

#### POST /auth/register
**Request:**
```json
{
    "email": "student@ubnhs.edu.ph",
    "password": "securePassword123",
    "full_name": "Juan Dela Cruz",
    "section": "STEM-A"
}
```

**Response:**
```json
{
    "user_id": 1,
    "email": "student@ubnhs.edu.ph",
    "message": "Registration successful"
}
```

#### POST /auth/login
**Request:**
```json
{
    "email": "student@ubnhs.edu.ph",
    "password": "securePassword123"
}
```

**Response:**
```json
{
    "access_token": "eyJhbGciOiJIUzI1NiIs...",
    "token_type": "bearer",
    "expires_in": 86400
}
```

### 6.2 Query Endpoints

#### POST /ask
**Request:**
```json
{
    "question": "What is the derivative of x^3 + 2x?",
    "subject": "general_math"
}
```

**Response:**
```json
{
    "answer": "The derivative of x³ + 2x is 3x² + 2.",
    "sources": [
        {
            "chunk_id": 42,
            "pdf": "General_Math.pdf",
            "page": 15
        }
    ],
    "model_used": "t5_finetuned",
    "confidence": 0.92
}
```

#### POST /solve
**Request:**
```json
{
    "problem": "Solve: 2x + 5 = 13",
    "problem_type": "equation"
}
```

**Response:**
```json
{
    "steps": [
        {
            "step": 1,
            "expression": "2x + 5 = 13",
            "explanation": "Original equation"
        },
        {
            "step": 2,
            "expression": "2x = 13 - 5",
            "explanation": "Subtract 5 from both sides"
        },
        {
            "step": 3,
            "expression": "2x = 8",
            "explanation": "Simplify"
        },
        {
            "step": 4,
            "expression": "x = 4",
            "explanation": "Divide both sides by 2"
        }
    ],
    "final_answer": "x = 4"
}
```

#### POST /quiz
**Request:**
```json
{
    "difficulty_level": "intermediate",
    "num_questions": 10,
    "subject": "general_math"
}
```

**Response:**
```json
{
    "quiz_id": 101,
    "questions": [
        {
            "question_id": 1,
            "question": "What is 15% of 200?",
            "options": ["20", "30", "40", "50"],
            "question_type": "multiple_choice"
        }
    ],
    "total_questions": 10
}
```

#### POST /quiz/submit
**Request:**
```json
{
    "quiz_id": 101,
    "answers": [
        {
            "question_id": 1,
            "user_answer": "30"
        }
    ]
}
```

**Response:**
```json
{
    "score": 85.0,
    "correct_answers": 8,
    "total_questions": 10,
    "points_earned": 50,
    "item_analysis": [
        {
            "question_id": 1,
            "is_correct": true,
            "correct_answer": "30"
        }
    ]
}
```

### 6.3 User Endpoints

#### GET /user/profile
**Headers:** `Authorization: Bearer {token}`

**Response:**
```json
{
    "user_id": 1,
    "full_name": "Juan Dela Cruz",
    "email": "student@ubnhs.edu.ph",
    "section": "STEM-A",
    "total_points": 250,
    "total_quizzes_taken": 12
}
```

#### GET /user/progress
**Headers:** `Authorization: Bearer {token}`

**Response:**
```json
{
    "total_quizzes": 12,
    "average_score": 78.5,
    "total_points": 250,
    "recent_attempts": [
        {
            "quiz_id": 101,
            "score": 85.0,
            "attempted_at": "2026-06-08T14:30:00Z"
        }
    ]
}
```

---

## 7. Technology Stack

| Layer | Component | Technology |
|---|---|---|
| **Frontend** | Mobile App | Flutter |
| | State Management | Riverpod |
| | Math Rendering | KaTeX |
| | Math Input | Google ML Kit v2, Pix2tex |
| **Backend** | API Framework | FastAPI (Python) |
| | Model Serving | PyTorch |
| **AI/ML** | Embeddings | SBERT |
| | Vector Store | FAISS |
| | Text Generation | Fine-tuned T5 |
| | Fallback Model | Phi-3 Mini |
| | Math Solver | SymPy, SciPy, NumPy |
| | Fallback API | Claude API (post-defense) |
| **Database** | Primary DB | PostgreSQL |
| | Vector DB | pgvector |
| | Vector Indexing | FAISS |
| **Infrastructure** | Compute | AWS EC2 |
| | Managed DB | Supabase |
| | Authentication | JWT |
| **Development** | Version Control | Git (GitHub) |
| | Package Manager | pip (Python), Pub (Flutter) |

---

## 8. Security Considerations

### 8.1 Authentication & Authorization
- JWT tokens with 24-hour expiry
- Bcrypt password hashing with salt
- Session management with token validation
- CORS protection on API endpoints

### 8.2 Data Protection
- HTTPS/TLS for all client-server communication
- Input validation and sanitization on all endpoints
- SQL injection prevention via parameterized queries
- Rate limiting to prevent abuse

### 8.3 Model & API Security
- Fine-tuned models (T5, Phi-3 Mini) run locally—no external calls (except Claude API post-defense)
- FAISS indices stored in encrypted PostgreSQL
- PDF source documents stored securely with access controls

---

## 9. Deployment Architecture

### 9.1 Deployment Topology

```
Internet
   ↓
AWS EC2 Instance (Backend)
├── FastAPI Server (Port 8000)
├── RAG Pipeline (In-Memory)
│   ├── SBERT Model
│   ├── FAISS Indices (Loaded from PostgreSQL)
│   └── T5 Model
├── Math Solver (SymPy)
└── Phi-3 Mini (Fallback)
   ↓
Supabase PostgreSQL
├── User Data
├── Quiz Attempts
├── Sessions
└── FAISS Index Metadata & pgvector Embeddings
```

### 9.2 Environment Configuration
- **Development:** Windows (PowerShell), local Python venv, mock repositories
- **Testing:** AWS EC2 staging environment
- **Production:** AWS EC2 + Supabase (post-defense deployment)

---

## 10. Quality Assurance & Testing

### 10.1 Testing Strategy

| Phase | Type | Coverage |
|---|---|---|
| **Unit Testing** | Backend API endpoints | 80%+ coverage |
| | RAG pipeline modules | 75%+ coverage |
| | Math solver functions | 90%+ coverage |
| **Integration Testing** | Frontend-Backend communication | Full API contract |
| | Database persistence | CRUD operations |
| | Fallback chain activation | Model failure scenarios |
| **System Testing** | End-to-end workflows | Ask → Solve → Quiz |
| | Performance benchmarks | Response times (NFR compliance) |
| | Security validation | Authentication, input validation |
| **User Acceptance Testing** | STEM student pilots | Usability, feedback |

---

## 11. Maintenance & Support

### 11.1 Post-Deployment
- Weekly FAISS index refresh with new PDF content
- Monthly security updates and dependency patches
- Quarterly performance optimization and model tuning
- Continuous monitoring of API response times and error rates

### 11.2 Scalability Roadmap
- **Phase 1 (Thesis):** 50–100 concurrent students
- **Phase 2 (Post-MVP):** Multi-school deployment, SM-2 spaced repetition, BM25+SBERT hybrid retrieval
- **Phase 3:** Teacher dashboards, admin analytics, learning path customization

---

## 12. Revision History

| Version | Date | Author | Changes |
|---|---|---|---|
| 1.0 | June 2026 | Kat | Initial system specification for thesis submission |
| 1.1 | 2026-06-25 | Kat | Added Implementation Status section distinguishing built vs. planned components |
| 1.2 | 2026-07-18 | Kat | Documented T5 fine-tuning pipeline status (dataset engineering, DeepMind warm-up, two-stage training); refined FR-RAG-04 to the output-sanity fallback cascade |
| 1.3 | 2026-07-19 | Kat | Answer cascade built and live at `/api/ask` (Phi-3 + T5 + Gemini free-tier escalation, `model_used`); T5 trained (two-stage) and evaluated; updated FR-RAG-04 and §6 status |

---

## Appendix A: Glossary

- **RAG:** Retrieval-Augmented Generation — combines information retrieval with language models
- **SBERT:** Sentence-BERT — semantic embeddings for similarity search
- **FAISS:** Facebook AI Similarity Search — vector database for fast similarity queries
- **T5:** Text-to-Text Transfer Transformer — fine-tuned (flan-t5-base) for mathematics Q&A
- **flan-t5:** Instruction-tuned T5 variant used as the base for fine-tuning (base on Colab T4; small as the CPU offline fallback)
- **Phi-3 Mini:** Lightweight local language model, the fallback generator in the cascade
- **LLM-as-judge:** Using a language model (local llama3) to score generated QA pairs for self-containment, grounding, and correctness before they become training data
- **DeepMind Mathematics dataset:** 100k generic symbolic-math Q&A pairs used as a Stage-A general-math warm-up before curriculum fine-tuning
- **Grouped split:** Train/val/test partition by source chunk so a chunk's context never leaks across splits
- **pgvector:** PostgreSQL extension for vector similarity search
- **JWT:** JSON Web Token — stateless authentication mechanism
- **SymPy:** Python library for symbolic mathematics

---

**Document Classification:** Thesis Submission — CONFIDENTIAL  
**Last Updated:** June 2026  
**Next Review:** Post-Defense (Recommended)
