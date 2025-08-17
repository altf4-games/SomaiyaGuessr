import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiService {
  static const String _baseUrl = 'https://somaiyaguessr.skillversus.xyz/api';

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
  Future<Map<String, dynamic>> joinRoom(String roomId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/game/join-room'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'roomId': roomId}),
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

  // Submit a guess (REST fallback, prefer Socket.IO)
  Future<Map<String, dynamic>> submitGuess({
    required String roomId,
    required String playerName,
    required double guessX,
    required double guessY,
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

  // Move to next round (REST fallback, prefer Socket.IO)
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
