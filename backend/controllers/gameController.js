const RoomManager = require("../utils/roomManager");
const Photo = require("../models/Photo");

// Generate a short, user-friendly room code
function generateRoomCode() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  let result = '';
  for (let i = 0; i < 6; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return result;
}

// Create a new room
exports.createRoom = async (req, res) => {
  try {
    // Generate a 6-character room code using alphanumeric characters
    const roomId = generateRoomCode();

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
    // Note: Frontend sends guessX=longitude, guessY=latitude
    // Backend stores coordX=latitude, coordY=longitude (swapped!)
    // Distance function expects: (lng, lat, lng, lat)
    const distance = calculateDistance(
      guessX,        // guess longitude
      guessY,        // guess latitude
      photo.coordY,  // photo longitude (stored in coordY)
      photo.coordX   // photo latitude (stored in coordX)
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
function calculateDistance(guessLng, guessLat, photoLng, photoLat) {
  // Use Haversine formula for geographic distance calculation
  const R = 6371000; // Earth's radius in meters
  const φ1 = guessLat * Math.PI / 180; // φ, λ in radians
  const φ2 = photoLat * Math.PI / 180;
  const Δφ = (photoLat - guessLat) * Math.PI / 180;
  const Δλ = (photoLng - guessLng) * Math.PI / 180;

  const a = Math.sin(Δφ/2) * Math.sin(Δφ/2) +
            Math.cos(φ1) * Math.cos(φ2) *
            Math.sin(Δλ/2) * Math.sin(Δλ/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));

  const distance = R * c; // Distance in meters

  console.log(`📏 Distance calculation: Guess(${guessLng}, ${guessLat}) -> Photo(${photoLng}, ${photoLat}) = ${distance.toFixed(2)}m`);

  return distance;
}

function calculatePoints(distance) {
  // Much stricter scoring system for more challenging gameplay
  const maxPoints = 1000;

  // Perfect accuracy (within 5 meters) = 1000 points
  if (distance <= 5) return maxPoints;

  // Excellent accuracy (5-15 meters) = 800-900 points
  if (distance <= 15) return Math.round(900 - ((distance - 5) / 10) * 100);

  // Good accuracy (15-30 meters) = 600-800 points
  if (distance <= 30) return Math.round(800 - ((distance - 15) / 15) * 200);

  // Fair accuracy (30-60 meters) = 300-600 points
  if (distance <= 60) return Math.round(600 - ((distance - 30) / 30) * 300);

  // Poor accuracy (60-100 meters) = 100-300 points
  if (distance <= 100) return Math.round(300 - ((distance - 60) / 40) * 200);

  // Very poor accuracy (100-200 meters) = 50-100 points
  if (distance <= 200) return Math.round(100 - ((distance - 100) / 100) * 50);

  // Terrible accuracy (200+ meters) = 0-50 points
  if (distance <= 500) return Math.round(50 - ((distance - 200) / 300) * 50);

  // Beyond 500 meters = 0 points
  return 0;
}
