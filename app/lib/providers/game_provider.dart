import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/game_models.dart';
import '../services/game_service.dart';

class GameProvider extends ChangeNotifier {
  final GameService _gameService = GameService();
  
  GameRoom? _currentRoom;
  Player? _currentPlayer;
  Location? _currentLocation;
  LatLng? _currentGuess;
  bool _isLoading = false;
  String? _error;
  bool _disposed = false; // Added disposal flag to prevent framework errors

  // Getters
  GameRoom? get currentRoom => _currentRoom;
  Player? get currentPlayer => _currentPlayer;
  Location? get currentLocation => _currentLocation;
  LatLng? get currentGuess => _currentGuess;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasGuess => _currentGuess != null;
  GameService get gameService => _gameService;

  Future<void> createGuestRoom(String playerName) async {
    _setLoading(true);
    try {
      final roomName = 'Guest Room - ${DateTime.now().millisecondsSinceEpoch}';
      final room = await _gameService.createRoom(roomName);
      final player = await _gameService.joinRoom(room.id, playerName.isEmpty ? 'Guest Player' : playerName);
      
      _currentRoom = room;
      _currentPlayer = player;
      _error = null;
      
      _safeNotifyListeners();
    } catch (e) {
      _error = e.toString();
      _safeNotifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Create a new room
  Future<void> createRoom(String roomName, String playerName) async {
    _setLoading(true);
    try {
      final room = await _gameService.createRoom(roomName);
      final player = await _gameService.joinRoom(room.id, playerName);
      
      _currentRoom = room;
      _currentPlayer = player;
      _error = null;
      
      _safeNotifyListeners();
    } catch (e) {
      _error = e.toString();
      _safeNotifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Join an existing room
  Future<void> joinRoom(String roomId, String playerName) async {
    _setLoading(true);
    _error = null; // Clear any previous errors

    try {
      print('🔍 Attempting to join room: $roomId with player: $playerName');

      final player = await _gameService.joinRoom(roomId, playerName);
      print('✅ Successfully joined room as player: ${player.name}');

      final room = await _gameService.getRoom(roomId);
      print('✅ Retrieved room data: ${room.name} with ${room.players.length} players');

      _currentRoom = room;
      _currentPlayer = player;
      _error = null;

      _safeNotifyListeners();
    } catch (e) {
      print('❌ Error joining room: $e');
      _error = 'Failed to join room: ${e.toString()}';
      _safeNotifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Start the game
  Future<void> startGame() async {
    if (_currentRoom == null) return;
    
    _setLoading(true);
    try {
      await _gameService.startGame(_currentRoom!.id);
      _currentLocation = _gameService.getCurrentLocation(_currentRoom!);
      _currentRoom = await _gameService.getRoom(_currentRoom!.id);
      
      _safeNotifyListeners();
    } catch (e) {
      _error = e.toString();
      _safeNotifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Set player ready status
  Future<void> setPlayerReady(String roomId, String playerName, bool isReady) async {
    try {
      await _gameService.setPlayerReady(roomId, playerName, isReady);
      // Refresh the room data to get updated player states
      _currentRoom = await _gameService.getRoom(roomId);
      _safeNotifyListeners();
    } catch (e) {
      print('❌ Error setting player ready: $e');
      _error = e.toString();
      _safeNotifyListeners();
    }
  }

  // Update current room (for refreshing data)
  void updateCurrentRoom(GameRoom room) {
    _currentRoom = room;
    print('🔄 GameProvider: Updated room ${room.id} with ${room.players.length} players');
    _safeNotifyListeners();
  }

  // Start shared timer for room
  void startRoomTimer(String roomId, {int duration = 30}) {
    _gameService.startRoomTimer(roomId, duration: duration);
  }

  // Get current timer value for room
  int getRoomTimeLeft(String roomId) {
    return _gameService.getRoomTimeLeft(roomId);
  }

  // Check if room has active timer
  bool hasActiveTimer(String roomId) {
    return _gameService.hasActiveTimer(roomId);
  }

  // Check if all players have completed the round
  Future<bool> checkRoundComplete(String roomId) async {
    return await _gameService.checkRoundComplete(roomId);
  }

  // Set player's guess
  void setGuess(LatLng guess) {
    _currentGuess = guess;
    _safeNotifyListeners();
  }

  // Submit guess for current round
  Future<RoundResult?> submitGuess() async {
    if (_currentRoom == null || _currentPlayer == null || _currentLocation == null) {
      return null;
    }

    _setLoading(true);
    try {
      final result = await _gameService.submitGuess(
        _currentRoom!.id,
        _currentPlayer!.id,
        _currentGuess,
        _currentLocation!.coordinates,
      );

      // Update player's results
      _currentPlayer!.roundResults.add(result);
      _currentPlayer!.totalScore += result.score;

      _safeNotifyListeners();
      return result;
    } catch (e) {
      _error = e.toString();
      _safeNotifyListeners();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Move to next round
  Future<void> nextRound() async {
    if (_currentRoom == null) return;

    _setLoading(true);
    try {
      _currentGuess = null;
      _currentRoom = await _gameService.nextRound(_currentRoom!.id);
      
      if (_currentRoom!.state == GameState.playing) {
        _currentLocation = _gameService.getCurrentLocation(_currentRoom!);
      } else {
        _currentLocation = null;
      }

      _safeNotifyListeners();
    } catch (e) {
      _error = e.toString();
      _safeNotifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> endGame() async {
    if (_currentRoom == null) return;

    _setLoading(true);
    try {
      _currentRoom = await _gameService.endGame(_currentRoom!.id);
      _currentLocation = null;
      _currentGuess = null;
      
      _safeNotifyListeners();
    } catch (e) {
      _error = e.toString();
      _safeNotifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> startNewGame() async {
    if (_currentRoom == null) return;

    _setLoading(true);
    try {
      await _gameService.resetRoom(_currentRoom!.id);
      _currentRoom = await _gameService.getRoom(_currentRoom!.id);
      
      // Reset player scores for new game
      if (_currentPlayer != null) {
        _currentPlayer!.roundResults.clear();
        _currentPlayer!.totalScore = 0;
      }
      
      // Start the new game immediately
      await _gameService.startGame(_currentRoom!.id);
      _currentLocation = _gameService.getCurrentLocation(_currentRoom!);
      _currentRoom = await _gameService.getRoom(_currentRoom!.id);
      _currentGuess = null;
      
      _safeNotifyListeners();
    } catch (e) {
      _error = e.toString();
      _safeNotifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Reset game state
  void resetGame() {
    _currentRoom = null;
    _currentPlayer = null;
    _currentLocation = null;
    _currentGuess = null;
    _error = null;
    _safeNotifyListeners();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    _safeNotifyListeners();
  }

  void _safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    _safeNotifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
