from fastapi import FastAPI, File, UploadFile, HTTPException, Form
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import shutil
import os
import uuid
import logging
import mysql.connector

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

# ================= DATABASE =================

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

# 🔐 SIGNUP
@app.post("/api/auth/signup")
def signup(user: SignupModel):
    try:
        query = """
        INSERT INTO users (full_name, email, password_hash)
        VALUES (%s, %s, %s)
        """

        cursor.execute(query, (
            user.name,
            user.email,
            user.password
        ))

        db.commit()

        return {"success": True, "message": "Signup successful"}

    except Exception as e:
        return {"success": False, "message": str(e)}

# 🔐 LOGIN
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

# 👤 UPDATE PROFILE
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

        return {
            "success": True,
            "message": "Profile updated successfully"
        }

    except Exception as e:
        print("❌ DB ERROR:", e)
        return {"success": False, "message": str(e)}

# 👤 GET PROFILE
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

# ================= HEALTH =================

@app.get("/health")
def health():
    return {"status": "running"}