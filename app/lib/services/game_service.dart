import 'dart:math';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import '../models/game_models.dart';

class GameService {
  static final GameService _instance = GameService._internal();
  factory GameService() => _instance;
  GameService._internal();

  final Map<String, GameRoom> _rooms = {};
  final Distance _distance = const Distance();
  final Uuid _uuid = const Uuid();

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

    _rooms[roomId] = room;
    return room;
  }

  Future<Player> joinRoom(String roomId, String playerName) async {
    final room = _rooms[roomId];
    if (room == null) {
      throw Exception('Room not found');
    }

    final playerId = _uuid.v4();
    final player = Player(id: playerId, name: playerName);
    
    room.players.add(player);
    return player;
  }

  Future<GameRoom> getRoom(String roomId) async {
    final room = _rooms[roomId];
    if (room == null) {
      throw Exception('Room not found');
    }
    return room;
  }

  Future<void> startGame(String roomId) async {
    final room = _rooms[roomId];
    if (room == null) {
      throw Exception('Room not found');
    }

    _rooms[roomId] = GameRoom(
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
    final room = _rooms[roomId];
    if (room == null) {
      throw Exception('Room not found');
    }

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
    final room = _rooms[roomId];
    if (room == null) {
      throw Exception('Room not found');
    }

    final nextRound = room.currentRound + 1;
    final newState = nextRound > room.totalRounds 
        ? GameState.gameOver 
        : GameState.playing;

    _rooms[roomId] = GameRoom(
      id: room.id,
      name: room.name,
      players: room.players,
      state: newState,
      currentRound: nextRound,
      totalRounds: room.totalRounds,
      locations: room.locations,
    );

    return _rooms[roomId]!;
  }

  Future<GameRoom> endGame(String roomId) async {
    final room = _rooms[roomId];
    if (room == null) {
      throw Exception('Room not found');
    }

    _rooms[roomId] = GameRoom(
      id: room.id,
      name: room.name,
      players: room.players,
      state: GameState.gameOver,
      currentRound: room.currentRound,
      totalRounds: room.totalRounds,
      locations: room.locations,
    );

    return _rooms[roomId]!;
  }

  Future<void> resetRoom(String roomId) async {
    final room = _rooms[roomId];
    if (room == null) {
      throw Exception('Room not found');
    }

    final newLocations = _getRandomLocations(5);
    _rooms[roomId] = GameRoom(
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
    // Score calculation: max 1000 points, decreasing with distance
    if (distanceInMeters <= 10) return 1000;
    if (distanceInMeters <= 50) return 900;
    if (distanceInMeters <= 100) return 800;
    if (distanceInMeters <= 200) return 700;
    if (distanceInMeters <= 500) return 500;
    if (distanceInMeters <= 1000) return 300;
    if (distanceInMeters <= 2000) return 100;
    return 50;
  }
}
