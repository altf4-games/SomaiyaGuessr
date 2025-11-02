import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/game_models.dart';
import '../services/realtime_game_service.dart';
import '../services/timer_service.dart';

class RealtimeGameProvider extends ChangeNotifier {
  final RealtimeGameService _gameService = RealtimeGameService();
  final TimerService _timerService = TimerService();

  GameRoom? _currentRoom;
  Player? _currentPlayer;
  List<Player> _players = [];
  LatLng? _currentGuess;
  bool _isLoading = false;
  String? _error;
  int _timeLeft = 30;
  RoundResult? _lastRoundResult;

  GameRoom? get currentRoom => _currentRoom;
  Player? get currentPlayer => _currentPlayer;
  List<Player> get players => _players;
  LatLng? get currentGuess => _currentGuess;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasGuess => _currentGuess != null;
  int get timeLeft => _timeLeft;
  RoundResult? get lastRoundResult => _lastRoundResult;
  List<Map<String, dynamic>>? get finalScores => _gameService.finalScores;

  Stream<GameRoom?> get roomStream => _gameService.roomStream;
  Stream<Player?> get playerStream => _gameService.playerStream;
  Stream<List<Player>> get playersStream => _gameService.playersStream;
  Stream<int> get roundTimerStream => _gameService.roundTimerStream;
  Stream<RoundResult?> get roundResultStream => _gameService.roundResultStream;
  Stream<String> get errorStream => _gameService.errorStream;
  Stream<bool> get loadingStream => _gameService.loadingStream;

  Stream<Map<String, dynamic>> get gameStartingStream =>
      _gameService.gameStartingStream;

  RealtimeGameProvider() {
    _setupListeners();
    _initializeService();
  }

  void _initializeService() async {
    await _gameService.initialize();
  }

  void _setupListeners() {
    _gameService.roomStream.listen((room) {
      _currentRoom = room;
      notifyListeners();
    });

    _gameService.playerStream.listen((player) {
      _currentPlayer = player;
      notifyListeners();
    });

    _gameService.playersStream.listen((players) {
      _players = players;
      notifyListeners();
    });

    _gameService.roundTimerStream.listen((timeLeft) {
      _timeLeft = timeLeft;
      notifyListeners();
    });

    _gameService.roundResultStream.listen((result) {
      _lastRoundResult = result;
      notifyListeners();
    });

    _gameService.errorStream.listen((error) {
      _error = error;
      notifyListeners();
    });

    _gameService.loadingStream.listen((loading) {
      _isLoading = loading;
      notifyListeners();
    });
  }

  Future<void> createRoom(String playerName) async {
    _setLoading(true);
    _clearError();
    try {
      await _gameService.createRoom(playerName);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> joinRoom(String roomId, String playerName) async {
    _setLoading(true);
    _clearError();
    try {
      await _gameService.joinRoom(roomId, playerName);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Set player ready status
  void setPlayerReady(bool isReady) {
    _gameService.setPlayerReady(isReady);
  }

  // Start the game (for room creator)
  void startGame() {
    _gameService.startGame();
  }

  // Set player's guess
  void setGuess(LatLng guess) {
    _currentGuess = guess;
    notifyListeners();
  }

  // Submit guess for current round
  void submitGuess() {
    if (_currentGuess != null) {
      _gameService.submitGuess(_currentGuess);
    } else {
      _gameService.submitGuess(null); // Submit null guess
    }
  }

  // Move to next round
  // Note: Round advancement is now handled automatically by the backend
  // No manual nextRound() method needed

  // Clear current guess
  void clearGuess() {
    _currentGuess = null;
    notifyListeners();
  }

  // Reset game state
  void resetGame() {
    _currentRoom = null;
    _currentPlayer = null;
    _players = [];
    _currentGuess = null;
    _lastRoundResult = null;
    _timeLeft = 30;
    _clearError();
    notifyListeners();
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // Public method to clear error
  void clearError() {
    _clearError();
  }

  // Get current location for the round
  Location? getCurrentLocation() {
    if (_currentRoom != null &&
        _currentRoom!.currentRound <= _currentRoom!.locations.length) {
      return _currentRoom!.locations[_currentRoom!.currentRound - 1];
    }
    return null;
  }

  // Getter for current location (to match GameProvider interface)
  Location? get currentLocation => getCurrentLocation();

  // Check if game is in specific state
  bool isInState(GameState state) {
    return _currentRoom?.state == state;
  }

  // Get player by name
  Player? getPlayerByName(String name) {
    try {
      return _players.firstWhere((player) => player.name == name);
    } catch (e) {
      return null;
    }
  }

  // Check if all players are ready (for lobby)
  bool get allPlayersReady {
    if (_players.isEmpty) return false;
    return _players.every((player) => player.isReady);
  }

  // Get ready players count
  int get readyPlayersCount {
    return _players.where((player) => player.isReady).length;
  }

  // Check if current player is ready
  bool get isCurrentPlayerReady {
    return _currentPlayer?.isReady ?? false;
  }

  // Get leaderboard (sorted by score)
  List<Player> get leaderboard {
    final sortedPlayers = List<Player>.from(_players);
    sortedPlayers.sort((a, b) => b.totalScore.compareTo(a.totalScore));
    return sortedPlayers;
  }

  // Get current player's rank
  int get currentPlayerRank {
    if (_currentPlayer == null) return 0;
    final leaderboard = this.leaderboard;
    return leaderboard.indexWhere((player) => player.id == _currentPlayer!.id) +
        1;
  }

  @override
  void dispose() {
    _gameService.dispose();
    _timerService.dispose();
    super.dispose();
  }
}
