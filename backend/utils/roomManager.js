const Photo = require("../models/Photo");

// In-memory room storage
const rooms = new Map();
const roomTimers = new Map(); // Store timers for each room

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
      gameState: "lobby", // Changed from "waiting" to "lobby"
      createdAt: new Date(),
      lastActivity: new Date(),
      // New lobby-specific properties
      lobbyStartTime: null,
      gameStartTime: null,
      roundStartTime: null,
      roundDuration: 30000, // 30 seconds in milliseconds
      lobbyCountdown: null,
      roundTimer: null,
      minPlayers: 1, // Minimum players to start
      maxPlayers: 8, // Maximum players allowed
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

    // Check if room is full
    if (room.players.size >= room.maxPlayers) {
      throw new Error("Room is full");
    }

    // Check if player already exists (reconnection)
    let player = room.players.get(playerName);
    if (player) {
      player.socketId = socketId; // Update socket ID for reconnection
      player.isReady = false; // Reset ready status on reconnection
    } else {
      player = {
        socketId,
        name: playerName,
        score: 0,
        guesses: [],
        isReady: false, // New property for lobby ready status
        hasSubmittedGuess: false, // Track if player submitted guess this round
        joinedAt: new Date(),
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

    // If no players left, mark for cleanup and clear timers
    if (room.players.size === 0) {
      room.gameState = "empty";
      this.clearRoomTimer(roomId);
    } else if (room.gameState === "lobby") {
      // Check if remaining players are all ready
      // Note: io will be passed from the socket controller when needed
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
      timestamp: new Date(),
    });

    player.score += guessData.points;
    player.hasSubmittedGuess = true;
    room.lastActivity = new Date();

    // Check if all players have submitted their guesses
    // Note: io will be passed from the socket controller when needed

    return player;
  }

  // Check if all players have submitted guesses for current round
  static checkRoundCompletion(roomId, io = null, autoSubmitted = false) {
    const room = rooms.get(roomId);
    if (!room || room.gameState !== "playing") return false;

    const playerCount = room.players.size;
    const submittedCount = Array.from(room.players.values()).filter(player => player.hasSubmittedGuess).length;
    const allSubmitted = submittedCount === playerCount;

    console.log(`🔍 Round completion check for room ${roomId}: ${submittedCount}/${playerCount} players submitted (autoSubmitted: ${autoSubmitted})`);

    if (allSubmitted && playerCount > 0) {
      console.log(`✅ All players submitted! Ending round for room ${roomId}`);

      // All players submitted, end round early
      this.clearRoomTimer(roomId, 'round');

      // Emit round ended event
      if (io) {
        io.to(roomId).emit('round-ended', {
          autoSubmitted: autoSubmitted,
          actualLocation: {
            x: room.currentPhoto.coordX,
            y: room.currentPhoto.coordY,
          },
        });

        // Auto-advance to next round after 3 seconds (only if not already scheduled)
        if (!roomTimers.has(roomId) || !roomTimers.get(roomId).advancement) {
          const advancementTimer = setTimeout(() => {
            this.advanceToNextRound(roomId, io);
            // Clear the timer reference
            if (roomTimers.has(roomId)) {
              delete roomTimers.get(roomId).advancement;
            }
          }, 3000);

          // Store timer reference to prevent duplicates
          if (!roomTimers.has(roomId)) {
            roomTimers.set(roomId, {});
          }
          roomTimers.get(roomId).advancement = advancementTimer;
        }
      }
      return true;
    }

    return false;
  }

  // Safely advance to next round (called automatically by backend)
  static async advanceToNextRound(roomId, io = null) {
    const room = rooms.get(roomId);
    if (!room) return;

    // Check if room is still in roundResult state (prevent double advancement)
    if (room.gameState !== "playing") {
      console.log(`⚠️ Skipping round advancement for room ${roomId} - not in playing state`);
      return;
    }

    console.log(`🚀 Auto-advancing to next round for room ${roomId}`);

    try {
      const result = await this.nextRound(roomId);

      if (result && result.gameFinished) {
        // Game finished
        if (io) {
          io.to(roomId).emit('game-finished', {
            finalScores: result.finalScores,
          });
        }
      } else if (result && io) {
        // New round started
        io.to(roomId).emit('new-round', {
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

        // Start timer for new round
        this.startRoundTimer(roomId, io);
      }
    } catch (error) {
      console.error(`❌ Error advancing round for room ${roomId}:`, error);
    }
  }

  // Move to next round
  static async nextRound(roomId) {
    const room = rooms.get(roomId);
    if (!room) return null;

    // Prevent double advancement - only allow if game is in playing state
    if (room.gameState !== "playing") {
      console.log(`⚠️ Attempted to advance round for room ${roomId} but game state is ${room.gameState}`);
      return null;
    }

    if (room.currentRound >= room.totalRounds) {
      room.gameState = "finished";
      this.clearRoomTimer(roomId);
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

    // Reset all players' guess status for new round
    for (const player of room.players.values()) {
      player.hasSubmittedGuess = false;
    }

    // Start new round timer
    // Note: io will be passed from the socket controller when needed

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

  // Set player ready status
  static setPlayerReady(roomId, playerName, isReady) {
    const room = rooms.get(roomId);
    if (!room) return null;

    const player = room.players.get(playerName);
    if (!player) return null;

    player.isReady = isReady;
    room.lastActivity = new Date();

    // Check if all players are ready and start game if so
    // Note: io will be passed from the socket controller when needed

    return player;
  }

  // Check if all players are ready and start game
  static checkAndStartGame(roomId, io = null) {
    const room = rooms.get(roomId);
    if (!room || room.gameState !== "lobby") return false;

    // Need at least minimum players
    if (room.players.size < room.minPlayers) return false;

    // Check if all players are ready
    const allReady = Array.from(room.players.values()).every(player => player.isReady);

    if (allReady && room.players.size > 0) {
      // Start 2-second countdown before game starts
      this.startGameCountdown(roomId, io);
      return true;
    }

    return false;
  }

  // Start 2-second countdown before game begins
  static startGameCountdown(roomId, io = null) {
    const room = rooms.get(roomId);
    if (!room) return;

    room.gameState = "starting";
    room.lobbyCountdown = 2; // 2 seconds

    // Clear any existing timer
    this.clearRoomTimer(roomId, 'lobby');

    const countdownInterval = setInterval(() => {
      room.lobbyCountdown--;

      // Emit countdown update to all players
      if (io) {
        io.to(roomId).emit('game-starting', { countdown: room.lobbyCountdown });
      }

      if (room.lobbyCountdown <= 0) {
        clearInterval(countdownInterval);
        this.startGame(roomId, io);
      }
    }, 1000);

    // Store timer reference
    if (!roomTimers.has(roomId)) {
      roomTimers.set(roomId, {});
    }
    roomTimers.get(roomId).lobby = countdownInterval;
  }

  // Start the actual game
  static async startGame(roomId, io = null) {
    const room = rooms.get(roomId);
    if (!room) return null;

    room.gameState = "playing";
    room.gameStartTime = new Date();
    room.currentRound = 1;

    // Reset all players' ready status and guess status
    for (const player of room.players.values()) {
      player.isReady = false;
      player.hasSubmittedGuess = false;
    }

    // Notify all players that the game has started
    if (io) {
      const playersArray = Array.from(room.players.values()).map(p => ({
        name: p.name,
        score: p.score,
        isReady: p.isReady,
        hasSubmittedGuess: p.hasSubmittedGuess,
      }));

      io.to(roomId).emit("game-started", {
        roomId: room.roomId,
        currentRound: room.currentRound,
        totalRounds: room.totalRounds,
        gameState: room.gameState,
        players: playersArray,
        photo: room.currentPhoto ? {
          imageUrl: room.currentPhoto.imageUrl,
          location: room.currentPhoto.location,
          difficulty: room.currentPhoto.difficulty,
          coordX: room.currentPhoto.coordX,
          coordY: room.currentPhoto.coordY,
        } : null,
      });
    }

    // Start round timer
    this.startRoundTimer(roomId, io);

    return room;
  }

  // Start round timer (30 seconds)
  static startRoundTimer(roomId, io = null) {
    const room = rooms.get(roomId);
    if (!room) return;

    console.log(`⏰ Starting round timer for room ${roomId} (${room.roundDuration / 1000} seconds)`);

    room.roundStartTime = new Date();
    let timeLeft = room.roundDuration / 1000; // Convert to seconds

    // Clear any existing round timer and advancement timer
    this.clearRoomTimer(roomId, 'round');
    this.clearRoomTimer(roomId, 'advancement');

    const roundInterval = setInterval(() => {
      timeLeft--;

      // Emit timer update to all players
      if (io) {
        io.to(roomId).emit('round-timer', { timeLeft });
      }

      // Debug: Log timer status every 10 seconds
      if (timeLeft % 10 === 0 || timeLeft <= 5) {
        const submittedCount = Array.from(room.players.values()).filter(p => p.hasSubmittedGuess).length;
        console.log(`⏰ Room ${roomId} timer: ${timeLeft}s left, ${submittedCount}/${room.players.size} players submitted`);
      }

      if (timeLeft <= 0) {
        console.log(`⏰ Timer expired for room ${roomId}, calling autoSubmitRound`);
        clearInterval(roundInterval);
        this.autoSubmitRound(roomId, io);
      }
    }, 1000);

    // Store timer reference
    if (!roomTimers.has(roomId)) {
      roomTimers.set(roomId, {});
    }
    roomTimers.get(roomId).round = roundInterval;
  }

  // Auto-submit round when timer expires
  static autoSubmitRound(roomId, io = null) {
    const room = rooms.get(roomId);
    if (!room) return;

    console.log(`⏰ Timer expired for room ${roomId}, auto-submitting for remaining players`);

    // Auto-submit for players who haven't submitted
    let autoSubmittedCount = 0;
    for (const [playerName, player] of room.players) {
      if (!player.hasSubmittedGuess) {
        console.log(`🤖 Auto-submitting for player ${playerName}`);
        // Submit with no guess (0 points)
        this.updatePlayerScore(roomId, playerName, {
          guessX: null,
          guessY: null,
          distance: Infinity,
          points: 0,
        });
        player.hasSubmittedGuess = true;
        autoSubmittedCount++;
      }
    }

    console.log(`🤖 Auto-submitted for ${autoSubmittedCount} players in room ${roomId}`);

    // Now check if round is complete (should be true since we auto-submitted everyone)
    const roundComplete = this.checkRoundCompletion(roomId, io, true);

    if (!roundComplete) {
      console.error(`❌ Round completion check failed after auto-submit for room ${roomId}`);
      // Fallback: emit round-ended event directly
      if (io) {
        io.to(roomId).emit('round-ended', {
          autoSubmitted: true,
          actualLocation: {
            x: room.currentPhoto.coordX,
            y: room.currentPhoto.coordY,
          },
        });

        // Auto-advance to next round after 3 seconds
        setTimeout(() => {
          this.advanceToNextRound(roomId, io);
        }, 3000);
      }
    }
  }

  // Clear room timers
  static clearRoomTimer(roomId, timerType = null) {
    const timers = roomTimers.get(roomId);
    if (!timers) return;

    if (timerType) {
      if (timers[timerType]) {
        console.log(`🛑 Clearing ${timerType} timer for room ${roomId}`);
        if (timerType === 'advancement') {
          clearTimeout(timers[timerType]); // advancement uses setTimeout
        } else {
          clearInterval(timers[timerType]); // other timers use setInterval
        }
        delete timers[timerType];
      }
    } else {
      console.log(`🛑 Clearing ALL timers for room ${roomId}`);
      // Clear all timers for the room
      Object.values(timers).forEach(timer => {
        clearInterval(timer); // Try both just in case
        clearTimeout(timer);
      });
      roomTimers.delete(roomId);
    }
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
