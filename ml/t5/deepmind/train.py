"""Phase 2 of the T5 fine-tune: train flan-t5 on the RAG-augmented dataset.

Phase 1 (`prepare_dataset.py`) already produced ml/t5/data/{train,val,test}.jsonl,
where each row is

    input  = "<instruction>\nContext: <top-3 retrieved chunks>\nQuestion: <q>"
    target = "<reference answer>"

so the model learns *exactly* the inference task: read the retrieved context and
answer. This script only fine-tunes; it does not touch the split (the grouped,
no-leakage split was fixed in Phase 1).

Choices worth defending at review:

- **flan-t5-base, fp32.** flan-t5 is numerically unstable in fp16 (nan logits),
  and the dataset is tiny, so fp32 costs us nothing meaningful in wall time while
  avoiding silent NaN collapse. Pass --model_name google/flan-t5-small to train
  the CPU-friendly offline fallback with no other changes.

- **Overfitting is the real risk, not undertraining.** There are only ~298 train
  examples from ~125 source chunks. So we evaluate every epoch on val, keep the
  best-val checkpoint, and stop early once val loss stops improving instead of
  running a fixed large number of epochs.

- **Fast tokenizer, no sentencepiece.** flan-t5 ships tokenizer.json, so
  AutoTokenizer loads the fast tokenizer and sentencepiece is not required for
  training or inference.

Meant to run on Colab (free T4 GPU) via train_flan_t5.ipynb, but the same command
runs locally on CPU for flan-t5-small. Example:

    python ml/t5/train.py                       # flan-t5-base, defaults
    python ml/t5/train.py --model_name google/flan-t5-small --batch_size 8
"""

import argparse
import os

HERE = os.path.dirname(os.path.abspath(__file__))          # ml/t5

# Match Phase 1: 512-token input budget (instruction + top-3 chunks + question),
# 256-token targets (answers average ~38 words, so 256 leaves generous headroom).
MAX_SOURCE_LENGTH = 512
MAX_TARGET_LENGTH = 256


def parse_args():
    p = argparse.ArgumentParser(description="Fine-tune flan-t5 for MATHIVA /ask.")
    p.add_argument("--model_name", default="google/flan-t5-base",
                   help="HF model id. Use google/flan-t5-small for a CPU-only run.")
    p.add_argument("--data_dir", default=os.path.join(HERE, "data"),
                   help="Directory holding train.jsonl / val.jsonl.")
    p.add_argument("--out_dir", default=os.path.join(HERE, "model"),
                   help="Where to save the best fine-tuned model + tokenizer.")
    p.add_argument("--epochs", type=int, default=20,
                   help="Upper bound; early stopping usually halts well before this.")
    p.add_argument("--batch_size", type=int, default=4)
    p.add_argument("--lr", type=float, default=3e-4)
    p.add_argument("--patience", type=int, default=3,
                   help="Stop after this many epochs without val-loss improvement.")
    p.add_argument("--seed", type=int, default=42)
    return p.parse_args()


def main():
    args = parse_args()

    # Imported here (not at module top) so that `--help` and argument errors work
    # even in an environment where the heavy training deps aren't installed yet.
    from datasets import load_dataset
    from transformers import (
        AutoModelForSeq2SeqLM,
        AutoTokenizer,
        DataCollatorForSeq2Seq,
        EarlyStoppingCallback,
        Seq2SeqTrainer,
        Seq2SeqTrainingArguments,
        set_seed,
    )

    set_seed(args.seed)

    data_files = {
        "train": os.path.join(args.data_dir, "train.jsonl"),
        "validation": os.path.join(args.data_dir, "val.jsonl"),
    }
    raw = load_dataset("json", data_files=data_files)

    tokenizer = AutoTokenizer.from_pretrained(args.model_name)      # fast tokenizer
    model = AutoModelForSeq2SeqLM.from_pretrained(args.model_name)

    def tokenize(batch):
        model_inputs = tokenizer(
            batch["input"],
            max_length=MAX_SOURCE_LENGTH,
            truncation=True,
        )
        labels = tokenizer(
            text_target=batch["target"],
            max_length=MAX_TARGET_LENGTH,
            truncation=True,
        )
        model_inputs["labels"] = labels["input_ids"]
        return model_inputs

    # Drop the raw columns so only model_inputs/labels reach the collator.
    tokenized = raw.map(tokenize, batched=True, remove_columns=raw["train"].column_names)

    # Pads inputs and pads labels with -100 so padding tokens are ignored by loss.
    collator = DataCollatorForSeq2Seq(tokenizer, model=model)

    training_args = Seq2SeqTrainingArguments(
        output_dir=args.out_dir,
        num_train_epochs=args.epochs,
        learning_rate=args.lr,
        per_device_train_batch_size=args.batch_size,
        per_device_eval_batch_size=args.batch_size,
        warmup_ratio=0.1,
        weight_decay=0.01,
        eval_strategy="epoch",
        save_strategy="epoch",
        save_total_limit=1,              # only the best checkpoint is worth keeping
        load_best_model_at_end=True,
        metric_for_best_model="eval_loss",
        greater_is_better=False,
        logging_steps=10,
        fp16=False,                      # flan-t5 fp16 -> NaN; keep fp32 (see header)
        report_to="none",
        seed=args.seed,
    )

    trainer = Seq2SeqTrainer(
        model=model,
        args=training_args,
        train_dataset=tokenized["train"],
        eval_dataset=tokenized["validation"],
        data_collator=collator,
        callbacks=[EarlyStoppingCallback(early_stopping_patience=args.patience)],
    )

    trainer.train()

    # Persist the best-val model (load_best_model_at_end restored it) + tokenizer,
    # so ml/t5/model/ is a self-contained folder eval.py / the backend can load.
    os.makedirs(args.out_dir, exist_ok=True)
    trainer.save_model(args.out_dir)
    tokenizer.save_pretrained(args.out_dir)
    print(f"\nSaved fine-tuned model + tokenizer to: {args.out_dir}")


if __name__ == "__main__":
    main()
