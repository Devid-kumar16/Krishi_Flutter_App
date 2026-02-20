const db = require("../config/db");

const authorizeRoles = (...allowedRoles) => {
  return async (req, res, next) => {
    try {
      const userId = req.user.id;

      const [rows] = await db.query(
        `SELECT r.role_name 
         FROM users u
         JOIN roles r ON u.role_id = r.id
         WHERE u.id = ?`,
        [userId]
      );

      if (rows.length === 0) {
        return res.status(403).json({ message: "User role not found" });
      }

      const userRole = rows[0].role_name;

      if (!allowedRoles.includes(userRole)) {
        return res.status(403).json({
          message: "Access denied: insufficient permissions",
        });
      }

      next();
    } catch (error) {
      next(error);
    }
  };
};

module.exports = authorizeRoles;
