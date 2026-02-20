from fastapi import FastAPI, File, UploadFile, HTTPException, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from datetime import datetime
import shutil
import os
import uuid
import logging

# Internal imports
from model.model_loader import predict_disease
from services.advisory_service import generate_multilingual_advice


# ================= CONFIG =================

APP_NAME = "Krishi AI Service"
MODEL_VERSION = "2.3.0"
UPLOAD_FOLDER = "uploads"

os.makedirs(UPLOAD_FOLDER, exist_ok=True)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)

# ================= APP INIT =================

app = FastAPI(
    title=APP_NAME,
    version=MODEL_VERSION,
    description="AI Powered Crop Disease Detection & Advisory Service"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Restrict in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ================= HEALTH CHECK =================

@app.get("/health")
def health_check():
    return {
        "status": "running",
        "service": APP_NAME,
        "model_version": MODEL_VERSION,
        "timestamp": datetime.utcnow().isoformat()
    }

# ================= DISEASE PREDICTION =================

@app.post("/predict")
async def predict(
    file: UploadFile = File(...),
    language: str = Form("en") 
):


    if not file.filename.lower().endswith((".jpg", ".jpeg", ".png", ".webp", ".jfif")):
        raise HTTPException(status_code=400, detail="Invalid file type")

    unique_filename = f"{uuid.uuid4()}.jpg"
    file_path = os.path.join(UPLOAD_FOLDER, unique_filename)

    try:
        # Save uploaded image
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        # Run model prediction
        disease, confidence = predict_disease(file_path)

        logging.info(f"Predicted: {disease} | Confidence: {confidence}")

        # Low confidence handling
        if confidence < 60:
            return JSONResponse({
                "status": "uncertain",
                "prediction": {
                    "disease": disease,
                    "confidence": confidence,
                    "recommendation": "Model confidence is low. Please capture a clearer image of a single leaf with good lighting."
                }
            })

        # Clean disease name for advisory generation
        clean_disease = disease.replace("___", " ").replace("_", " ")

        advisory_result = generate_multilingual_advice(
               question=clean_disease,
        )


        return JSONResponse({
            "status": "success",
            "timestamp": datetime.utcnow().isoformat(),
            "prediction": {
                "disease": disease,
                "confidence": confidence,
                "recommendation": advisory_result.get("answer", "No advisory found"),
                "advisory_confidence": advisory_result.get("confidence", 0.0),
                "language": language
            }
        })

    except Exception as e:
        logging.error(f"Prediction error: {str(e)}")
        raise HTTPException(status_code=500, detail="Prediction failed")

    finally:
        if os.path.exists(file_path):
            os.remove(file_path)

# ================= AI ADVISORY =================

class AdvisoryRequest(BaseModel):
    question: str
    language: str = "en"

@app.post("/advisory")
def advisory(request: AdvisoryRequest):

    if not request.question.strip():
        raise HTTPException(status_code=400, detail="Question cannot be empty")

    try:
        result = generate_multilingual_advice(request.question)

        return JSONResponse({
            "status": "success",
            "timestamp": datetime.utcnow().isoformat(),
            "response": result.get("answer"),
            "confidence": result.get("confidence")
        })

    except Exception as e:
        logging.error(f"Advisory error: {str(e)}")
        raise HTTPException(status_code=500, detail="Advisory failed")

