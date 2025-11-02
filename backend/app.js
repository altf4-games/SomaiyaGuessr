const express = require("express");
const cors = require("cors");
require("dotenv").config();

const app = express();

const gameRoutes = require("./routes/gameRoutes");
const adminRoutes = require("./routes/adminRoutes");

app.use(cors());
app.use(express.json({ limit: "10mb" }));
app.use(express.urlencoded({ extended: true, limit: "10mb" }));

app.use("/api/game", gameRoutes);
app.use("/api/admin", adminRoutes);

app.get("/", (req, res) => {
  const RoomManager = require("./utils/roomManager");
  const stats = RoomManager.getStats();

  res.json({
    message: "Somaiya Guessr Backend is running!",
    status: "healthy",
    timestamp: new Date().toISOString(),
    roomStats: stats,
    endpoints: {
      game: "/api/game",
      admin: "/api/admin",
    },
  });
});

app.get("/test", (req, res) => {
  res.sendFile(__dirname + "/test.html");
});

app.use((error, req, res, next) => {
  console.error("Error:", error);
  res.status(500).json({
    error: "Something went wrong!",
    message: error.message,
  });
});

app.use("*", (req, res) => {
  res.status(404).json({ error: "Route not found" });
});

module.exports = app;
