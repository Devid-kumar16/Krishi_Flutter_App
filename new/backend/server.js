require("dotenv").config();
const express = require("express");
const cors = require("cors");
const http = require("http");
const { Server } = require("socket.io");
const helmet = require("helmet");

const authRoutes = require("./routes/auth");
const diseaseRoutes = require("./routes/disease");
const advisoryRoutes = require("./routes/advisory");
const marketRoutes = require("./routes/market");
const profileRoutes = require("./routes/profile");

const rateLimiter = require("./middlewares/rateLimiter");
const { swaggerUi, swaggerSpec } = require("./utils/swagger");
const errorHandler = require("./middlewares/errorHandler");

const app = express();
const server = http.createServer(app);

// ================= SOCKET =================
const io = new Server(server, {
  cors: { origin: "*" },
});

// ================= MIDDLEWARE =================

// ✅ CORS FIRST
app.use(cors());

// ✅ VERY IMPORTANT (BODY PARSING - FIXES YOUR ISSUE)
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// ✅ SECURITY
app.use(helmet());

// ✅ RATE LIMIT
app.use(rateLimiter);

// ================= STATIC =================
app.use("/uploads", express.static("uploads"));

// ================= ROUTES =================
app.use("/api/auth", authRoutes);      // signup/login
app.use("/api/auth", profileRoutes);   // profile routes
app.use("/api/disease", diseaseRoutes);
app.use("/api/advisory", advisoryRoutes);
app.use("/api/market", marketRoutes);

// ================= ROOT =================
app.get("/", (req, res) => {
  res.send("Server is working 🚀");
});

// ================= SWAGGER =================
app.use("/api-docs", swaggerUi.serve, swaggerUi.setup(swaggerSpec));

// ================= SOCKET =================
io.on("connection", (socket) => {
  console.log("User connected:", socket.id);

  socket.on("disconnect", () => {
    console.log("User disconnected");
  });
});

// ================= ERROR HANDLER =================
app.use(errorHandler);

// ================= START SERVER =================
const PORT = process.env.PORT || 5000;

server.listen(PORT, "0.0.0.0", () => {
  console.log(`Server running on port ${PORT}`);
});