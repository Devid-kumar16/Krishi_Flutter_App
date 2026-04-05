/**
 * @swagger
 * /api/auth/signup:
 *   post:
 *     summary: Register new user
 */

const express = require("express");
const router = express.Router();
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const db = require("../config/db");

// ================= SIGNUP =================
router.post("/signup", async (req, res) => {
  try {
    const { full_name, email, password } = req.body;

    if (!full_name || !email || !password) {
      return res.status(400).json({
        success: false,
        message: "All fields required",
      });
    }

    const checkUser = "SELECT * FROM users WHERE email = ?";

    db.query(checkUser, [email], async (err, result) => {
      if (err) {
        console.error("DB ERROR:", err);
        return res.status(500).json({
          success: false,
          message: "Database error",
        });
      }

      if (result.length > 0) {
        return res.status(400).json({
          success: false,
          message: "User already exists",
        });
      }

      // 🔐 Hash password
      const hashedPassword = await bcrypt.hash(password, 10);

      const sql = `
        INSERT INTO users (full_name, email, password_hash, role_id)
        VALUES (?, ?, ?, 1)
      `;

      db.query(sql, [full_name, email, hashedPassword], (err, result) => {
        if (err) {
          console.error("INSERT ERROR:", err);
          return res.status(500).json({
            success: false,
            message: "Database error",
          });
        }

        return res.status(200).json({
          success: true,
          message: "User registered successfully",
        });
      });
    });

  } catch (error) {
    console.error("SIGNUP ERROR:", error);
    return res.status(500).json({
      success: false,
      message: "Server error",
    });
  }
});


// ================= LOGIN =================
router.post("/login", (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({
      success: false,
      message: "Email and password required",
    });
  }

  const sql = "SELECT * FROM users WHERE email = ?";

  db.query(sql, [email], async (err, result) => {
    if (err) {
      console.error("DB ERROR:", err);
      return res.status(500).json({
        success: false,
        message: "Database error",
      });
    }

    if (result.length === 0) {
      return res.status(400).json({
        success: false,
        message: "User not found",
      });
    }

    const user = result[0];

    try {
      const isMatch = await bcrypt.compare(password, user.password_hash);

      if (!isMatch) {
        return res.status(400).json({
          success: false,
          message: "Invalid password",
        });
      }

      // 🔐 JWT
      const secret = process.env.JWT_SECRET || "fallback_secret";

      const token = jwt.sign(
        { id: user.id },
        secret,
        { expiresIn: "7d" }
      );

      return res.status(200).json({
        success: true,
        message: "Login successful",
        token: token, // ✅ VERY IMPORTANT
        user: {
          id: user.id,
          name: user.full_name,
          email: user.email,
        },
      });

    } catch (error) {
      console.error("LOGIN ERROR:", error);
      return res.status(500).json({
        success: false,
        message: "Login failed",
      });
    }
  });
});

module.exports = router;