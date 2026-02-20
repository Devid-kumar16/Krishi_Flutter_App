const express = require("express");
const router = express.Router();
const authMiddleware = require("../middlewares/authMiddleware");
const authorizeRoles = require("../middlewares/roleMiddleware");

router.post(
  "/create",
  authMiddleware,
  authorizeRoles("admin"),
  (req, res) => {
    res.json({ message: "ML model created (admin only)" });
  }
);

module.exports = router;
