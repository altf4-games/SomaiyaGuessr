const Photo = require("../models/Photo");

// In-memory room storage
const rooms = new Map();

class RoomManager {
  // Create a new room
  static async createRoom(roomId) {
    // Get random photo for first round
    const photos = await Photo.find();
    if (photos.length === 0) {
      throw new Error("No photos available. Please upload some photos first.");
    }

    const randomPhoto = photos[Math.floor(Math.random() * photos.length)];

    const room = {
      roomId,
      currentPhoto: randomPhoto,
      currentRound: 1,
      totalRounds: 5,
      players: new Map(), // Using Map for better performance
      gameState: "waiting",
      createdAt: new Date(),
      lastActivity: new Date(),
    };

    rooms.set(roomId, room);
    return room;
  }

  // Get room by ID
  static getRoom(roomId) {
    const room = rooms.get(roomId);
    if (room) {
      room.lastActivity = new Date();
    }
    return room;
  }

  // Add player to room
  static addPlayerToRoom(roomId, socketId, playerName) {
    const room = rooms.get(roomId);
    if (!room) return null;

    // Check if player already exists (reconnection)
    let player = room.players.get(playerName);
    if (player) {
      player.socketId = socketId; // Update socket ID for reconnection
    } else {
      player = {
        socketId,
        name: playerName,
        score: 0,
        guesses: [],
      };
      room.players.set(playerName, player);
    }

    room.lastActivity = new Date();
    return player;
  }

  // Remove player from room
  static removePlayerFromRoom(roomId, playerName) {
    const room = rooms.get(roomId);
    if (!room) return false;

    const removed = room.players.delete(playerName);
    room.lastActivity = new Date();

    // If no players left, mark for cleanup
    if (room.players.size === 0) {
      room.gameState = "empty";
    }

    return removed;
  }

  // Get player from room
  static getPlayer(roomId, playerName) {
    const room = rooms.get(roomId);
    if (!room) return null;

    return room.players.get(playerName);
  }

  // Update player score
  static updatePlayerScore(roomId, playerName, guessData) {
    const room = rooms.get(roomId);
    if (!room) return null;

    const player = room.players.get(playerName);
    if (!player) return null;

    player.guesses.push({
      round: room.currentRound,
      guessX: guessData.guessX,
      guessY: guessData.guessY,
      distance: guessData.distance,
      points: guessData.points,
    });

    player.score += guessData.points;
    room.lastActivity = new Date();

    return player;
  }

  // Move to next round
  static async nextRound(roomId) {
    const room = rooms.get(roomId);
    if (!room) return null;

    if (room.currentRound >= room.totalRounds) {
      room.gameState = "finished";
      return {
        gameFinished: true,
        finalScores: Array.from(room.players.values())
          .map((p) => ({ name: p.name, score: p.score }))
          .sort((a, b) => b.score - a.score),
      };
    }

    // Get new random photo
    const photos = await Photo.find();
    const randomPhoto = photos[Math.floor(Math.random() * photos.length)];

    room.currentRound += 1;
    room.currentPhoto = randomPhoto;
    room.lastActivity = new Date();

    return room;
  }

  // Get all rooms (for debugging)
  static getAllRooms() {
    return Array.from(rooms.values());
  }

  // Clean up inactive rooms (call this periodically)
  static cleanupInactiveRooms(maxInactiveTime = 30 * 60 * 1000) {
    // 30 minutes
    const now = new Date();
    const roomsToDelete = [];

    for (const [roomId, room] of rooms) {
      const timeSinceActivity = now - room.lastActivity;

      // Clean up if inactive for too long or empty
      if (timeSinceActivity > maxInactiveTime || room.gameState === "empty") {
        roomsToDelete.push(roomId);
      }
    }

    roomsToDelete.forEach((roomId) => {
      rooms.delete(roomId);
      console.log(`🧹 Cleaned up inactive room: ${roomId}`);
    });

    return roomsToDelete.length;
  }

  // Get room statistics
  static getStats() {
    const totalRooms = rooms.size;
    let totalPlayers = 0;
    let activeRooms = 0;

    for (const room of rooms.values()) {
      totalPlayers += room.players.size;
      if (room.players.size > 0 && room.gameState !== "finished") {
        activeRooms++;
      }
    }

    return {
      totalRooms,
      activeRooms,
      totalPlayers,
      averagePlayersPerRoom:
        totalRooms > 0 ? (totalPlayers / totalRooms).toFixed(2) : 0,
    };
  }
}

module.exports = RoomManager;
