const express = require("express");
const router = express.Router();
const db = require("../config/db");
const jwt = require("jsonwebtoken");

// ================= AUTH MIDDLEWARE =================
const verifyToken = (req, res, next) => {
  const authHeader = req.headers["authorization"];

  if (!authHeader) {
    return res.status(401).json({
      success: false,
      message: "No token provided",
    });
  }

  const token = authHeader.split(" ")[1];

  jwt.verify(token, process.env.JWT_SECRET, (err, decoded) => {
    if (err) {
      return res.status(403).json({
        success: false,
        message: "Invalid token",
      });
    }

    req.user = decoded;
    next();
  });
};

// ================= UPDATE PROFILE =================
router.put("/profile", verifyToken, (req, res) => {
  const { name, email, phone } = req.body;
  const userId = req.user.id;

  console.log("📩 UPDATE DATA:", req.body);

  const sql = `
    UPDATE users 
    SET full_name = ?, email = ?, phone = ?
    WHERE id = ?
  `;

  db.query(sql, [name, email, phone, userId], (err, result) => {
    if (err) {
      console.error("❌ DB ERROR:", err);
      return res.status(500).json({
        success: false,
        message: "Database error",
      });
    }

    return res.json({
      success: true,
      message: "Profile updated successfully",
    });
  });
});

// ================= GET PROFILE =================
router.get("/profile", verifyToken, (req, res) => {
  const userId = req.user.id;

  const sql = `
    SELECT id, full_name AS name, email, phone 
    FROM users 
    WHERE id = ?
  `;

  db.query(sql, [userId], (err, result) => {
    if (err) {
      console.error(err);
      return res.status(500).json({
        success: false,
        message: "Error fetching data",
      });
    }

    if (result.length === 0) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    return res.json({
      success: true,
      user: result[0],
    });
  });
});

module.exports = router;