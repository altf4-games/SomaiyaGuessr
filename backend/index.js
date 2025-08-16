const app = require("./app");
const { connectDB } = require("./db/connection");
const socketHandler = require("./controllers/socketController");

require("dotenv").config();

const PORT = process.env.PORT || 3000;

// Connect to database
connectDB();

// Create HTTP server
const server = require("http").createServer(app);

// Initialize Socket.io
const io = require("socket.io")(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"],
  },
});

// Handle socket connections
socketHandler(io);

server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Test your endpoints at http://localhost:${PORT}`);
});
