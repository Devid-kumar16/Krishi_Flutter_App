import tensorflow as tf
import numpy as np
from tensorflow.keras.preprocessing import image

model = tf.keras.models.load_model("models/crop_disease_model.h5")

classes = ["Healthy", "Leaf Blight", "Powdery Mildew", "Rust"]

def predict_disease(image_path):

    img = image.load_img(image_path, target_size=(224, 224))
    img_array = image.img_to_array(img)
    img_array = np.expand_dims(img_array, axis=0) / 255.0

    predictions = model.predict(img_array)

    index = np.argmax(predictions)
    confidence = float(np.max(predictions) * 100)

    return classes[index], confidence
