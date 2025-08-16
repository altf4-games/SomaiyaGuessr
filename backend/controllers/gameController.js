const RoomManager = require("../utils/roomManager");
const Photo = require("../models/Photo");
const { v4: uuidv4 } = require("uuid");

// Create a new room
exports.createRoom = async (req, res) => {
  try {
    const roomId = uuidv4().slice(0, 6).toUpperCase();

    const room = await RoomManager.createRoom(roomId);

    res.json({
      roomId: room.roomId,
      currentRound: room.currentRound,
      totalRounds: room.totalRounds,
      photo: {
        imageUrl: room.currentPhoto.imageUrl,
        location: room.currentPhoto.location,
        difficulty: room.currentPhoto.difficulty,
      },
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Join existing room
exports.joinRoom = async (req, res) => {
  try {
    const { roomId } = req.body;

    const room = RoomManager.getRoom(roomId);

    if (!room) {
      return res.status(404).json({ error: "Room not found" });
    }

    const playersArray = Array.from(room.players.values()).map((p) => ({
      name: p.name,
      score: p.score,
    }));

    res.json({
      roomId: room.roomId,
      currentRound: room.currentRound,
      totalRounds: room.totalRounds,
      gameState: room.gameState,
      photo: room.currentPhoto
        ? {
            imageUrl: room.currentPhoto.imageUrl,
            location: room.currentPhoto.location,
            difficulty: room.currentPhoto.difficulty,
          }
        : null,
      players: playersArray,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Get random photo
exports.getRandomPhoto = async (req, res) => {
  try {
    const photos = await Photo.find();

    if (photos.length === 0) {
      return res.status(404).json({ error: "No photos available" });
    }

    const randomPhoto = photos[Math.floor(Math.random() * photos.length)];

    res.json({
      photo: {
        imageUrl: randomPhoto.imageUrl,
        location: randomPhoto.location,
        difficulty: randomPhoto.difficulty,
      },
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Submit guess and calculate score
exports.submitGuess = async (req, res) => {
  try {
    const { roomId, guessX, guessY, playerName } = req.body;

    const room = RoomManager.getRoom(roomId);
    if (!room) {
      return res.status(404).json({ error: "Room not found" });
    }

    const photo = room.currentPhoto;
    const distance = calculateDistance(
      guessX,
      guessY,
      photo.coordX,
      photo.coordY
    );
    const points = calculatePoints(distance);

    // Add player if doesn't exist and update score
    RoomManager.addPlayerToRoom(roomId, null, playerName);
    const updatedPlayer = RoomManager.updatePlayerScore(roomId, playerName, {
      guessX,
      guessY,
      distance,
      points,
    });

    res.json({
      distance: Math.round(distance),
      points,
      actualLocation: {
        x: photo.coordX,
        y: photo.coordY,
      },
      totalScore: updatedPlayer.score,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Move to next round
exports.nextRound = async (req, res) => {
  try {
    const { roomId } = req.body;

    const result = await RoomManager.nextRound(roomId);
    if (!result) {
      return res.status(404).json({ error: "Room not found" });
    }

    if (result.gameFinished) {
      return res.json(result);
    }

    res.json({
      currentRound: result.currentRound,
      totalRounds: result.totalRounds,
      photo: {
        imageUrl: result.currentPhoto.imageUrl,
        location: result.currentPhoto.location,
        difficulty: result.currentPhoto.difficulty,
      },
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Get room stats (for debugging)
exports.getRoomStats = async (req, res) => {
  try {
    const stats = RoomManager.getStats();
    const allRooms = RoomManager.getAllRooms().map((room) => ({
      roomId: room.roomId,
      currentRound: room.currentRound,
      totalRounds: room.totalRounds,
      playerCount: room.players.size,
      gameState: room.gameState,
      createdAt: room.createdAt,
      lastActivity: room.lastActivity,
    }));

    res.json({
      stats,
      rooms: allRooms,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Clean up inactive rooms
exports.cleanupRooms = async (req, res) => {
  try {
    const cleanedCount = RoomManager.cleanupInactiveRooms();
    res.json({
      message: `Cleaned up ${cleanedCount} inactive rooms`,
      cleanedCount,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Helper functions
function calculateDistance(x1, y1, x2, y2) {
  return Math.sqrt(Math.pow(x2 - x1, 2) + Math.pow(y2 - y1, 2));
}

function calculatePoints(distance) {
  // Scoring: closer guess = more points (max 1000 points)
  const maxPoints = 1000;
  const maxDistance = 500; // adjust based on your image dimensions

  if (distance <= 10) return maxPoints;
  if (distance >= maxDistance) return 0;

  return Math.round(maxPoints * (1 - distance / maxDistance));
}
