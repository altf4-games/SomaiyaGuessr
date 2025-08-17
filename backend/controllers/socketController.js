const RoomManager = require("../utils/roomManager");

module.exports = (io) => {
  io.on("connection", (socket) => {
    console.log(`🔗 User connected: ${socket.id}`);

    // Join room
    socket.on("join-room", async (data) => {
      try {
        const { roomId, playerName } = data;

        const room = RoomManager.getRoom(roomId);
        if (!room) {
          socket.emit("error", { message: "Room not found" });
          return;
        }

        // Add player to room
        const player = RoomManager.addPlayerToRoom(roomId, socket.id, playerName);
        if (!player) {
          socket.emit("error", { message: "Failed to join room" });
          return;
        }

        socket.join(roomId);

        // Get updated room info after player joined
        const updatedRoom = RoomManager.getRoom(roomId);
        const playersArray = Array.from(updatedRoom.players.values()).map(p => ({
          name: p.name,
          score: p.score,
          isReady: p.isReady,
          hasSubmittedGuess: p.hasSubmittedGuess,
        }));

        // Send room info to player
        socket.emit("room-joined", {
          roomId: updatedRoom.roomId,
          currentRound: updatedRoom.currentRound,
          totalRounds: updatedRoom.totalRounds,
          gameState: updatedRoom.gameState,
          players: playersArray,
          minPlayers: updatedRoom.minPlayers,
          maxPlayers: updatedRoom.maxPlayers,
          photo: updatedRoom.currentPhoto && updatedRoom.gameState === "playing"
            ? {
                imageUrl: updatedRoom.currentPhoto.imageUrl,
                location: updatedRoom.currentPhoto.location,
                difficulty: updatedRoom.currentPhoto.difficulty,
                coordX: updatedRoom.currentPhoto.coordX,
                coordY: updatedRoom.currentPhoto.coordY,
              }
            : null,
        });

        // Notify other players
        socket.to(roomId).emit("player-joined", {
          playerName,
          totalPlayers: updatedRoom.players.size,
          players: playersArray,
        });
      } catch (error) {
        socket.emit("error", { message: error.message });
      }
    });

    // Handle player ready status
    socket.on("player-ready", async (data) => {
      try {
        const { roomId, playerName, isReady } = data;

        const room = RoomManager.getRoom(roomId);
        if (!room) {
          socket.emit("error", { message: "Room not found" });
          return;
        }

        if (room.gameState !== "lobby") {
          socket.emit("error", { message: "Game is not in lobby state" });
          return;
        }

        // Update player ready status
        const player = RoomManager.setPlayerReady(roomId, playerName, isReady);
        if (!player) {
          socket.emit("error", { message: "Player not found in room" });
          return;
        }

        // Get updated players list
        const playersArray = Array.from(room.players.values()).map(p => ({
          name: p.name,
          score: p.score,
          isReady: p.isReady,
          hasSubmittedGuess: p.hasSubmittedGuess,
        }));

        // Notify all players about ready status change
        io.to(roomId).emit("player-ready-changed", {
          playerName,
          isReady,
          players: playersArray,
        });

        // Check if all players are ready and start game
        RoomManager.checkAndStartGame(roomId, io);

      } catch (error) {
        socket.emit("error", { message: error.message });
      }
    });

    // Handle start game request (for room creator)
    socket.on("start-game", async (data) => {
      try {
        const { roomId } = data;

        const room = RoomManager.getRoom(roomId);
        if (!room) {
          socket.emit("error", { message: "Room not found" });
          return;
        }

        if (room.gameState !== "lobby") {
          socket.emit("error", { message: "Game is not in lobby state" });
          return;
        }

        if (room.players.size < room.minPlayers) {
          socket.emit("error", { message: `Need at least ${room.minPlayers} players to start` });
          return;
        }

        // Force start the game countdown
        RoomManager.startGameCountdown(roomId, io);

      } catch (error) {
        socket.emit("error", { message: error.message });
      }
    });

    // Handle guess submission
    socket.on("submit-guess", async (data) => {
      try {
        const { roomId, guessX, guessY, playerName } = data;

        const room = RoomManager.getRoom(roomId);
        if (!room) {
          socket.emit("error", { message: "Room not found" });
          return;
        }

        if (room.gameState !== "playing") {
          socket.emit("error", { message: "Game is not in playing state" });
          return;
        }

        const player = RoomManager.getPlayer(roomId, playerName);
        if (!player) {
          socket.emit("error", { message: "Player not found in room" });
          return;
        }

        if (player.hasSubmittedGuess) {
          socket.emit("error", { message: "You have already submitted a guess for this round" });
          return;
        }

        const photo = room.currentPhoto;

        console.log(`🎯 Guess submission: Player ${playerName}`);
        console.log(`   Guess coordinates: (${guessX}, ${guessY})`);
        console.log(`   Photo coordinates: (${photo.coordX}, ${photo.coordY})`);

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

        console.log(`   Distance: ${distance.toFixed(2)}m`);
        console.log(`   Points awarded: ${points}`);

        // Update player score
        const updatedPlayer = RoomManager.updatePlayerScore(
          roomId,
          playerName,
          {
            guessX,
            guessY,
            distance,
            points,
          }
        );

        if (!updatedPlayer) {
          socket.emit("error", { message: "Failed to update player score" });
          return;
        }

        // Send result to player
        socket.emit("guess-result", {
          distance: Math.round(distance),
          points,
          actualLocation: {
            x: photo.coordX,
            y: photo.coordY,
          },
          totalScore: updatedPlayer.score,
        });

        // Get updated players list
        const playersArray = Array.from(room.players.values()).map(p => ({
          name: p.name,
          score: p.score,
          isReady: p.isReady,
          hasSubmittedGuess: p.hasSubmittedGuess,
        }));

        // Notify room about the guess
        io.to(roomId).emit("player-guessed", {
          playerName,
          score: updatedPlayer.score,
          guessCount: updatedPlayer.guesses.length,
          players: playersArray,
        });

        // Check if all players have submitted their guesses
        console.log(`🎯 Player ${playerName} submitted guess in room ${roomId}`);
        RoomManager.checkRoundCompletion(roomId, io);

      } catch (error) {
        socket.emit("error", { message: error.message });
      }
    });

    // Handle next round
    socket.on("next-round", async (data) => {
      try {
        const { roomId } = data;

        const result = await RoomManager.nextRound(roomId);
        if (!result) {
          socket.emit("error", { message: "Room not found" });
          return;
        }

        if (result.gameFinished) {
          // Notify all players that game is finished
          io.to(roomId).emit("game-finished", result);
        } else {
          // Start new round timer
          RoomManager.startRoundTimer(roomId, io);

          // Send new round info to all players in room
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
        }
      } catch (error) {
        socket.emit("error", { message: error.message });
      }
    });

    // Handle disconnect
    socket.on("disconnect", () => {
      console.log(`🔌 User disconnected: ${socket.id}`);

      // Find and remove player from any rooms they were in
      const allRooms = RoomManager.getAllRooms();
      for (const room of allRooms) {
        for (const [playerName, player] of room.players) {
          if (player.socketId === socket.id) {
            console.log(`👋 Removing ${playerName} from room ${room.roomId}`);

            // Remove player from room first
            RoomManager.removePlayerFromRoom(room.roomId, playerName);

            // Get updated room info
            const updatedRoom = RoomManager.getRoom(room.roomId);
            if (updatedRoom) {
              const playersArray = Array.from(updatedRoom.players.values()).map(p => ({
                name: p.name,
                score: p.score,
                isReady: p.isReady,
                hasSubmittedGuess: p.hasSubmittedGuess,
              }));

              // Notify other players
              socket.to(room.roomId).emit("player-left", {
                playerName,
                totalPlayers: updatedRoom.players.size,
                players: playersArray,
              });

              // If in lobby, check if remaining players can start
              if (updatedRoom.gameState === "lobby") {
                RoomManager.checkAndStartGame(room.roomId, io);
              }
            }
            break;
          }
        }
      }
    });
  });

  // Cleanup inactive rooms every 5 minutes
  setInterval(() => {
    RoomManager.cleanupInactiveRooms();
  }, 5 * 60 * 1000);
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
