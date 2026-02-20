import logging
from transformers import AutoTokenizer, AutoModelForSeq2SeqLM
import torch

logging.basicConfig(level=logging.INFO)

MODEL_NAME = "google/flan-t5-small"

tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME)
model = AutoModelForSeq2SeqLM.from_pretrained(MODEL_NAME)


def generate_multilingual_advice(question: str):

    try:
        prompt = f"""
You are an agricultural expert.

Explain clearly in 4-5 sentences.

Farmer question: {question}

Answer:
"""

        inputs = tokenizer(
            prompt,
            return_tensors="pt",
            truncation=True,
            max_length=256
        )

        outputs = model.generate(
            **inputs,
            max_new_tokens=180,
            min_new_tokens=60,      # 🔥 force longer answer
            do_sample=True,
            temperature=0.7,
            top_p=0.9,
            repetition_penalty=1.2,
            no_repeat_ngram_size=3
        )

        answer = tokenizer.decode(outputs[0], skip_special_tokens=True)

        return {
            "answer": answer.strip(),
            "confidence": 0.9
        }

    except Exception as e:
        logging.error(f"AI Advisory Error: {e}")
        return {
            "answer": "AI advisory engine error.",
            "confidence": 0
        }

