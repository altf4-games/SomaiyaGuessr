const RoomManager = require("../utils/roomManager");
const Photo = require("../models/Photo");
const pusher = require("../config/pusher");

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
    const { roomId, playerName } = req.body;

    const room = RoomManager.getRoom(roomId);

    if (!room) {
      return res.status(404).json({ error: "Room not found" });
    }

    // Add player to room
    const player = RoomManager.addPlayerToRoom(roomId, null, playerName);
    if (!player) {
      return res.status(400).json({ error: "Failed to join room" });
    }

    const playersArray = Array.from(room.players.values()).map((p) => ({
      name: p.name,
      score: p.score,
      isReady: p.isReady,
      hasSubmittedGuess: p.hasSubmittedGuess,
    }));

    // Notify other players via Pusher
    await pusher.trigger(`room-${roomId}`, "player-joined", {
      playerName,
      totalPlayers: room.players.size,
      players: playersArray,
    });

    res.json({
      roomId: room.roomId,
      currentRound: room.currentRound,
      totalRounds: room.totalRounds,
      gameState: room.gameState,
      minPlayers: room.minPlayers,
      maxPlayers: room.maxPlayers,
      photo:
        room.currentPhoto && room.gameState === "playing"
          ? {
              imageUrl: room.currentPhoto.imageUrl,
              location: room.currentPhoto.location,
              difficulty: room.currentPhoto.difficulty,
              coordX: room.currentPhoto.coordX,
              coordY: room.currentPhoto.coordY,
            }
          : null,
      players: playersArray,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.leaveRoom = async (req, res) => {
  try {
    const { roomId, playerName } = req.body;

    const room = RoomManager.getRoom(roomId);
    if (!room) {
      return res.status(404).json({ error: "Room not found" });
    }

    RoomManager.removePlayerFromRoom(roomId, playerName);

    const updatedRoom = RoomManager.getRoom(roomId);
    if (updatedRoom) {
      const playersArray = Array.from(updatedRoom.players.values()).map((p) => ({
        name: p.name,
        score: p.score,
        isReady: p.isReady,
        hasSubmittedGuess: p.hasSubmittedGuess,
      }));

      await pusher.trigger(`room-${roomId}`, "player-left", {
        playerName,
        totalPlayers: updatedRoom.players.size,
        players: playersArray,
      });
    }

    res.json({ success: true, message: "Left room successfully" });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.setPlayerReady = async (req, res) => {
  try {
    const { roomId, playerName, isReady } = req.body;

    const room = RoomManager.getRoom(roomId);
    if (!room) {
      return res.status(404).json({ error: "Room not found" });
    }

    if (room.gameState !== "lobby") {
      return res.status(400).json({ error: "Game is not in lobby state" });
    }

    const player = RoomManager.setPlayerReady(roomId, playerName, isReady);
    if (!player) {
      return res.status(404).json({ error: "Player not found in room" });
    }

    const playersArray = Array.from(room.players.values()).map((p) => ({
      name: p.name,
      score: p.score,
      isReady: p.isReady,
      hasSubmittedGuess: p.hasSubmittedGuess,
    }));

    await pusher.trigger(`room-${roomId}`, "player-ready-changed", {
      playerName,
      isReady,
      players: playersArray,
    });

    // Check if all players are ready
    const allReady = Array.from(room.players.values()).every((p) => p.isReady);
    const canStart = allReady && room.players.size >= room.minPlayers;

    res.json({
      success: true,
      playerName,
      isReady,
      players: playersArray,
      canStart,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.startGame = async (req, res) => {
  try {
    const { roomId } = req.body;

    const room = RoomManager.getRoom(roomId);
    if (!room) {
      return res.status(404).json({ error: "Room not found" });
    }

    if (room.gameState !== "lobby") {
      return res.status(400).json({ error: "Game is not in lobby state" });
    }

    if (room.players.size < room.minPlayers) {
      return res.status(400).json({
        error: `Need at least ${room.minPlayers} players to start`,
      });
    }

    // Start countdown
    room.gameState = "starting";
    
    // Send countdown events
    await pusher.trigger(`room-${roomId}`, "game-starting", { countdown: 3 });
    
    // Schedule game start
    setTimeout(async () => {
      await pusher.trigger(`room-${roomId}`, "game-starting", { countdown: 2 });
    }, 1000);
    
    setTimeout(async () => {
      await pusher.trigger(`room-${roomId}`, "game-starting", { countdown: 1 });
    }, 2000);

    setTimeout(async () => {
      // Actually start the game
      const startedRoom = await RoomManager.startGameForPusher(roomId);
      if (startedRoom) {
        const playersArray = Array.from(startedRoom.players.values()).map((p) => ({
          name: p.name,
          score: p.score,
          isReady: p.isReady,
          hasSubmittedGuess: p.hasSubmittedGuess,
        }));

        await pusher.trigger(`room-${roomId}`, "game-started", {
          roomId: startedRoom.roomId,
          currentRound: startedRoom.currentRound,
          totalRounds: startedRoom.totalRounds,
          gameState: startedRoom.gameState,
          players: playersArray,
          photo: startedRoom.currentPhoto
            ? {
                imageUrl: startedRoom.currentPhoto.imageUrl,
                location: startedRoom.currentPhoto.location,
                difficulty: startedRoom.currentPhoto.difficulty,
                coordX: startedRoom.currentPhoto.coordX,
                coordY: startedRoom.currentPhoto.coordY,
              }
            : null,
        });

        // Start the round timer
        RoomManager.startRoundTimerWithPusher(roomId, pusher);
      }
    }, 3000);

    res.json({ success: true, message: "Game starting countdown initiated" });
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

    if (room.gameState !== "playing") {
      return res.status(400).json({ error: "Game is not in playing state" });
    }

    const player = RoomManager.getPlayer(roomId, playerName);
    if (!player) {
      return res.status(404).json({ error: "Player not found in room" });
    }

    if (player.hasSubmittedGuess) {
      return res.status(400).json({
        error: "You have already submitted a guess for this round",
      });
    }

    const photo = room.currentPhoto;
    const distance = calculateDistance(
      guessX,
      guessY,
      photo.coordY,
      photo.coordX
    );
    const points = calculatePoints(distance);

    console.log(`Guess submission: Player ${playerName}`);
    console.log(`   Guess coordinates: (${guessX}, ${guessY})`);
    console.log(`   Photo coordinates: (${photo.coordX}, ${photo.coordY})`);
    console.log(`   Distance: ${distance.toFixed(2)}m`);
    console.log(`   Points awarded: ${points}`);

    const updatedPlayer = RoomManager.updatePlayerScore(roomId, playerName, {
      guessX,
      guessY,
      distance,
      points,
    });

    if (!updatedPlayer) {
      return res.status(500).json({ error: "Failed to update player score" });
    }

    const playersArray = Array.from(room.players.values()).map((p) => ({
      name: p.name,
      score: p.score,
      isReady: p.isReady,
      hasSubmittedGuess: p.hasSubmittedGuess,
    }));

    // Notify all players about the guess
    await pusher.trigger(`room-${roomId}`, "player-guessed", {
      playerName,
      score: updatedPlayer.score,
      guessCount: updatedPlayer.guesses.length,
      players: playersArray,
    });

    // Check if round is complete
    RoomManager.checkRoundCompletionWithPusher(roomId, pusher);

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
      await pusher.trigger(`room-${roomId}`, "game-finished", {
        finalScores: result.finalScores,
      });
      return res.json(result);
    }

    // Start round timer for new round
    RoomManager.startRoundTimerWithPusher(roomId, pusher);

    await pusher.trigger(`room-${roomId}`, "new-round", {
      currentRound: result.currentRound,
      totalRounds: result.totalRounds,
      photo: {
        imageUrl: result.currentPhoto.imageUrl,
        location: result.currentPhoto.location,
        difficulty: result.currentPhoto.difficulty,
        coordX: result.currentPhoto.coordX,
        coordY: result.currentPhoto.coordY,
      },
    });

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

// Get room state (for polling fallback)
exports.getRoomState = async (req, res) => {
  try {
    const { roomId } = req.params;

    const room = RoomManager.getRoom(roomId);
    if (!room) {
      return res.status(404).json({ error: "Room not found" });
    }

    const playersArray = Array.from(room.players.values()).map((p) => ({
      name: p.name,
      score: p.score,
      isReady: p.isReady,
      hasSubmittedGuess: p.hasSubmittedGuess,
    }));

    res.json({
      roomId: room.roomId,
      currentRound: room.currentRound,
      totalRounds: room.totalRounds,
      gameState: room.gameState,
      minPlayers: room.minPlayers,
      maxPlayers: room.maxPlayers,
      photo:
        room.currentPhoto && room.gameState === "playing"
          ? {
              imageUrl: room.currentPhoto.imageUrl,
              location: room.currentPhoto.location,
              difficulty: room.currentPhoto.difficulty,
              coordX: room.currentPhoto.coordX,
              coordY: room.currentPhoto.coordY,
            }
          : null,
      players: playersArray,
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
