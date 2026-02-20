import json
import numpy as np
from sentence_transformers import SentenceTransformer
from sklearn.metrics.pairwise import cosine_similarity

# Load model
model = SentenceTransformer("all-MiniLM-L6-v2")

# Load advisory data
with open("agri_advisory_data.json", "r", encoding="utf-8") as f:
    advisory_data = json.load(f)

# Prepare question list
questions = [item["question"] for item in advisory_data]

# Generate embeddings once (very important)
question_embeddings = model.encode(questions)

def get_best_answer(user_question):
    user_embedding = model.encode([user_question])
    similarities = cosine_similarity(user_embedding, question_embeddings)
    
    best_match_index = np.argmax(similarities)
    confidence_score = similarities[0][best_match_index]

    if confidence_score < 0.4:
        return {
            "answer": "Sorry, I couldn't find a relevant advisory.",
            "confidence": float(confidence_score)
        }

    return {
        "crop": advisory_data[best_match_index]["crop"],
        "answer": advisory_data[best_match_index]["answer"],
        "confidence": float(confidence_score)
    }
