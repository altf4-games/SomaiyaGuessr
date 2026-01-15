const Photo = require("../models/Photo");

const rooms = new Map();
const roomTimers = new Map();

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
      lobbyStartTime: null,
      gameStartTime: null,
      roundStartTime: null,
      roundDuration: 30000,
      lobbyCountdown: null,
      roundTimer: null,
      minPlayers: 1,
      maxPlayers: 8,
      timeLeft: 30,
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
      this.clearRoomTimer(roomId);
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

  // Pusher-compatible methods
  static async startGameForPusher(roomId) {
    const room = rooms.get(roomId);
    if (!room) return null;

    room.gameState = "playing";
    room.gameStartTime = new Date();
    room.currentRound = 1;
    room.timeLeft = room.roundDuration / 1000;

    for (const player of room.players.values()) {
      player.isReady = false;
      player.hasSubmittedGuess = false;
    }

    return room;
  }

  static startRoundTimerWithPusher(roomId, pusher) {
    const room = rooms.get(roomId);
    if (!room) return;

    console.log(
      `Starting round timer for room ${roomId} (${room.roundDuration / 1000} seconds)`
    );

    room.roundStartTime = new Date();
    room.timeLeft = room.roundDuration / 1000;

    this.clearRoomTimer(roomId, "round");

    const roundInterval = setInterval(async () => {
      room.timeLeft--;

      try {
        await pusher.trigger(`room-${roomId}`, "round-timer", {
          timeLeft: room.timeLeft,
        });
      } catch (error) {
        console.error(`Error sending timer update: ${error.message}`);
      }

      if (room.timeLeft % 10 === 0 || room.timeLeft <= 5) {
        const submittedCount = Array.from(room.players.values()).filter(
          (p) => p.hasSubmittedGuess
        ).length;
        console.log(
          `Room ${roomId} timer: ${room.timeLeft}s left, ${submittedCount}/${room.players.size} players submitted`
        );
      }

      if (room.timeLeft <= 0) {
        console.log(`Timer expired for room ${roomId}, auto-submitting`);
        clearInterval(roundInterval);
        await this.autoSubmitRoundWithPusher(roomId, pusher);
      }
    }, 1000);

    if (!roomTimers.has(roomId)) {
      roomTimers.set(roomId, {});
    }
    roomTimers.get(roomId).round = roundInterval;
  }

  static async autoSubmitRoundWithPusher(roomId, pusher) {
    const room = rooms.get(roomId);
    if (!room) return;

    console.log(`Timer expired for room ${roomId}, auto-submitting for remaining players`);

    for (const [playerName, player] of room.players) {
      if (!player.hasSubmittedGuess) {
        console.log(`Auto-submitting for player ${playerName}`);
        this.updatePlayerScore(roomId, playerName, {
          guessX: null,
          guessY: null,
          distance: Infinity,
          points: 0,
        });
        player.hasSubmittedGuess = true;
      }
    }

    await this.checkRoundCompletionWithPusher(roomId, pusher, true);
  }

  static async checkRoundCompletionWithPusher(roomId, pusher, autoSubmitted = false) {
    const room = rooms.get(roomId);
    if (!room || room.gameState !== "playing") return false;

    const playerCount = room.players.size;
    const submittedCount = Array.from(room.players.values()).filter(
      (player) => player.hasSubmittedGuess
    ).length;
    const allSubmitted = submittedCount === playerCount;

    console.log(
      `Round completion check for room ${roomId}: ${submittedCount}/${playerCount} players submitted`
    );

    if (allSubmitted && playerCount > 0) {
      console.log(`All players submitted! Ending round for room ${roomId}`);

      this.clearRoomTimer(roomId, "round");

      try {
        await pusher.trigger(`room-${roomId}`, "round-ended", {
          autoSubmitted: autoSubmitted,
          actualLocation: {
            x: room.currentPhoto.coordX,
            y: room.currentPhoto.coordY,
          },
        });

        // Schedule next round advancement
        setTimeout(async () => {
          await this.advanceToNextRoundWithPusher(roomId, pusher);
        }, 3000);
      } catch (error) {
        console.error(`Error in round completion: ${error.message}`);
      }

      return true;
    }

    return false;
  }

  static async advanceToNextRoundWithPusher(roomId, pusher) {
    const room = rooms.get(roomId);
    if (!room) return;

    if (room.gameState !== "playing") {
      console.log(`Skipping round advancement for room ${roomId} - not in playing state`);
      return;
    }

    console.log(`Auto-advancing to next round for room ${roomId}`);

    try {
      const result = await this.nextRound(roomId);

      if (result && result.gameFinished) {
        await pusher.trigger(`room-${roomId}`, "game-finished", {
          finalScores: result.finalScores,
        });
      } else if (result) {
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

        this.startRoundTimerWithPusher(roomId, pusher);
      }
    } catch (error) {
      console.error(`Error advancing round for room ${roomId}:`, error);
    }
  }

  static checkRoundCompletion(roomId, io = null, autoSubmitted = false) {
    const room = rooms.get(roomId);
    if (!room || room.gameState !== "playing") return false;

    const playerCount = room.players.size;
    const submittedCount = Array.from(room.players.values()).filter(
      (player) => player.hasSubmittedGuess
    ).length;
    const allSubmitted = submittedCount === playerCount;

    console.log(
      `Round completion check for room ${roomId}: ${submittedCount}/${playerCount} players submitted (autoSubmitted: ${autoSubmitted})`
    );

    if (allSubmitted && playerCount > 0) {
      console.log(`All players submitted! Ending round for room ${roomId}`);

      this.clearRoomTimer(roomId, "round");

      if (io) {
        io.to(roomId).emit("round-ended", {
          autoSubmitted: autoSubmitted,
          actualLocation: {
            x: room.currentPhoto.coordX,
            y: room.currentPhoto.coordY,
          },
        });

        if (!roomTimers.has(roomId) || !roomTimers.get(roomId).advancement) {
          const advancementTimer = setTimeout(() => {
            this.advanceToNextRound(roomId, io);
            if (roomTimers.has(roomId)) {
              delete roomTimers.get(roomId).advancement;
            }
          }, 3000);

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

  static async advanceToNextRound(roomId, io = null) {
    const room = rooms.get(roomId);
    if (!room) return;

    if (room.gameState !== "playing") {
      console.log(
        `Skipping round advancement for room ${roomId} - not in playing state`
      );
      return;
    }

    console.log(`Auto-advancing to next round for room ${roomId}`);

    try {
      const result = await this.nextRound(roomId);

      if (result && result.gameFinished) {
        if (io) {
          io.to(roomId).emit("game-finished", {
            finalScores: result.finalScores,
          });
        }
      } else if (result && io) {
        io.to(roomId).emit("new-round", {
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

        this.startRoundTimer(roomId, io);
      }
    } catch (error) {
      console.error(`Error advancing round for room ${roomId}:`, error);
    }
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
      this.clearRoomTimer(roomId);
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
    room.lastActivity = new Date();

    for (const player of room.players.values()) {
      player.hasSubmittedGuess = false;
    }

    return room;
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

  static checkAndStartGame(roomId, io = null) {
    const room = rooms.get(roomId);
    if (!room || room.gameState !== "lobby") return false;

    if (room.players.size < room.minPlayers) return false;

    const allReady = Array.from(room.players.values()).every(
      (player) => player.isReady
    );

    if (allReady && room.players.size > 0) {
      this.startGameCountdown(roomId, io);
      return true;
    }

    return false;
  }

  static startGameCountdown(roomId, io = null) {
    const room = rooms.get(roomId);
    if (!room) return;

    room.gameState = "starting";
    room.lobbyCountdown = 2;

    this.clearRoomTimer(roomId, "lobby");

    const countdownInterval = setInterval(() => {
      room.lobbyCountdown--;

      if (io) {
        io.to(roomId).emit("game-starting", { countdown: room.lobbyCountdown });
      }

      if (room.lobbyCountdown <= 0) {
        clearInterval(countdownInterval);
        this.startGame(roomId, io);
      }
    }, 1000);

    if (!roomTimers.has(roomId)) {
      roomTimers.set(roomId, {});
    }
    roomTimers.get(roomId).lobby = countdownInterval;
  }

  static async startGame(roomId, io = null) {
    const room = rooms.get(roomId);
    if (!room) return null;

    room.gameState = "playing";
    room.gameStartTime = new Date();
    room.currentRound = 1;

    for (const player of room.players.values()) {
      player.isReady = false;
      player.hasSubmittedGuess = false;
    }

    if (io) {
      const playersArray = Array.from(room.players.values()).map((p) => ({
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
        photo: room.currentPhoto
          ? {
              imageUrl: room.currentPhoto.imageUrl,
              location: room.currentPhoto.location,
              difficulty: room.currentPhoto.difficulty,
              coordX: room.currentPhoto.coordX,
              coordY: room.currentPhoto.coordY,
            }
          : null,
      });
    }

    this.startRoundTimer(roomId, io);

    return room;
  }

  static startRoundTimer(roomId, io = null) {
    const room = rooms.get(roomId);
    if (!room) return;

    console.log(
      `Starting round timer for room ${roomId} (${
        room.roundDuration / 1000
      } seconds)`
    );

    room.roundStartTime = new Date();
    let timeLeft = room.roundDuration / 1000;

    this.clearRoomTimer(roomId, "round");
    this.clearRoomTimer(roomId, "advancement");

    const roundInterval = setInterval(() => {
      timeLeft--;

      if (io) {
        io.to(roomId).emit("round-timer", { timeLeft });
      }

      if (timeLeft % 10 === 0 || timeLeft <= 5) {
        const submittedCount = Array.from(room.players.values()).filter(
          (p) => p.hasSubmittedGuess
        ).length;
        console.log(
          `Room ${roomId} timer: ${timeLeft}s left, ${submittedCount}/${room.players.size} players submitted`
        );
      }

      if (timeLeft <= 0) {
        console.log(
          `Timer expired for room ${roomId}, calling autoSubmitRound`
        );
        clearInterval(roundInterval);
        this.autoSubmitRound(roomId, io);
      }
    }, 1000);

    if (!roomTimers.has(roomId)) {
      roomTimers.set(roomId, {});
    }
    roomTimers.get(roomId).round = roundInterval;
  }

  static autoSubmitRound(roomId, io = null) {
    const room = rooms.get(roomId);
    if (!room) return;

    console.log(
      `Timer expired for room ${roomId}, auto-submitting for remaining players`
    );

    let autoSubmittedCount = 0;
    for (const [playerName, player] of room.players) {
      if (!player.hasSubmittedGuess) {
        console.log(`Auto-submitting for player ${playerName}`);
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

    console.log(
      `Auto-submitted for ${autoSubmittedCount} players in room ${roomId}`
    );

    const roundComplete = this.checkRoundCompletion(roomId, io, true);

    if (!roundComplete) {
      console.error(
        `Round completion check failed after auto-submit for room ${roomId}`
      );
      if (io) {
        io.to(roomId).emit("round-ended", {
          autoSubmitted: true,
          actualLocation: {
            x: room.currentPhoto.coordX,
            y: room.currentPhoto.coordY,
          },
        });

        setTimeout(() => {
          this.advanceToNextRound(roomId, io);
        }, 3000);
      }
    }
  }

  static clearRoomTimer(roomId, timerType = null) {
    const timers = roomTimers.get(roomId);
    if (!timers) return;

    if (timerType) {
      if (timers[timerType]) {
        console.log(`Clearing ${timerType} timer for room ${roomId}`);
        if (timerType === "advancement") {
          clearTimeout(timers[timerType]);
        } else {
          clearInterval(timers[timerType]);
        }
        delete timers[timerType];
      }
    } else {
      console.log(`Clearing ALL timers for room ${roomId}`);
      Object.values(timers).forEach((timer) => {
        clearInterval(timer);
        clearTimeout(timer);
      });
      roomTimers.delete(roomId);
    }
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
