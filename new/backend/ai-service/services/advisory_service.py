import logging
from transformers import AutoTokenizer, AutoModelForSeq2SeqLM
import torch

# ================= CONFIG =================

logging.basicConfig(level=logging.INFO)

MODEL_NAME = "google/flan-t5-small"
device = "cuda" if torch.cuda.is_available() else "cpu"

# ================= LOAD MODEL =================

logging.info("Loading advisory model...")

tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME)
model = AutoModelForSeq2SeqLM.from_pretrained(MODEL_NAME).to(device)

logging.info("Advisory model loaded successfully!")

# ================= HELPER =================

def is_bad_response(text: str, disease: str):
    text = text.lower()
    disease = disease.lower()

    return (
        len(text) < 40 or
        text.startswith(disease) or
        text == disease
    )


def clean_ai_output(text: str):
    text = text.replace("\n", " ").strip()

    # remove repeated words
    words = text.split()
    text = " ".join(dict.fromkeys(words))

    # keep it simple (do NOT remove too much)
    return text.strip()


# ================= FALLBACK =================

def generate_fallback(disease: str):
    return f"""
For {disease}, use pesticides like Imidacloprid or Mancozeb.

Mix 0.3–2g per liter water and spray on leaves every 5–7 days.

Remove infected leaves and maintain proper field hygiene.
"""


# ================= FUNCTION =================

def generate_multilingual_advice(question: str, language: str = "en"):
    try:

        # ================= STRONG PROMPT (WITH EXAMPLE) =================

        prompt = f"""
You are an expert agricultural advisor.

Example:
Disease: Tomato Yellow Leaf Curl Virus
Answer:
Cause: Whitefly infestation.
Treatment: Spray Imidacloprid 0.3 ml per liter water every 5 days.
Application: Spray on both sides of leaves.
Prevention: Remove infected plants and control whiteflies.

Now give similar answer.

Disease: {question}

Answer:
"""

        # ================= TOKENIZE =================

        inputs = tokenizer(
            prompt,
            return_tensors="pt",
            truncation=True,
            max_length=256
        ).to(device)

        # ================= GENERATE =================

        outputs = model.generate(
            **inputs,
            max_new_tokens=200,
            temperature=0.9,
            top_p=0.95,
            repetition_penalty=2.0,
            no_repeat_ngram_size=3,
        )

        answer = tokenizer.decode(outputs[0], skip_special_tokens=True).strip()

        # ================= VALIDATION =================

        if is_bad_response(answer, question):
            logging.warning("AI weak → retrying")

            retry_prompt = f"""
Give proper pesticide treatment for {question}.
Mention chemical name, dosage, and spray method.
"""

            inputs = tokenizer(
                retry_prompt,
                return_tensors="pt",
                truncation=True,
                max_length=256
            ).to(device)

            outputs = model.generate(
                **inputs,
                max_new_tokens=150,
                temperature=0.9,
                repetition_penalty=2.2
            )

            answer = tokenizer.decode(outputs[0], skip_special_tokens=True).strip()

        # ================= FINAL FALLBACK =================

        if is_bad_response(answer, question):
            logging.warning("Fallback used")
            answer = generate_fallback(question)

        # ================= CLEAN =================

        answer = clean_ai_output(answer)

        return {
            "answer": answer,
            "confidence": 0.9
        }

    except Exception as e:
        logging.error(f"AI Advisory Error: {e}")
        return {
            "answer": "",
            "confidence": 0.0
        }