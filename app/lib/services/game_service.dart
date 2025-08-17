import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import '../models/game_models.dart';

class GameService {
  // Static storage to ensure true global sharing
  static final Map<String, GameRoom> _globalRooms = {};
  static final Map<String, Timer?> _globalTimers = {};
  static final Map<String, int> _globalTimeLeft = {};
  static final Map<String, Set<String>> _globalPlayersSubmitted = {};

  static final GameService _instance = GameService._internal();
  factory GameService() => _instance;
  GameService._internal();
  final Distance _distance = const Distance();
  final Uuid _uuid = const Uuid();

  // Backend URL - update this to match your backend
  static const String _backendUrl = 'https://somaiyaguessr.skillversus.xyz';

  // Sample Somaiya campus locations
  final List<Location> _somaiyaLocations = [
    Location(
      id: '1',
      name: 'Main Gate',
      coordinates: const LatLng(19.0728, 72.8997),
      imageUrl: '/placeholder.svg?height=400&width=600',
      description: 'The iconic main entrance of Somaiya Campus',
    ),
    Location(
      id: '2',
      name: 'Library',
      coordinates: const LatLng(19.0730, 72.9000),
      imageUrl: '/placeholder.svg?height=400&width=600',
      description: 'The central library building',
    ),
    Location(
      id: '3',
      name: 'Engineering Block',
      coordinates: const LatLng(19.0725, 72.8995),
      imageUrl: '/placeholder.svg?height=400&width=600',
      description: 'The main engineering department building',
    ),
    Location(
      id: '4',
      name: 'Cafeteria',
      coordinates: const LatLng(19.0732, 72.9002),
      imageUrl: '/placeholder.svg?height=400&width=600',
      description: 'The student cafeteria and dining area',
    ),
    Location(
      id: '5',
      name: 'Sports Complex',
      coordinates: const LatLng(19.0720, 72.8990),
      imageUrl: '/placeholder.svg?height=400&width=600',
      description: 'The sports and recreation complex',
    ),
  ];

  Future<GameRoom> createRoom(String roomName) async {
    final roomId = _uuid.v4();
    final locations = _getRandomLocations(5);

    final room = GameRoom(
      id: roomId,
      name: roomName,
      players: [],
      state: GameState.waiting,
      locations: locations,
    );

    _globalRooms[roomId] = room;
    return room;
  }

  Future<Player> joinRoom(String roomId, String playerName) async {
    print('🎮 GameService: Attempting to join room $roomId');

    // First check if room exists locally
    GameRoom? room = _globalRooms[roomId];

    // If room doesn't exist locally, create a mock room for testing
    if (room == null) {
      print(
        '🏠 GameService: Room $roomId not found locally, creating mock room',
      );
      // Generate locations with backend photos
      final locations = await _generateMockLocations();

      room = GameRoom(
        id: roomId,
        name: 'Room $roomId',
        players: [],
        state: GameState.waiting,
        currentRound: 1,
        totalRounds: 5,
        locations: locations,
      );
      _globalRooms[roomId] = room;
      print(
        '✅ GameService: Created mock room with ${room.locations.length} locations',
      );
    } else {
      print(
        '✅ GameService: Found existing room with ${room.players.length} players',
      );
    }

    final playerId = _uuid.v4();
    final player = Player(id: playerId, name: playerName);

    room.players.add(player);

    // Force update the global room storage
    _globalRooms[roomId] = room;

    print(
      '👤 GameService: Added player ${player.name} to room. Total players: ${room.players.length}',
    );
    print('🎮 All players in room $roomId:');
    for (var p in room.players) {
      print('  - ${p.name} (Ready: ${p.isReady})');
    }
    print('🔍 Global rooms count: ${_globalRooms.length}');

    return player;
  }

  Future<GameRoom> getRoom(String roomId) async {
    final room = _globalRooms[roomId];
    if (room == null) {
      throw Exception('Room not found');
    }
    return room;
  }

  // Update player ready status
  Future<void> setPlayerReady(
    String roomId,
    String playerName,
    bool isReady,
  ) async {
    final room = _globalRooms[roomId];
    if (room == null) {
      throw Exception('Room not found');
    }

    // Find and update the player
    for (var player in room.players) {
      if (player.name == playerName) {
        player.isReady = isReady;
        print('✅ Updated ${player.name} ready status to: $isReady');
        break;
      }
    }

    // Print all players' ready status
    print('🎮 Ready status for room $roomId:');
    for (var p in room.players) {
      print('  - ${p.name}: ${p.isReady ? "Ready" : "Not Ready"}');
    }
  }

  // Start a shared timer for a room
  void startRoomTimer(String roomId, {int duration = 30}) {
    // Stop any existing timer for this room
    stopRoomTimer(roomId);

    _globalTimeLeft[roomId] = duration;
    print('⏰ Starting shared timer for room $roomId: ${duration}s');

    _globalTimers[roomId] = Timer.periodic(const Duration(seconds: 1), (timer) {
      final timeLeft = _globalTimeLeft[roomId];
      if (timeLeft == null || timeLeft <= 0) {
        timer.cancel();
        _globalTimers[roomId] = null;
        _globalTimeLeft[roomId] = 0;
        print('⏰ Timer finished for room $roomId');
        return;
      }

      _globalTimeLeft[roomId] = timeLeft - 1;
      print('⏰ Room $roomId timer: ${_globalTimeLeft[roomId]}s remaining');
    });
  }

  // Stop timer for a room
  void stopRoomTimer(String roomId) {
    final timer = _globalTimers[roomId];
    if (timer != null) {
      timer.cancel();
      _globalTimers[roomId] = null;
      print('⏰ Stopped timer for room $roomId');
    }
  }

  // Get current time left for a room
  int getRoomTimeLeft(String roomId) {
    return _globalTimeLeft[roomId] ?? 0;
  }

  // Check if room has an active timer
  bool hasActiveTimer(String roomId) {
    return _globalTimers[roomId] != null;
  }

  // Check if all players have completed the round
  Future<bool> checkRoundComplete(String roomId) async {
    final room = _globalRooms[roomId];
    if (room == null) {
      print('❌ Room $roomId not found for round completion check');
      return false;
    }

    final submittedPlayers = _globalPlayersSubmitted[roomId] ?? {};
    final totalPlayers = room.players.length;

    // Round is complete if all players submitted OR timer expired
    final allSubmitted =
        submittedPlayers.length >= totalPlayers && totalPlayers > 0;
    final timerExpired = getRoomTimeLeft(roomId) <= 0;

    print(
      '🎮 Round check for $roomId: ${submittedPlayers.length}/$totalPlayers submitted, timer: ${getRoomTimeLeft(roomId)}s',
    );
    print('   - allSubmitted: $allSubmitted, timerExpired: $timerExpired');
    print('   - submitted players: ${submittedPlayers.toList()}');

    if (allSubmitted || timerExpired) {
      print('✅ Round complete! Clearing submissions for next round');
      // Clear submissions for next round
      _globalPlayersSubmitted[roomId] = {};
      return true;
    }

    return false;
  }

  // Fetch random photo from backend
  Future<Map<String, dynamic>?> _fetchRandomPhoto() async {
    try {
      final response = await http.get(
        Uri.parse('$_backendUrl/api/random-photo'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📸 Fetched photo: ${data['location']} - ${data['imageUrl']}');
        return data;
      } else {
        print('❌ Backend returned status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching random photo: $e');
    }
    return null;
  }

  Future<List<Location>> _generateMockLocations() async {
    final locations = <Location>[];

    // Try to fetch 5 random photos from backend
    for (int i = 1; i <= 5; i++) {
      final photoData = await _fetchRandomPhoto();

      if (photoData != null && photoData['photo'] != null) {
        final photo = photoData['photo'];
        locations.add(
          Location(
            id: photo['id']?.toString() ?? i.toString(),
            name: photo['location'] ?? 'Campus Location $i',
            coordinates: LatLng(
              photo['lat']?.toDouble() ?? (19.0760 + (i * 0.001)),
              photo['lng']?.toDouble() ?? (72.8777 + (i * 0.001)),
            ),
            imageUrl:
                photo['imageUrl'] ??
                'https://via.placeholder.com/400x300?text=Location+$i',
            description: photo['description'] ?? 'Campus location $i',
          ),
        );
      } else {
        // Fallback to mock data if backend is not available
        locations.add(
          Location(
            id: i.toString(),
            name: 'Campus Location $i',
            coordinates: LatLng(19.0760 + (i * 0.001), 72.8777 + (i * 0.001)),
            imageUrl: 'https://via.placeholder.com/400x300?text=Location+$i',
            description: 'Campus location $i',
          ),
        );
      }
    }

    return locations;
  }

  Future<void> startGame(String roomId) async {
    final room = _globalRooms[roomId];
    if (room == null) {
      throw Exception('Room not found');
    }

    _globalRooms[roomId] = GameRoom(
      id: room.id,
      name: room.name,
      players: room.players,
      state: GameState.playing,
      currentRound: 1,
      totalRounds: room.totalRounds,
      locations: room.locations,
    );
  }

  Location getCurrentLocation(GameRoom room) {
    if (room.currentRound <= room.locations.length) {
      return room.locations[room.currentRound - 1];
    }
    throw Exception('No more locations available');
  }

  Future<RoundResult> submitGuess(
    String roomId,
    String playerId,
    LatLng? guessLocation,
    LatLng actualLocation,
  ) async {
    final room = _globalRooms[roomId];
    if (room == null) {
      throw Exception('Room not found');
    }

    // Track that this player has submitted
    _globalPlayersSubmitted[roomId] ??= {};
    _globalPlayersSubmitted[roomId]!.add(playerId);

    print(
      '🎮 Player $playerId submitted guess for room $roomId. Total submitted: ${_globalPlayersSubmitted[roomId]!.length}/${room.players.length}',
    );

    double distance = 0;
    int score = 0;

    if (guessLocation != null) {
      distance = _distance.as(LengthUnit.Meter, guessLocation, actualLocation);
      score = _calculateScore(distance);
    }

    return RoundResult(
      round: room.currentRound,
      guessLocation: guessLocation,
      actualLocation: actualLocation,
      distance: distance,
      score: score,
      timestamp: DateTime.now(),
    );
  }

  Future<GameRoom> nextRound(String roomId) async {
    final room = _globalRooms[roomId];
    if (room == null) {
      throw Exception('Room not found');
    }

    final nextRound = room.currentRound + 1;
    final newState = nextRound > room.totalRounds
        ? GameState.gameOver
        : GameState.playing;

    _globalRooms[roomId] = GameRoom(
      id: room.id,
      name: room.name,
      players: room.players,
      state: newState,
      currentRound: nextRound,
      totalRounds: room.totalRounds,
      locations: room.locations,
    );

    return _globalRooms[roomId]!;
  }

  Future<GameRoom> endGame(String roomId) async {
    final room = _globalRooms[roomId];
    if (room == null) {
      throw Exception('Room not found');
    }

    _globalRooms[roomId] = GameRoom(
      id: room.id,
      name: room.name,
      players: room.players,
      state: GameState.gameOver,
      currentRound: room.currentRound,
      totalRounds: room.totalRounds,
      locations: room.locations,
    );

    return _globalRooms[roomId]!;
  }

  Future<void> resetRoom(String roomId) async {
    final room = _globalRooms[roomId];
    if (room == null) {
      throw Exception('Room not found');
    }

    final newLocations = _getRandomLocations(5);
    _globalRooms[roomId] = GameRoom(
      id: room.id,
      name: room.name,
      players: room.players,
      state: GameState.waiting,
      currentRound: 1,
      totalRounds: room.totalRounds,
      locations: newLocations,
    );
  }

  List<Location> _getRandomLocations(int count) {
    final shuffled = List<Location>.from(_somaiyaLocations)..shuffle();
    return shuffled.take(count).toList();
  }

  int _calculateScore(double distanceInMeters) {
    // Much stricter scoring system for more challenging gameplay
    const maxPoints = 1000;

    // Perfect accuracy (within 5 meters) = 1000 points
    if (distanceInMeters <= 5) return maxPoints;

    // Excellent accuracy (5-15 meters) = 800-900 points
    if (distanceInMeters <= 15)
      return (900 - ((distanceInMeters - 5) / 10) * 100).round();

    // Good accuracy (15-30 meters) = 600-800 points
    if (distanceInMeters <= 30)
      return (800 - ((distanceInMeters - 15) / 15) * 200).round();

    // Fair accuracy (30-60 meters) = 300-600 points
    if (distanceInMeters <= 60)
      return (600 - ((distanceInMeters - 30) / 30) * 300).round();

    // Poor accuracy (60-100 meters) = 100-300 points
    if (distanceInMeters <= 100)
      return (300 - ((distanceInMeters - 60) / 40) * 200).round();

    // Very poor accuracy (100-200 meters) = 50-100 points
    if (distanceInMeters <= 200)
      return (100 - ((distanceInMeters - 100) / 100) * 50).round();

    // Terrible accuracy (200+ meters) = 0-50 points
    if (distanceInMeters <= 500)
      return (50 - ((distanceInMeters - 200) / 300) * 50).round();

    // Beyond 500 meters = 0 points
    return 0;
  }
}
