// db.js

const mysql = require("mysql2");
require("dotenv").config();

// Create MySQL connection pool
const pool = mysql.createPool({
  host: process.env.DB_HOST || "localhost",
  user: process.env.DB_USER || "root",
  password: process.env.DB_PASSWORD || "devid@2030",
  database: process.env.DB_NAME || "agri_advisor_pro",
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
});

// ✅ Test connection properly
pool.getConnection((err, connection) => {
  if (err) {
    console.error("❌ Database connection failed:", err);
  } else {
    console.log("✅ MySQL Connected Successfully");
    connection.release();
  }
});

// ✅ IMPORTANT: export NORMAL pool (not promise)
module.exports = pool;