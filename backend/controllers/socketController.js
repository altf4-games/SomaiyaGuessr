const RoomManager = require("../utils/roomManager");

module.exports = (io) => {
  io.on("connection", (socket) => {
    console.log(`User connected: ${socket.id}`);

    socket.on("join-room", async (data) => {
      try {
        const { roomId, playerName } = data;

        const room = RoomManager.getRoom(roomId);
        if (!room) {
          socket.emit("error", { message: "Room not found" });
          return;
        }

        const player = RoomManager.addPlayerToRoom(
          roomId,
          socket.id,
          playerName
        );
        if (!player) {
          socket.emit("error", { message: "Failed to join room" });
          return;
        }

        socket.join(roomId);

        const updatedRoom = RoomManager.getRoom(roomId);
        const playersArray = Array.from(updatedRoom.players.values()).map(
          (p) => ({
            name: p.name,
            score: p.score,
            isReady: p.isReady,
            hasSubmittedGuess: p.hasSubmittedGuess,
          })
        );

        socket.emit("room-joined", {
          roomId: updatedRoom.roomId,
          currentRound: updatedRoom.currentRound,
          totalRounds: updatedRoom.totalRounds,
          gameState: updatedRoom.gameState,
          players: playersArray,
          minPlayers: updatedRoom.minPlayers,
          maxPlayers: updatedRoom.maxPlayers,
          photo:
            updatedRoom.currentPhoto && updatedRoom.gameState === "playing"
              ? {
                  imageUrl: updatedRoom.currentPhoto.imageUrl,
                  location: updatedRoom.currentPhoto.location,
                  difficulty: updatedRoom.currentPhoto.difficulty,
                  coordX: updatedRoom.currentPhoto.coordX,
                  coordY: updatedRoom.currentPhoto.coordY,
                }
              : null,
        });

        socket.to(roomId).emit("player-joined", {
          playerName,
          totalPlayers: updatedRoom.players.size,
          players: playersArray,
        });
      } catch (error) {
        socket.emit("error", { message: error.message });
      }
    });

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

        const player = RoomManager.setPlayerReady(roomId, playerName, isReady);
        if (!player) {
          socket.emit("error", { message: "Player not found in room" });
          return;
        }

        const playersArray = Array.from(room.players.values()).map((p) => ({
          name: p.name,
          score: p.score,
          isReady: p.isReady,
          hasSubmittedGuess: p.hasSubmittedGuess,
        }));

        io.to(roomId).emit("player-ready-changed", {
          playerName,
          isReady,
          players: playersArray,
        });

        RoomManager.checkAndStartGame(roomId, io);
      } catch (error) {
        socket.emit("error", { message: error.message });
      }
    });

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
          socket.emit("error", {
            message: `Need at least ${room.minPlayers} players to start`,
          });
          return;
        }

        RoomManager.startGameCountdown(roomId, io);
      } catch (error) {
        socket.emit("error", { message: error.message });
      }
    });

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
          socket.emit("error", {
            message: "You have already submitted a guess for this round",
          });
          return;
        }

        const photo = room.currentPhoto;

        console.log(`Guess submission: Player ${playerName}`);
        console.log(`   Guess coordinates: (${guessX}, ${guessY})`);
        console.log(`   Photo coordinates: (${photo.coordX}, ${photo.coordY})`);

        const distance = calculateDistance(
          guessX,
          guessY,
          photo.coordY,
          photo.coordX
        );
        const points = calculatePoints(distance);

        console.log(`   Distance: ${distance.toFixed(2)}m`);
        console.log(`   Points awarded: ${points}`);

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

        socket.emit("guess-result", {
          distance: Math.round(distance),
          points,
          actualLocation: {
            x: photo.coordX,
            y: photo.coordY,
          },
          totalScore: updatedPlayer.score,
        });

        const playersArray = Array.from(room.players.values()).map((p) => ({
          name: p.name,
          score: p.score,
          isReady: p.isReady,
          hasSubmittedGuess: p.hasSubmittedGuess,
        }));

        io.to(roomId).emit("player-guessed", {
          playerName,
          score: updatedPlayer.score,
          guessCount: updatedPlayer.guesses.length,
          players: playersArray,
        });

        console.log(`Player ${playerName} submitted guess in room ${roomId}`);
        RoomManager.checkRoundCompletion(roomId, io);
      } catch (error) {
        socket.emit("error", { message: error.message });
      }
    });

    socket.on("next-round", async (data) => {
      try {
        const { roomId } = data;

        const result = await RoomManager.nextRound(roomId);
        if (!result) {
          socket.emit("error", { message: "Room not found" });
          return;
        }

        if (result.gameFinished) {
          io.to(roomId).emit("game-finished", result);
        } else {
          RoomManager.startRoundTimer(roomId, io);

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

    socket.on("disconnect", () => {
      console.log(`User disconnected: ${socket.id}`);

      const allRooms = RoomManager.getAllRooms();
      for (const room of allRooms) {
        for (const [playerName, player] of room.players) {
          if (player.socketId === socket.id) {
            console.log(`Removing ${playerName} from room ${room.roomId}`);

            RoomManager.removePlayerFromRoom(room.roomId, playerName);

            const updatedRoom = RoomManager.getRoom(room.roomId);
            if (updatedRoom) {
              const playersArray = Array.from(updatedRoom.players.values()).map(
                (p) => ({
                  name: p.name,
                  score: p.score,
                  isReady: p.isReady,
                  hasSubmittedGuess: p.hasSubmittedGuess,
                })
              );

              socket.to(room.roomId).emit("player-left", {
                playerName,
                totalPlayers: updatedRoom.players.size,
                players: playersArray,
              });

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

  setInterval(() => {
    RoomManager.cleanupInactiveRooms();
  }, 5 * 60 * 1000);
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
