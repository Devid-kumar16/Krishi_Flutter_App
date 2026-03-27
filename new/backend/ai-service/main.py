from fastapi import FastAPI, File, UploadFile, HTTPException, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel
import shutil
import os
import uuid
import logging
import requests
from services.market_service import get_mandi_price
from model.model_loader import predict_disease
from services.advisory_service import generate_multilingual_advice

# ================= CONFIG =================

APP_NAME = "Krishi AI Service"
UPLOAD_FOLDER = "uploads"

os.makedirs(UPLOAD_FOLDER, exist_ok=True)
logging.basicConfig(level=logging.INFO)

app = FastAPI(title=APP_NAME)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ================= EXPERT FALLBACK =================

DISEASE_SOLUTIONS = {
    "Tomato Yellow Leaf Curl Virus": {
        "en": "This disease is caused by whiteflies. Spray Imidacloprid or Neem oil every 7 days. Remove infected plants and maintain field hygiene.",
        "hi": "यह रोग सफेद मक्खी से फैलता है। इमिडाक्लोप्रिड या नीम तेल का छिड़काव करें। संक्रमित पौधों को हटा दें।"
    }
}

# ================= HELPER =================

def is_bad_response(text: str, disease: str):
    if not text:
        return True

    text = text.lower()
    disease = disease.lower()

    return (
        len(text) < 25 or
        text == disease or
        disease in text and len(text.split()) < 6
    )

# ================= HEALTH =================

@app.get("/health")
def health():
    return {"status": "running"}

# ================= PREDICT =================

@app.post("/predict")
async def predict(
    file: UploadFile = File(...),
    language: str = Form("en")
):

    if not file.filename.lower().endswith((".jpg", ".jpeg", ".png", ".webp")):
        raise HTTPException(status_code=400, detail="Invalid file")

    file_path = os.path.join(UPLOAD_FOLDER, f"{uuid.uuid4()}.jpg")

    try:
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        disease, confidence = predict_disease(file_path)

        # ================= CLEAN NAME =================
        clean_disease = disease.split("___")[-1].replace("_", " ")

        # remove duplicates
        words = clean_disease.split()
        clean_disease = " ".join(dict.fromkeys(words))

        logging.info(f"{clean_disease} ({confidence}%)")

        # ================= LOW CONFIDENCE =================
        if confidence < 50:
            return {
                "status": "uncertain",
                "prediction": {
                    "disease": clean_disease,
                    "confidence": confidence,
                    "recommendation": "Low confidence. Please capture a clearer image.",
                    "language": language
                }
            }

        # ================= AI CALL =================

        question = f"{clean_disease} treatment with pesticide and prevention"

        advisory = generate_multilingual_advice(
            question=question,
            language=language
        )

        ai_text = advisory.get("answer", "").strip()

        # ================= VALIDATION =================

        if is_bad_response(ai_text, clean_disease):
            logging.warning("Bad AI response detected")

            # fallback
            if clean_disease in DISEASE_SOLUTIONS:
                recommendation = DISEASE_SOLUTIONS[clean_disease][language]
            else:
                recommendation = "No proper recommendation available. Please consult an expert."
        else:
            recommendation = ai_text

        return {
            "status": "success",
            "prediction": {
                "disease": clean_disease,
                "confidence": confidence,
                "recommendation": recommendation,
                "language": language
            }
        }

    except Exception as e:
        logging.error(str(e))
        raise HTTPException(status_code=500, detail="Prediction failed")

    finally:
        if os.path.exists(file_path):
            os.remove(file_path)

# ================= ADVISORY =================

class AdvisoryRequest(BaseModel):
    question: str
    language: str = "en"

@app.post("/advisory")
def advisory(req: AdvisoryRequest):

    if not req.question.strip():
        raise HTTPException(status_code=400, detail="Empty question")

    result = generate_multilingual_advice(
        question=req.question,
        language=req.language
    )

    return {
        "status": "success",
        "response": result["answer"],
        "confidence": result["confidence"]
    }
    
    

from services.market_service import get_mandi_price

@app.get("/market")
def market(crop: str = "Tomato"):
    try:
        result = get_mandi_price(crop)

        # ✅ Directly return service response
        return result

    except Exception as e:
        return {
            "success": False,
            "data": [],
            "error": str(e)
        }