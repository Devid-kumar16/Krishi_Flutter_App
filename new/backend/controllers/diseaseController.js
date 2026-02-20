const db = require("../config/db");
const { callAIService } = require("../services/aiService");

exports.detectDisease = async (req, res, next) => {
  const connection = await db.getConnection();

  try {
    await connection.beginTransaction();

    if (!req.file) {
      return res.status(400).json({ message: "Image is required" });
    }

    const userId = req.user.id;
    const { crop_id } = req.body;
    const imagePath = req.file.path;

    if (!crop_id) {
      return res.status(400).json({ message: "Crop ID is required" });
    }

    // 1️⃣ Call AI
    const { disease, confidence, recommendation } =
      await callAIService(imagePath);

    // 2️⃣ Fetch disease_id
    const [diseaseRows] = await connection.query(
      "SELECT id FROM diseases WHERE disease_name = ? AND crop_id = ?",
      [disease, crop_id]
    );

    if (diseaseRows.length === 0) {
      throw new Error("Disease not found for selected crop");
    }

    const diseaseId = diseaseRows[0].id;

    // 3️⃣ Fetch active ML model
    const [modelRows] = await connection.query(
      "SELECT id FROM ml_models WHERE is_active = TRUE LIMIT 1"
    );

    if (modelRows.length === 0) {
      throw new Error("No active ML model found");
    }

    const modelId = modelRows[0].id;

    // 4️⃣ Insert detection
    await connection.query(
      `INSERT INTO disease_detections
      (user_id, crop_id, disease_id, model_id, image_path, confidence_score, recommendation)
      VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [
        userId,
        crop_id,
        diseaseId,
        modelId,
        imagePath,
        confidence,
        recommendation,
      ]
    );

    await connection.commit();

    res.status(200).json({
      message: "Disease detected successfully",
      disease,
      confidence,
      recommendation,
    });

  } catch (error) {
    await connection.rollback();
    console.error("Detection Transaction Failed:", error);
    next(error);
  } finally {
    connection.release();
  }
};


exports.getDetectionHistory = async (req, res, next) => {
  try {
    const userId = req.user.id;

    const [rows] = await db.query(
      `SELECT 
          dd.id,
          c.crop_name,
          d.disease_name,
          dd.confidence_score,
          dd.image_path,
          dd.detection_time
       FROM disease_detections dd
       JOIN crops c ON dd.crop_id = c.id
       JOIN diseases d ON dd.disease_id = d.id
       WHERE dd.user_id = ?
       ORDER BY dd.detection_time DESC`,
      [userId]
    );

    res.json(rows);
  } catch (error) {
    next(error);
  }
};

