import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiService {
  // static const String _baseUrl = 'https://somaiyaguessr.skillversus.xyz/api';
  static const String _baseUrl = 'http://localhost:3000/api';

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Create a new room
  Future<Map<String, dynamic>> createRoom() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/game/create-room'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create room: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating room: $e');
      }
      throw Exception('Failed to create room: $e');
    }
  }

  // Join an existing room
  Future<Map<String, dynamic>> joinRoom(
    String roomId,
    String playerName,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/game/join-room'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'roomId': roomId, 'playerName': playerName}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['error'] ?? 'Failed to join room');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error joining room: $e');
      }
      throw Exception('Failed to join room: $e');
    }
  }

  // Leave a room
  Future<void> leaveRoom(String roomId, String playerName) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/game/leave-room'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'roomId': roomId, 'playerName': playerName}),
      );

      if (response.statusCode != 200) {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['error'] ?? 'Failed to leave room');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error leaving room: $e');
      }
      // Don't throw - leaving room should fail silently
    }
  }

  // Set player ready status
  Future<Map<String, dynamic>> setPlayerReady(
    String roomId,
    String playerName,
    bool isReady,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/game/player-ready'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'roomId': roomId,
          'playerName': playerName,
          'isReady': isReady,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['error'] ?? 'Failed to set ready status');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting ready status: $e');
      }
      throw Exception('Failed to set ready status: $e');
    }
  }

  // Start game
  Future<Map<String, dynamic>> startGame(String roomId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/game/start-game'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'roomId': roomId}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['error'] ?? 'Failed to start game');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error starting game: $e');
      }
      throw Exception('Failed to start game: $e');
    }
  }

  // Get a random photo (for testing)
  Future<Map<String, dynamic>> getRandomPhoto() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/game/random-photo'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get random photo: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting random photo: $e');
      }
      throw Exception('Failed to get random photo: $e');
    }
  }

  // Submit a guess
  Future<Map<String, dynamic>> submitGuess({
    required String roomId,
    required String playerName,
    double? guessX,
    double? guessY,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/game/submit-guess'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'roomId': roomId,
          'playerName': playerName,
          'guessX': guessX,
          'guessY': guessY,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['error'] ?? 'Failed to submit guess');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error submitting guess: $e');
      }
      throw Exception('Failed to submit guess: $e');
    }
  }

  // Move to next round
  Future<Map<String, dynamic>> nextRound(String roomId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/game/next-round'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'roomId': roomId}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['error'] ?? 'Failed to move to next round');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error moving to next round: $e');
      }
      throw Exception('Failed to move to next round: $e');
    }
  }

  // Get room state (for polling/fallback)
  Future<Map<String, dynamic>> getRoomState(String roomId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/game/room/$roomId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['error'] ?? 'Failed to get room state');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting room state: $e');
      }
      throw Exception('Failed to get room state: $e');
    }
  }

  // Get room statistics (for debugging)
  Future<Map<String, dynamic>> getRoomStats() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/game/room-stats'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get room stats: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting room stats: $e');
      }
      throw Exception('Failed to get room stats: $e');
    }
  }

  // Cleanup rooms (admin function)
  Future<Map<String, dynamic>> cleanupRooms() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/game/cleanup-rooms'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to cleanup rooms: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error cleaning up rooms: $e');
      }
      throw Exception('Failed to cleanup rooms: $e');
    }
  }
}
