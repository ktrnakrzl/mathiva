"""Fine-tuned T5 generator for the /ask answer cascade.

This loads the thesis's in-domain model (ml/t5/model/, produced by ml/t5/train.py)
and answers using the *exact* input format it was fine-tuned on. The model is now
a standalone Senior High School math tutor (see ml/t5/prepare_dataset.py's tutor
mode): it answers from the question alone -- no retrieved context. RAG still
grounds the other cascade tiers (Phi-3, Gemini); T5 is the direct tutor.

Loaded lazily on first use so importing this module (and booting the app) stays
cheap, and so a deployment WITHOUT a trained model still runs: t5_available() is
False and answer_service simply skips the T5 tier.
"""

import os

_HERE = os.path.dirname(os.path.abspath(__file__))
# backend/app/services -> backend/app -> backend -> <repo root>
_REPO_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(_HERE)))
MODEL_DIR = os.path.join(_REPO_ROOT, "ml", "t5", "model")

# Must match ml/t5/prepare_dataset.py (tutor mode) so inference sees the same
# prompt shape as training.
INSTRUCTION = "Answer the Senior High School mathematics question."
MAX_SOURCE_LENGTH = 512
MAX_NEW_TOKENS = 256

# Decoding guards. A small flan-t5 fine-tune otherwise collapses into repetition
# loops ("x2-4x = x2-4x = ..."); no_repeat_ngram_size + repetition_penalty stop
# that at generation time, so the model never emits a degenerate answer.
NO_REPEAT_NGRAM_SIZE = 3
REPETITION_PENALTY = 1.4

_model = None
_tokenizer = None


class T5ServiceError(RuntimeError):
    """Raised when the fine-tuned model is missing or fails to generate. The
    cascade treats it as 'no T5 answer' and moves on to Phi-3."""


def t5_available() -> bool:
    """True when a fine-tuned model has actually been placed at ml/t5/model/."""
    return os.path.isdir(MODEL_DIR) and os.path.exists(
        os.path.join(MODEL_DIR, "config.json")
    )


def _load():
    """Load model + tokenizer once and cache them (the 990 MB flan-t5-base load
    is ~seconds, so we pay it a single time, not per request)."""
    global _model, _tokenizer
    if _model is None:
        from transformers import AutoModelForSeq2SeqLM, AutoTokenizer

        _tokenizer = AutoTokenizer.from_pretrained(MODEL_DIR)
        _model = AutoModelForSeq2SeqLM.from_pretrained(MODEL_DIR)
        _model.eval()
    return _model, _tokenizer


def t5_generate(context: str, question: str) -> str:
    """Answer using the trained (instruction + question) format.

    `context` is accepted so the cascade can call every generator the same way,
    but the standalone-tutor model does not consume it -- it answers from the
    question alone (RAG grounds the other tiers). Greedy decoding (num_beams=1)
    keeps the live CPU path fast; the anti-repetition guards do the quality work.
    """
    if not t5_available():
        raise T5ServiceError("no fine-tuned model at ml/t5/model/")

    import torch

    model, tokenizer = _load()
    text = f"{INSTRUCTION}\nQuestion: {question}"
    enc = tokenizer(
        text, max_length=MAX_SOURCE_LENGTH, truncation=True, return_tensors="pt"
    )
    with torch.no_grad():
        out = model.generate(
            **enc,
            max_new_tokens=MAX_NEW_TOKENS,
            num_beams=1,
            no_repeat_ngram_size=NO_REPEAT_NGRAM_SIZE,
            repetition_penalty=REPETITION_PENALTY,
        )
    return tokenizer.decode(out[0], skip_special_tokens=True).strip()
