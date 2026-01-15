const Photo = require("../models/Photo");

const rooms = new Map();

class RoomManager {
  static async createRoom(roomId) {
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
      players: new Map(),
      gameState: "lobby",
      createdAt: new Date(),
      lastActivity: new Date(),
      gameStartTime: null,
      roundStartTime: null,
      roundDuration: 30000, // 30 seconds in milliseconds
      minPlayers: 1,
      maxPlayers: 8,
    };

    rooms.set(roomId, room);
    return room;
  }

  static getRoom(roomId) {
    const room = rooms.get(roomId);
    if (room) {
      room.lastActivity = new Date();
    }
    return room;
  }

  static addPlayerToRoom(roomId, socketId, playerName) {
    const room = rooms.get(roomId);
    if (!room) return null;

    if (room.players.size >= room.maxPlayers) {
      throw new Error("Room is full");
    }

    let player = room.players.get(playerName);
    if (player) {
      player.socketId = socketId;
      player.isReady = false;
    } else {
      player = {
        socketId,
        name: playerName,
        score: 0,
        guesses: [],
        isReady: false,
        hasSubmittedGuess: false,
        joinedAt: new Date(),
      };
      room.players.set(playerName, player);
    }

    room.lastActivity = new Date();
    return player;
  }

  static removePlayerFromRoom(roomId, playerName) {
    const room = rooms.get(roomId);
    if (!room) return false;

    const removed = room.players.delete(playerName);
    room.lastActivity = new Date();

    if (room.players.size === 0) {
      room.gameState = "empty";
    }

    return removed;
  }

  static getPlayer(roomId, playerName) {
    const room = rooms.get(roomId);
    if (!room) return null;

    return room.players.get(playerName);
  }

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
      timestamp: new Date(),
    });

    player.score += guessData.points;
    player.hasSubmittedGuess = true;
    room.lastActivity = new Date();

    return player;
  }

  static startGame(roomId) {
    const room = rooms.get(roomId);
    if (!room) return null;

    room.gameState = "playing";
    room.gameStartTime = new Date();
    room.roundStartTime = new Date();
    room.currentRound = 1;

    for (const player of room.players.values()) {
      player.isReady = false;
      player.hasSubmittedGuess = false;
    }

    return room;
  }

  static async nextRound(roomId) {
    const room = rooms.get(roomId);
    if (!room) return null;

    if (room.gameState !== "playing") {
      console.log(
        `Attempted to advance round for room ${roomId} but game state is ${room.gameState}`
      );
      return null;
    }

    if (room.currentRound >= room.totalRounds) {
      room.gameState = "finished";
      return {
        gameFinished: true,
        finalScores: Array.from(room.players.values())
          .map((p) => ({ name: p.name, score: p.score }))
          .sort((a, b) => b.score - a.score),
      };
    }

    const photos = await Photo.find();
    const randomPhoto = photos[Math.floor(Math.random() * photos.length)];

    room.currentRound += 1;
    room.currentPhoto = randomPhoto;
    room.roundStartTime = new Date();
    room.lastActivity = new Date();

    for (const player of room.players.values()) {
      player.hasSubmittedGuess = false;
    }

    return {
      currentRound: room.currentRound,
      totalRounds: room.totalRounds,
      currentPhoto: room.currentPhoto,
    };
  }

  static getAllRooms() {
    return Array.from(rooms.values());
  }

  static cleanupInactiveRooms(maxInactiveTime = 30 * 60 * 1000) {
    const now = new Date();
    const roomsToDelete = [];

    for (const [roomId, room] of rooms) {
      const timeSinceActivity = now - room.lastActivity;

      if (timeSinceActivity > maxInactiveTime || room.gameState === "empty") {
        roomsToDelete.push(roomId);
      }
    }

    roomsToDelete.forEach((roomId) => {
      rooms.delete(roomId);
      console.log(`Cleaned up inactive room: ${roomId}`);
    });

    return roomsToDelete.length;
  }

  static setPlayerReady(roomId, playerName, isReady) {
    const room = rooms.get(roomId);
    if (!room) return null;

    const player = room.players.get(playerName);
    if (!player) return null;

    player.isReady = isReady;
    room.lastActivity = new Date();

    return player;
  }

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
