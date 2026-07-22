# syntax=docker/dockerfile:1
#
# MATHIVA backend (FastAPI + RAG). The Flutter app is built separately.
# Ollama is NOT bundled: in a hosted deployment the /ask cascade falls back to
# Google Gemini, so run this image with DISABLE_T5=true and a GEMINI_API_KEY
# (see DEPLOY.md). Build context is the repo root because the backend imports
# the RAG + solver packages from ml/.

FROM python:3.12-slim

# System libraries needed at runtime by opencv (pulled in by pix2tex).
RUN apt-get update && apt-get install -y --no-install-recommends \
        libgl1 \
        libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    HF_HUB_DISABLE_TELEMETRY=1 \
    HF_HUB_DISABLE_SYMLINKS_WARNING=1

WORKDIR /app

# Install CPU-only PyTorch FIRST. The default PyPI wheel bundles CUDA (~2 GB+),
# which a Gemini/CPU deployment never uses; the CPU wheel keeps the image small.
# sentence-transformers / transformers then reuse this already-installed torch.
RUN pip install torch==2.12.1 --index-url https://download.pytorch.org/whl/cpu

# Python dependencies (cache this layer unless requirements change).
COPY backend/requirements.txt ./requirements.txt
RUN pip install -r requirements.txt

# Application code. app/main.py adds ../../ml to sys.path, so the retrieval (RAG)
# and solver packages -- including the prebuilt FAISS index + chunks that live in
# ml/retrieval -- must be present under /app/ml. ml/t5 (the ~1 GB model) is
# intentionally NOT copied: the T5 tier is disabled in this deployment.
COPY backend/ ./backend/
COPY ml/retrieval/ ./ml/retrieval/
COPY ml/solver/ ./ml/solver/

# Bake the SBERT embedding model into the image so the first /ask request doesn't
# stall on a ~90 MB download at runtime.
RUN python -c "from sentence_transformers import SentenceTransformer; SentenceTransformer('all-MiniLM-L6-v2')"

WORKDIR /app/backend
EXPOSE 8000

# Apply DB migrations (set RUN_MIGRATIONS=0 to skip), then start the server.
# All secrets/config (DATABASE_URL, JWT_SECRET, GEMINI_API_KEY, ENVIRONMENT,
# DISABLE_T5) are supplied via the environment at runtime -- never baked in.
CMD ["sh", "-c", "if [ \"${RUN_MIGRATIONS:-1}\" = \"1\" ]; then alembic upgrade head; fi && exec uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
