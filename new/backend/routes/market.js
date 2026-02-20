const express = require("express");
const router = express.Router();
const db = require("../config/db");

// GET /api/market
router.get("/", async (req, res) => {
  try {
    const crop = req.query.crop;

    let query = "SELECT * FROM market_prices";
    let values = [];

    if (crop) {
      query += " WHERE crop_name LIKE ?";
      values.push(`%${crop}%`);
    }

    const [rows] = await db.query(query, values);

    res.json(rows);

  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Market data fetch failed" });
  }
});

module.exports = router;
