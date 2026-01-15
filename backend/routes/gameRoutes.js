const express = require("express");
const router = express.Router();
const gameController = require("../controllers/gameController");

// Room management routes
router.post("/create-room", gameController.createRoom);
router.post("/join-room", gameController.joinRoom);
router.post("/leave-room", gameController.leaveRoom);
router.get("/room/:roomId", gameController.getRoomState);

// Game flow routes
router.post("/player-ready", gameController.setPlayerReady);
router.post("/start-game", gameController.startGame);
router.post("/submit-guess", gameController.submitGuess);
router.post("/time-expired", gameController.timeExpired);
router.post("/next-round", gameController.nextRound);

// Utility routes
router.get("/random-photo", gameController.getRandomPhoto);

// Debug/Admin routes
router.get("/room-stats", gameController.getRoomStats);
router.post("/cleanup-rooms", gameController.cleanupRooms);

module.exports = router;
