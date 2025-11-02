const RoomManager = require("../utils/roomManager");
const Photo = require("../models/Photo");

function generateRoomCode() {
  const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
  let result = "";
  for (let i = 0; i < 6; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return result;
}

exports.createRoom = async (req, res) => {
  try {
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
      photo.coordY,
      photo.coordX
    );
    const points = calculatePoints(distance);

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

function calculateDistance(guessLng, guessLat, photoLng, photoLat) {
  const R = 6371000;
  const φ1 = (guessLat * Math.PI) / 180;
  const φ2 = (photoLat * Math.PI) / 180;
  const Δφ = ((photoLat - guessLat) * Math.PI) / 180;
  const Δλ = ((photoLng - guessLng) * Math.PI) / 180;

  const a =
    Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
    Math.cos(φ1) * Math.cos(φ2) * Math.sin(Δλ / 2) * Math.sin(Δλ / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  const distance = R * c;

  console.log(
    `Distance calculation: Guess(${guessLng}, ${guessLat}) -> Photo(${photoLng}, ${photoLat}) = ${distance.toFixed(
      2
    )}m`
  );

  return distance;
}

function calculatePoints(distance) {
  const maxPoints = 1000;

  if (distance <= 5) return maxPoints;

  if (distance <= 15) return Math.round(900 - ((distance - 5) / 10) * 100);

  if (distance <= 30) return Math.round(800 - ((distance - 15) / 15) * 200);

  if (distance <= 60) return Math.round(600 - ((distance - 30) / 30) * 300);

  if (distance <= 100) return Math.round(300 - ((distance - 60) / 40) * 200);

  if (distance <= 200) return Math.round(100 - ((distance - 100) / 100) * 50);

  if (distance <= 500) return Math.round(50 - ((distance - 200) / 300) * 50);

  return 0;
}
