"""Phase 3 of the T5 fine-tune: evaluate T5 against Phi-3 on the held-out test set.

This comparison is the thesis contribution. Both models answer the *same* Grade-11
General-Mathematics test questions using the *same* retrieved context (baked into
each test row's `input` during Phase 1), and both are scored against the same gold
answer. The question we are really answering: does the fine-tuned T5 match or beat
the general-purpose Phi-3 on this narrow, in-domain task?

Runs locally:
  - T5 inference is done here on CPU (only 36 test examples, so seconds to a minute).
  - Phi-3 answers reuse the live backend path (`app.services.ai_service.generate_answer`
    -> Ollama), so the Phi-3 we measure is exactly the one students hit today.

Metrics: ROUGE-L, BLEU (sacrebleu), BERTScore. Interpretation caveat worth stating
in the writeup: on short, free-form math answers, surface-overlap metrics
(BLEU/ROUGE) are noisy -- two correct answers can be worded very differently.
BERTScore (semantic) is the more meaningful signal here. The T5-vs-Phi-3 spread
also informs Phase 4: if T5's answers are competitive, the planned cascade's cheap
"is this output degenerate/empty?" guards are enough; if T5 is much worse, the
guards need to be stricter.

Prereqs: ml/t5/model/ exists (download + unzip the Colab-trained model there) and
Ollama is running the `phi` model. Then:  python ml/t5/eval.py
Outputs: ml/t5/eval_report.json  + a printed comparison table.
"""

import argparse
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))          # ml/t5
REPO_ROOT = os.path.dirname(os.path.dirname(HERE))         # A:/mathiva

# Reuse the exact Phi-3 path the live /ask endpoint uses. ai_service only depends
# on `requests`, and app/ has no __init__.py (implicit namespace package), so this
# import pulls in the Ollama client without booting the FastAPI app.
sys.path.insert(0, os.path.join(REPO_ROOT, "backend"))
from app.services.ai_service import generate_answer, AIServiceError  # noqa: E402

MAX_TARGET_LENGTH = 256


def parse_args():
    p = argparse.ArgumentParser(description="Evaluate fine-tuned T5 vs Phi-3.")
    p.add_argument("--model_dir", default=os.path.join(HERE, "model"),
                   help="Directory with the fine-tuned T5 (from Colab).")
    p.add_argument("--test_file", default=os.path.join(HERE, "data", "test.jsonl"))
    p.add_argument("--out_file", default=os.path.join(HERE, "eval_report.json"))
    p.add_argument("--num_beams", type=int, default=4)
    p.add_argument("--bertscore_model", default="roberta-large",
                   help="Swap to e.g. distilbert-base-uncased if roberta-large is "
                        "too heavy to download locally.")
    p.add_argument("--skip_phi", action="store_true",
                   help="Score only T5 (e.g. when Ollama isn't running).")
    return p.parse_args()


def read_jsonl(path):
    with open(path, "r", encoding="utf-8") as f:
        return [json.loads(line) for line in f if line.strip()]


def split_context_question(t5_input):
    """Recover (context, question) from a Phase-1 `input` string.

    Phase 1 built it as "<instruction>\nContext: <context>\nQuestion: <q>", so we
    peel the question off the last "Question:" and the context off "Context:".
    We rebuild a Phi-3 prompt from these so Phi-3 sees the *same* context+question
    as T5 -- an apples-to-apples comparison, not Phi-3's slightly different live
    tutor prompt.
    """
    context, question = "", t5_input
    if "Question:" in t5_input:
        head, question = t5_input.rsplit("Question:", 1)
        if "Context:" in head:
            context = head.split("Context:", 1)[1]
    return context.strip(), question.strip()


def phi_prompt(context, question):
    """A tutor prompt mirroring backend/app/api/ask.py, on shared context."""
    return (
        "You are Mathiva, a helpful math tutor.\n\n"
        "Use the following course material to answer the student's question.\n\n"
        f"Course Material:\n{context}\n\n"
        f"Student Question:\n{question}\n\n"
        "Instructions:\n"
        "- Answer clearly and concisely.\n"
        "- Do not repeat the course material.\n"
        "- Do not repeat these instructions.\n\n"
        "Answer:"
    )


def generate_t5_answers(model_dir, inputs, num_beams):
    import torch
    from transformers import AutoModelForSeq2SeqLM, AutoTokenizer

    tokenizer = AutoTokenizer.from_pretrained(model_dir)
    model = AutoModelForSeq2SeqLM.from_pretrained(model_dir)
    model.eval()

    answers = []
    for text in inputs:
        enc = tokenizer(text, max_length=512, truncation=True, return_tensors="pt")
        with torch.no_grad():
            out = model.generate(
                **enc,
                num_beams=num_beams,
                max_new_tokens=MAX_TARGET_LENGTH,
            )
        answers.append(tokenizer.decode(out[0], skip_special_tokens=True).strip())
    return answers


def score(predictions, references, bertscore_model):
    """Return {rougeL, bleu, bertscore_f1} aggregated over the set."""
    from rouge_score import rouge_scorer
    import sacrebleu
    from bert_score import score as bert_score

    scorer = rouge_scorer.RougeScorer(["rougeL"], use_stemmer=True)
    rouge_l = sum(
        scorer.score(ref, pred)["rougeL"].fmeasure
        for pred, ref in zip(predictions, references)
    ) / len(predictions)

    # sacrebleu expects a list of reference-lists (one per prediction slot).
    bleu = sacrebleu.corpus_bleu(predictions, [references]).score

    _, _, f1 = bert_score(
        predictions, references, model_type=bertscore_model, verbose=False,
    )
    bertscore_f1 = float(f1.mean())

    return {
        "rougeL": round(rouge_l, 4),
        "bleu": round(bleu, 4),
        "bertscore_f1": round(bertscore_f1, 4),
    }


def main():
    args = parse_args()
    rows = read_jsonl(args.test_file)
    references = [r["target"] for r in rows]
    t5_inputs = [r["input"] for r in rows]

    print(f"Generating T5 answers for {len(rows)} test examples...")
    t5_answers = generate_t5_answers(args.model_dir, t5_inputs, args.num_beams)

    phi_answers = None
    if not args.skip_phi:
        print("Generating Phi-3 answers (via Ollama) on the same context...")
        phi_answers = []
        for text in t5_inputs:
            context, question = split_context_question(text)
            try:
                phi_answers.append(generate_answer(phi_prompt(context, question)).strip())
            except AIServiceError as e:
                print(f"  Phi-3 unavailable ({e}); rerun with Ollama up or --skip_phi.")
                return

    print("Scoring...")
    report = {
        "test_examples": len(rows),
        "t5": {
            "model_dir": args.model_dir,
            "metrics": score(t5_answers, references, args.bertscore_model),
        },
        "per_example": [
            {
                "question": r["question"],
                "reference": r["target"],
                "t5": t5_answers[i],
                **({"phi": phi_answers[i]} if phi_answers else {}),
            }
            for i, r in enumerate(rows)
        ],
    }
    if phi_answers:
        report["phi"] = {
            "model": "phi (Ollama)",
            "metrics": score(phi_answers, references, args.bertscore_model),
        }

    with open(args.out_file, "w", encoding="utf-8") as f:
        json.dump(report, f, indent=2, ensure_ascii=False)

    # Comparison table.
    print("\n" + "=" * 48)
    print(f"{'metric':<16}{'T5':>10}{'Phi-3':>12}")
    print("-" * 48)
    for m in ("rougeL", "bleu", "bertscore_f1"):
        t5_v = report["t5"]["metrics"][m]
        phi_v = report["phi"]["metrics"][m] if phi_answers else "-"
        phi_str = f"{phi_v:>12}" if isinstance(phi_v, str) else f"{phi_v:>12.4f}"
        print(f"{m:<16}{t5_v:>10.4f}{phi_str}")
    print("=" * 48)
    print(f"\nWrote {args.out_file}")


if __name__ == "__main__":
    main()
