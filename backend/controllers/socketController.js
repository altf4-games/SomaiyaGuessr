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
        RoomManager.addPlayerToRoom(roomId, socket.id, playerName);

        socket.join(roomId);

        // Send room info to player
        socket.emit("room-joined", {
          roomId: room.roomId,
          currentRound: room.currentRound,
          totalRounds: room.totalRounds,
          gameState: room.gameState,
          photo: room.currentPhoto
            ? {
                imageUrl: room.currentPhoto.imageUrl,
                location: room.currentPhoto.location,
              }
            : null,
        });

        // Notify other players
        socket.to(roomId).emit("player-joined", {
          playerName,
          totalPlayers: room.players.size,
        });
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

        const photo = room.currentPhoto;
        const distance = calculateDistance(
          guessX,
          guessY,
          photo.coordX,
          photo.coordY
        );
        const points = calculatePoints(distance);

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
          socket.emit("error", { message: "Player not found in room" });
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

        // Notify room about the guess
        io.to(roomId).emit("player-guessed", {
          playerName,
          score: updatedPlayer.score,
          guessCount: updatedPlayer.guesses.length,
        });
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
          // Send new round info to all players in room
          io.to(roomId).emit("new-round", {
            currentRound: result.currentRound,
            totalRounds: result.totalRounds,
            photo: {
              imageUrl: result.currentPhoto.imageUrl,
              location: result.currentPhoto.location,
              difficulty: result.currentPhoto.difficulty,
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

            // Notify other players
            socket.to(room.roomId).emit("player-left", {
              playerName,
              totalPlayers: room.players.size - 1,
            });

            // Remove player from room
            RoomManager.removePlayerFromRoom(room.roomId, playerName);
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
function calculateDistance(x1, y1, x2, y2) {
  return Math.sqrt(Math.pow(x2 - x1, 2) + Math.pow(y2 - y1, 2));
}

function calculatePoints(distance) {
  const maxPoints = 1000;
  const maxDistance = 500;

  if (distance <= 10) return maxPoints;
  if (distance >= maxDistance) return 0;

  return Math.round(maxPoints * (1 - distance / maxDistance));
}
