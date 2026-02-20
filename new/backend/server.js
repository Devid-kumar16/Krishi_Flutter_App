require("dotenv").config();
const express = require("express");
const cors = require("cors");
const http = require("http");
const { Server } = require("socket.io");
const helmet = require("helmet");

const authRoutes = require("./routes/auth");
const diseaseRoutes = require("./routes/disease");
const advisoryRoutes = require("./routes/advisory");
const rateLimiter = require("./middlewares/rateLimiter");
const { swaggerUi, swaggerSpec } = require("./utils/swagger");
const marketRoutes = require("./routes/market");

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: "*" },
});

app.use(cors());
app.use(express.json());
app.use(helmet());
app.use(rateLimiter);

app.use("/uploads", express.static("uploads"));

app.use("/api/auth", authRoutes);
app.use("/api/disease", diseaseRoutes);
app.use("/api/advisory", advisoryRoutes);
app.use("/api/market", marketRoutes);

app.use("/api-docs", swaggerUi.serve, swaggerUi.setup(swaggerSpec));

// WebSocket connection
io.on("connection", (socket) => {
  console.log("User connected:", socket.id);

  socket.on("disconnect", () => {
    console.log("User disconnected");
  });
});

server.listen(process.env.PORT, "0.0.0.0", () => {
  console.log("Server running on port " + process.env.PORT);
});

const errorHandler = require("./middlewares/errorHandler");
app.use(errorHandler);

