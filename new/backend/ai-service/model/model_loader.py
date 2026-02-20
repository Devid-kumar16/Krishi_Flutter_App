import os
import logging
import tensorflow as tf
import numpy as np
from PIL import Image
import json

# ================= CONFIG =================

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_PATH = os.path.join(BASE_DIR, "..", "plant_disease_model.h5")
CLASS_FILE = os.path.join(BASE_DIR, "..", "class_names.json")

IMG_SIZE = 224
CONFIDENCE_THRESHOLD = 40  # %

logging.basicConfig(level=logging.INFO)

# ================= LOAD MODEL =================

model = None
class_names = []

try:
    if os.path.exists(MODEL_PATH):
        model = tf.keras.models.load_model(MODEL_PATH)
        logging.info("✅ Disease model loaded successfully")
    else:
        logging.warning("⚠ Model file not found")

    # Load class names dynamically
    if os.path.exists(CLASS_FILE):
        with open(CLASS_FILE, "r") as f:
            class_dict = json.load(f)
            # Convert dict to ordered list
            class_names = list(class_dict.keys())
            logging.info("✅ Class names loaded successfully")
    else:
        logging.warning("⚠ class_names.json not found")

except Exception as e:
    logging.error(f"❌ Model initialization failed: {e}")


# ================= IMAGE PREPROCESS =================

def preprocess_image(image_path):
    try:
        img = Image.open(image_path).convert("RGB")
        img = img.resize((IMG_SIZE, IMG_SIZE))
        img_array = np.array(img) / 255.0
        img_array = np.expand_dims(img_array, axis=0)
        return img_array
    except Exception as e:
        logging.error(f"❌ Image preprocessing failed: {e}")
        return None


# ================= PREDICTION =================

def predict_disease(image_path):

    if model is None:
        logging.warning("⚠ Model not loaded")
        return "Model not available", 0.0

    img = preprocess_image(image_path)

    if img is None:
        return "Invalid image", 0.0

    try:
        predictions = model.predict(img, verbose=0)

        predicted_index = int(np.argmax(predictions))
        confidence = float(np.max(predictions) * 100)

        # If class names available
        if class_names and predicted_index < len(class_names):
            disease_name = class_names[predicted_index]
        else:
            disease_name = f"Class_{predicted_index}"

        # Confidence filtering
        if confidence < CONFIDENCE_THRESHOLD:
            return "Low confidence prediction", round(confidence, 2)

        return disease_name, round(confidence, 2)

    except Exception as e:
        logging.error(f"❌ Prediction failed: {e}")
        return "Prediction error", 0.0
