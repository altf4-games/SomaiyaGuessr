const express = require("express");
const router = express.Router();
const gameController = require("../controllers/gameController");

// Game routes
router.post("/create-room", gameController.createRoom);
router.post("/join-room", gameController.joinRoom);
router.get("/random-photo", gameController.getRandomPhoto);
router.post("/submit-guess", gameController.submitGuess);
router.post("/next-round", gameController.nextRound);

// Debug/Admin routes
router.get("/room-stats", gameController.getRoomStats);
router.post("/cleanup-rooms", gameController.cleanupRooms);

module.exports = router;
