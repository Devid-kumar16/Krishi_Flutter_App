const express = require("express");
const router = express.Router();
const multer = require("multer");
const axios = require("axios");
const db = require("../config/db");

const upload = multer({ dest: "uploads/" });

router.post("/predict", upload.single("image"), async (req, res) => {
  try {
    const { user_id, crop_name } = req.body;

    // Send image to Python AI service
    const aiResponse = await axios.post(
      process.env.AI_SERVICE_URL,
      {
        image_path: req.file.path,
        crop_name
      }
    );

    const { disease_name, confidence, advice } = aiResponse.data;

    await db.query(
      `INSERT INTO disease_reports 
       (user_id, image_path, crop_name, disease_name, confidence, advice)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [user_id, req.file.path, crop_name, disease_name, confidence, advice]
    );

    res.json({
      disease_name,
      confidence,
      advice
    });

  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "AI prediction failed" });
  }
});

module.exports = router;
