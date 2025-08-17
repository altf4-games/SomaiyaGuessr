import 'package:latlong2/latlong.dart';

class GameRoom {
  final String id;
  final String name;
  final List<Player> players;
  final GameState state;
  final int currentRound;
  final int totalRounds;
  final List<Location> locations;

  GameRoom({
    required this.id,
    required this.name,
    required this.players,
    required this.state,
    this.currentRound = 1,
    this.totalRounds = 5,
    required this.locations,
  });

  factory GameRoom.fromJson(Map<String, dynamic> json) {
    return GameRoom(
      id: json['id'],
      name: json['name'],
      players: (json['players'] as List)
          .map((p) => Player.fromJson(p))
          .toList(),
      state: GameState.values[json['state']],
      currentRound: json['currentRound'] ?? 1,
      totalRounds: json['totalRounds'] ?? 5,
      locations: (json['locations'] as List)
          .map((l) => Location.fromJson(l))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'players': players.map((p) => p.toJson()).toList(),
      'state': state.index,
      'currentRound': currentRound,
      'totalRounds': totalRounds,
      'locations': locations.map((l) => l.toJson()).toList(),
    };
  }
}

class Player {
  final String id;
  final String name;
  int totalScore;
  List<RoundResult> roundResults;
  bool isReady;
  bool hasSubmittedGuess;

  Player({
    required this.id,
    required this.name,
    this.totalScore = 0,
    List<RoundResult>? roundResults,
    this.isReady = false,
    this.hasSubmittedGuess = false,
  }) : roundResults = roundResults ?? [];

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'],
      name: json['name'],
      totalScore: json['totalScore'] ?? 0,
      roundResults: (json['roundResults'] as List?)
          ?.map((r) => RoundResult.fromJson(r))
          .toList() ?? [],
      isReady: json['isReady'] ?? false,
      hasSubmittedGuess: json['hasSubmittedGuess'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'totalScore': totalScore,
      'roundResults': roundResults.map((r) => r.toJson()).toList(),
      'isReady': isReady,
      'hasSubmittedGuess': hasSubmittedGuess,
    };
  }
}

class Location {
  final String id;
  final String name;
  final LatLng coordinates;
  final String imageUrl;
  final String description;

  Location({
    required this.id,
    required this.name,
    required this.coordinates,
    required this.imageUrl,
    required this.description,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'],
      name: json['name'],
      coordinates: LatLng(json['lat'], json['lng']),
      imageUrl: json['imageUrl'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'lat': coordinates.latitude,
      'lng': coordinates.longitude,
      'imageUrl': imageUrl,
      'description': description,
    };
  }
}

class RoundResult {
  final int round;
  final LatLng? guessLocation;
  final LatLng actualLocation;
  final double distance;
  final int score;
  final DateTime timestamp;

  RoundResult({
    required this.round,
    this.guessLocation,
    required this.actualLocation,
    required this.distance,
    required this.score,
    required this.timestamp,
  });

  factory RoundResult.fromJson(Map<String, dynamic> json) {
    return RoundResult(
      round: json['round'],
      guessLocation: json['guessLat'] != null && json['guessLng'] != null
          ? LatLng(json['guessLat'], json['guessLng'])
          : null,
      actualLocation: LatLng(json['actualLat'], json['actualLng']),
      distance: json['distance'].toDouble(),
      score: json['score'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'round': round,
      'guessLat': guessLocation?.latitude,
      'guessLng': guessLocation?.longitude,
      'actualLat': actualLocation.latitude,
      'actualLng': actualLocation.longitude,
      'distance': distance,
      'score': score,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

enum GameState {
  waiting,    // Lobby state - players joining and getting ready
  starting,   // 2-second countdown before game starts
  playing,    // Game in progress
  roundResult, // Showing round results
  gameOver,   // Game finished
}
