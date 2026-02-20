const express = require("express");
const router = express.Router();
const axios = require("axios");

// ================= AI ADVISORY ROUTE =================
router.post("/", async (req, res) => {
  try {
    const { question, language = "en" } = req.body;

    // ===== VALIDATION =====
    if (!question || question.trim() === "") {
      return res.status(400).json({
        success: false,
        message: "Question is required"
      });
    }

    // ===== CONNECT TO AI SERVICE (Python FastAPI) =====
    const aiResponse = await axios.post(
      process.env.AI_SERVICE_URL,  // example: http://10.193.156.138:8000/advisory
      {
        question,
        language
      },
      {
        timeout: 15000
      }
    );

    return res.status(200).json({
      success: true,
      response: aiResponse.data.response,
      language
    });

  } catch (error) {
    console.error("AI Advisory Error:", error.message);

    return res.status(500).json({
      success: false,
      message: "AI advisory service failed"
    });
  }
});

module.exports = router;
