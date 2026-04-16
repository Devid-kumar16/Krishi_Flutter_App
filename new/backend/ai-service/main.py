import json

from fastapi import FastAPI, File, UploadFile, HTTPException, Form
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import shutil
import requests
import os
import uuid
import logging
import mysql.connector
import random
import tensorflow as tf
import numpy as np
from PIL import Image
from evaluation import evaluate_model

# ================= CONFIG =================

APP_NAME = "Krishi AI Service"
UPLOAD_FOLDER = "uploads"

os.makedirs(UPLOAD_FOLDER, exist_ok=True)

# ✅ CREATE APP FIRST (FIX)
app = FastAPI(title=APP_NAME)

# ✅ CORS (IMPORTANT FOR FLUTTER)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ================= UTIL =================

def save_prediction(true_label, predicted_label):
    try:
        with open("predictions.json", "r") as f:
            preds = json.load(f)
    except:
        preds = []

    preds.append(predicted_label)

    with open("predictions.json", "w") as f:
        json.dump(preds, f)
        
        
def get_solution(disease, lang="en"):
    solutions = {
        "Leaf Blight": {
            "en": "Use copper fungicide and avoid overwatering.",
            "hi": "कॉपर फफूंदनाशक का उपयोग करें और अधिक पानी न दें।"
        },
        "Powdery Mildew": {
            "en": "Spray sulfur-based fungicide weekly.",
            "hi": "सल्फर आधारित फफूंदनाशक का छिड़काव करें।"
        },
        "Rust Disease": {
            "en": "Apply neem oil and remove infected leaves.",
            "hi": "नीम का तेल लगाएं और संक्रमित पत्तियां हटाएं।"
        },
        "Healthy": {
            "en": "Crop is healthy. Maintain proper irrigation.",
            "hi": "फसल स्वस्थ है। उचित सिंचाई बनाए रखें।"
        }
    }

    return solutions.get(disease, solutions["Healthy"])[lang]

# ================= HEALTH =================

@app.get("/")
def home():
    return {"message": "AI Service Running ✅"}

@app.get("/health")
def health():
    return {"status": "running"}

# ================= DISEASE DETECTION =================

from fastapi import FastAPI, File, UploadFile, HTTPException
import uuid
import shutil
import os

UPLOAD_FOLDER = "uploads"
os.makedirs(UPLOAD_FOLDER, exist_ok=True)


model = tf.keras.models.load_model("plant_disease_model.h5")

with open("class_names.json") as f:
    class_names = json.load(f)


def predict_disease_from_model(image_path: str):
    try:
        print("📸 Image path:", image_path)

        img = Image.open(image_path).convert("RGB").resize((224, 224))
        img_array = np.array(img) / 255.0
        img_array = np.expand_dims(img_array, axis=0)

        predictions = model.predict(img_array)

        print("🔍 Raw Predictions:", predictions)

        confidence = float(np.max(predictions)) * 100
        index = int(np.argmax(predictions))

        print("📊 Confidence:", confidence)
        print("📌 Index:", index)

        disease = class_names.get(str(index), "Unknown")

        # 🔥 FIX: Lower threshold
        if confidence < 30:
            return "Unknown", confidence

        return disease, round(confidence, 2)

    except Exception as e:
        print("❌ MODEL ERROR:", e)
        return "Unknown", 0.0
    
    

# ================= SAVE PREDICTION =================
def save_prediction(true_label, predicted_label):
    try:
        with open("predictions.json", "r") as f:
            preds = json.load(f)
    except:
        preds = []

    preds.append(predicted_label)

    with open("predictions.json", "w") as f:
        json.dump(preds, f)
        
        
def generate_ai_advice(disease, confidence, lang="en"):

    API_URL = "https://openrouter.ai/api/v1/chat/completions"
    HEADERS = {
        "Authorization": "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",
        "Content-Type": "application/json"
    }

    if lang == "hi":
        prompt = f"""
        आप एक कृषि विशेषज्ञ हैं।

        रोग: {disease}
        विश्वास स्तर: {confidence}%

        कारण, उपचार, उर्वरक और रोकथाम सरल भाषा में बताएं।
        """
    else:
        prompt = f"""
        You are an expert agricultural advisor.

        Disease: {disease}
        Confidence: {confidence}%

        Give:
        Cause:
        Treatment:
        Fertilizer:
        Prevention:
        """

    try:
        response = requests.post(
            API_URL,
            headers=HEADERS,
            json={
                "model": "mistralai/mistral-7b-instruct",
                "messages": [
                    {"role": "user", "content": prompt}
                ]
            },
            timeout=10
        )

        data = response.json()

        text = data["choices"][0]["message"]["content"]

        return {
            "cause": text,
            "treatment": text,
            "fertilizer": text,
            "prevention": text,
            "source": "AI (OpenRouter)"
        }

    except Exception as e:
        print("OpenRouter Error:", e)

        return {
            "cause": f"{disease} detected. Please consult expert.",
            "treatment": "Apply recommended fungicide.",
            "fertilizer": "Use balanced fertilizer.",
            "prevention": "Monitor crop regularly.",
            "source": "Fallback"
        }


@app.post("/predict")
async def predict(file: UploadFile = File(...), lang: str = Form("en")):
    filename = None  # 🔥 ensure defined

    try:
        os.makedirs(UPLOAD_FOLDER, exist_ok=True)

        filename = f"{UPLOAD_FOLDER}/{uuid.uuid4()}_{file.filename}"

        # ✅ Save file
        with open(filename, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        # ✅ MODEL PREDICTION
        disease, confidence = predict_disease_from_model(filename)

        # ✅ SAVE PREDICTION
        save_prediction("unknown", disease)

        # ✅ AI ADVICE (SAFE)
        advice = generate_ai_advice(disease, confidence, lang)

        # 🔥 CRITICAL FIX: ensure advice is always dict
        if not isinstance(advice, dict):
            print("⚠ Invalid AI response, using fallback")
            advice = {
                "cause": f"{disease} detected. Please consult expert.",
                "treatment": "Apply recommended fungicide.",
                "fertilizer": "Use balanced fertilizer.",
                "prevention": "Monitor crop regularly.",
                "source": "Fallback"
            }

        # 🔥 Ensure all keys exist
        cause = advice.get("cause", "")
        treatment = advice.get("treatment", "")
        fertilizer = advice.get("fertilizer", "")
        prevention = advice.get("prevention", "")
        source = advice.get("source", "Unknown")

        # ✅ SAFE EVALUATION
        try:
            evaluation = evaluate_model()
        except Exception as eval_error:
            print("⚠ Evaluation Error:", eval_error)
            evaluation = {}

        # ✅ RESPONSE
        return {
            "disease": disease,
            "confidence": confidence,

            "cause": cause,
            "treatment": treatment,
            "fertilizer": fertilizer,
            "prevention": prevention,
            "source": source,

            "evaluation": evaluation
        }

    except Exception as e:
        print("❌ API ERROR:", e)
        raise HTTPException(status_code=500, detail=str(e))

    finally:
        # 🔥 ALWAYS DELETE FILE (VERY IMPORTANT)
        if filename and os.path.exists(filename):
            try:
                os.remove(filename)
            except Exception as cleanup_error:
                print("⚠ File cleanup error:", cleanup_error)


# ================= FALLBACK =================

def fallback_disease_solution(disease):

    if disease == "Leaf Blight":
        return """
Cause: Fungal infection due to excess moisture.

Treatment:
Use copper-based fungicide and remove infected leaves.

Fertilizer:
Apply balanced NPK fertilizer.

Prevention:
Avoid overwatering and ensure proper air circulation.
"""

    elif disease == "Powdery Mildew":
        return """
Cause: High humidity and poor airflow.

Treatment:
Spray sulfur or potassium bicarbonate fungicide.

Fertilizer:
Avoid excess nitrogen.

Prevention:
Maintain spacing and sunlight exposure.
"""

    elif disease == "Rust Disease":
        return """
Cause: Fungal spores in humid conditions.

Treatment:
Apply neem oil or fungicide regularly.

Fertilizer:
Use potassium-rich fertilizer.

Prevention:
Remove infected leaves and avoid water on leaves.
"""

    else:
        return """
Crop is healthy.

Recommendation:
Maintain proper irrigation, fertilization, and regular monitoring to prevent disease.
"""
    
    
# ================= AI ADVISORY =================

class ChatModel(BaseModel):
    message: str
    lang: str = "en"
    
    
def extract_crop(msg):
    msg = msg.lower()
    if "cotton" in msg:
        return "Cotton"
    elif "wheat" in msg:
        return "Wheat"
    elif "rice" in msg:
        return "Rice"
    return "General"


def detect_issue(msg):
    msg = msg.lower()
    if "temperature" in msg:
        return "Temperature"
    elif "water" in msg or "irrigation" in msg:
        return "Irrigation"
    elif "fertilizer" in msg:
        return "Fertilizer"
    return "General Farming"

def clean_text(text):
    # Remove prompt repetition
    text = text.replace("\n", " ").strip()

    # Remove unwanted instruction text
    if "Question:" in text:
        text = text.split("Question:")[-1]

    return text


def format_response(message, text):
    return {
        "crop": extract_crop(message),
        "issue": detect_issue(message),
        "advice": text,
        "recommendation": "Follow proper irrigation, fertilizer and crop care."
    }


def smart_fallback(message):
    crop = extract_crop(message)
    issue = detect_issue(message)

    msg = message.lower()

    # ✅ dynamic fallback (not static)
    if "temperature" in msg:
        advice = f"{crop} grows best in moderate temperature (around 20°C–30°C). Avoid extreme heat or cold."
    elif "water" in msg or "irrigation" in msg:
        advice = f"{crop} requires regular irrigation. Maintain proper soil moisture but avoid waterlogging."
    elif "fertilizer" in msg:
        advice = f"Use balanced fertilizers (NPK) for {crop}. Apply nitrogen and potash during growth stages."
    else:
        advice = f"For {crop}, use good quality seeds, proper spacing, balanced fertilizer, and regular irrigation."

    return {
        "crop": crop,
        "issue": issue,
        "advice": advice,
        "recommendation": "Follow local agricultural guidelines and monitor crop regularly."
    }
    
    
    
def smart_fallback(message, lang="en"):
    msg = message.lower()

    if "cotton" in msg or "कपास" in msg:
        crop = "कपास" if lang == "hi" else "Cotton"
    elif "wheat" in msg or "गेहूं" in msg:
        crop = "गेहूं" if lang == "hi" else "Wheat"
    elif "rice" in msg or "धान" in msg:
        crop = "धान" if lang == "hi" else "Rice"
    else:
        crop = "फसल" if lang == "hi" else "Crop"

    issue = "सामान्य खेती" if lang == "hi" else "General Farming"

    if lang == "hi":
        advice = f"{crop} के लिए 20°C से 30°C तापमान उपयुक्त होता है। संतुलित खाद और नियमित सिंचाई करें।"
        recommendation = "स्थानीय कृषि विशेषज्ञ की सलाह लें और फसल की नियमित निगरानी करें।"
    else:
        advice = f"{crop} grows best at 20°C–30°C. Use balanced fertilizers and regular irrigation."
        recommendation = "Follow local agricultural guidelines and monitor crops regularly."

    return {
        "crop": crop,
        "issue": issue,
        "advice": advice,
        "recommendation": recommendation
    }
    
def normalize_text(text):
    text = text.lower()

    # Remove punctuation
    for ch in [",", ".", "?", "!", ":", ";"]:
        text = text.replace(ch, "")

    # Normalize Hindi words (VERY IMPORTANT)
    replacements = {
        "उगाना": "उग",
        "उगाए": "उग",
        "उगाएं": "उग",
        "खेती": "उग",
        "बुवाई": "उग",
        "खाद": "fertilizer",
        "उर्वरक": "fertilizer",
        "सिंचाई": "irrigation",
        "पानी": "irrigation",
        "तापमान": "temperature",
        "बीज": "seed",
        "उपज": "yield",
        "उत्पादन": "yield"
    }

    for k, v in replacements.items():
        text = text.replace(k, v)

    return text   



@app.get("/evaluation")
def get_evaluation():
    return evaluate_model()


@app.post("/chat")
def chat(data: ChatModel):

    import requests

    API_KEY = "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"
    url = "https://openrouter.ai/api/v1/chat/completions"

    message = data.message.strip()

    # 🌍 Language detect
    lang = "hi" if any("\u0900" <= c <= "\u097F" for c in message) else "en"

    # 🧠 Prompt
    if lang == "hi":
        system_prompt = f"""
आप एक अनुभवी भारतीय कृषि विशेषज्ञ हैं।

नियम:
- हमेशा शुद्ध और सरल हिंदी में उत्तर दें
- अंग्रेज़ी का उपयोग न करें
- किसान के लिए आसान भाषा में समझाएं
- केवल पूछे गए प्रश्न का ही उत्तर दें

उत्तर का प्रारूप:
1. सीधा उत्तर
2. कारण
3. सुझाव

प्रश्न: {message}
"""
        user_message = f"कृपया हिंदी में उत्तर दें: {message}"

    else:
        system_prompt = f"""
You are an Indian agriculture expert.

RULES:
- Answer ONLY in English
- Do NOT mix Hindi
- Be simple and farmer-friendly
- Answer only what is asked

If question is about temperature:
- Include exact °C range

Question: {message}
"""
        user_message = message

    payload = {
        "model": "openrouter/auto",   # ✅ MOST STABLE (no 404)
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_message}
        ],
        "temperature": 0.2
    }

    try:
        response = requests.post(
            url,
            headers={
                "Authorization": f"Bearer {API_KEY}",
                "Content-Type": "application/json",
                "HTTP-Referer": "http://localhost",
                "X-Title": "Agri Advisor App"
            },
            json=payload,
            timeout=20
        )

        print("🔍 RAW:", response.text)

        result = response.json()

        # ✅ Safe parsing
        if "choices" in result and len(result["choices"]) > 0:
            reply = result["choices"][0]["message"]["content"]
            return {"reply": reply.strip()}

        print("⚠ Error:", result)

    except Exception as e:
        print("⚠ API Failed:", e)

    return {
        "reply": "⚠ Unable to fetch answer. Please try again."
    }
    

# ================= DATABASE =================

logging.basicConfig(level=logging.INFO)

db = mysql.connector.connect(
    host="localhost",
    user="root",
    password="devid@2030",
    database="agri_advisor_pro"
)

cursor = db.cursor(dictionary=True)

# ================= MODELS =================

class SignupModel(BaseModel):
    name: str
    email: str
    password: str

class LoginModel(BaseModel):
    email: str
    password: str

# ================= AUTH =================

@app.post("/api/auth/signup")
def signup(user: SignupModel):
    try:
        query = """
        INSERT INTO users (full_name, email, password_hash)
        VALUES (%s, %s, %s)
        """

        cursor.execute(query, (user.name, user.email, user.password))
        db.commit()

        return {"success": True, "message": "Signup successful"}

    except Exception as e:
        return {"success": False, "message": str(e)}

@app.post("/api/auth/login")
def login(user: LoginModel):

    query = "SELECT * FROM users WHERE email=%s"
    cursor.execute(query, (user.email,))
    db_user = cursor.fetchone()

    if not db_user:
        return {"success": False, "message": "User not found"}

    if db_user["password_hash"] != user.password:
        return {"success": False, "message": "Wrong password"}

    return {
        "success": True,
        "message": "Login successful",
        "token": "dummy-token",
        "user": {
            "id": db_user["id"],
            "name": db_user["full_name"],
            "email": db_user["email"]
        }
    }

@app.put("/api/auth/profile")
def update_profile(data: dict):
    try:
        query = """
        UPDATE users SET 
        full_name=%s,
        phone=%s
        WHERE email=%s
        """

        cursor.execute(query, (
            data.get("name"),
            data.get("phone"),
            data.get("email"),
        ))

        db.commit()

        return {"success": True, "message": "Profile updated successfully"}

    except Exception as e:
        return {"success": False, "message": str(e)}

@app.get("/api/auth/profile")
def get_profile(email: str):

    query = "SELECT id, full_name, email, phone FROM users WHERE email=%s"
    cursor.execute(query, (email,))
    user = cursor.fetchone()

    if not user:
        return {"success": False, "message": "User not found"}

    return {
        "success": True,
        "user": {
            "id": user["id"],
            "name": user["full_name"],
            "email": user["email"],
            "phone": user["phone"]
        }
    }