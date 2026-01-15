import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../models/game_models.dart';
import 'pusher_service.dart';
import 'api_service.dart';

class RealtimeGameService {
  final PusherService _pusherService = PusherService();
  final ApiService _apiService = ApiService();

  // Current game state
  GameRoom? _currentRoom;
  Player? _currentPlayer;
  String? _currentPlayerName;
  List<Map<String, dynamic>>? _finalScores;

  // Local timer management
  Timer? _roundTimer;
  int _currentTimeLeft = 0;
  int _roundDuration = 30; // Default 30 seconds
  bool _hasSubmittedCurrentRound = false;

  // Stream controllers for game state changes
  final StreamController<GameRoom?> _roomController =
      StreamController.broadcast();
  final StreamController<Player?> _playerController =
      StreamController.broadcast();
  final StreamController<List<Player>> _playersController =
      StreamController.broadcast();
  final StreamController<int> _roundTimerController =
      StreamController.broadcast();
  final StreamController<RoundResult?> _roundResultController =
      StreamController.broadcast();
  final StreamController<String> _errorController =
      StreamController.broadcast();
  final StreamController<bool> _loadingController =
      StreamController.broadcast();

  // Getters for streams
  Stream<GameRoom?> get roomStream => _roomController.stream;
  Stream<Player?> get playerStream => _playerController.stream;
  Stream<List<Player>> get playersStream => _playersController.stream;
  Stream<int> get roundTimerStream => _roundTimerController.stream;
  Stream<RoundResult?> get roundResultStream => _roundResultController.stream;
  Stream<String> get errorStream => _errorController.stream;
  Stream<bool> get loadingStream => _loadingController.stream;

  // Additional streams for lobby functionality
  Stream<Map<String, dynamic>> get gameStartingStream =>
      _pusherService.gameStarting;
  Stream<Map<String, dynamic>> get playerJoinedStream =>
      _pusherService.playerJoined;
  Stream<Map<String, dynamic>> get playerLeftStream =>
      _pusherService.playerLeft;
  Stream<Map<String, dynamic>> get playerReadyStream =>
      _pusherService.playerReady;

  // Getters for current state
  GameRoom? get currentRoom => _currentRoom;
  Player? get currentPlayer => _currentPlayer;
  String? get currentPlayerName => _currentPlayerName;
  List<Map<String, dynamic>>? get finalScores => _finalScores;

  // Singleton pattern
  static final RealtimeGameService _instance = RealtimeGameService._internal();
  factory RealtimeGameService() => _instance;
  RealtimeGameService._internal() {
    _setupPusherListeners();
  }

  Future<void> initialize() async {
    _setLoading(true);
    try {
      await _pusherService.connect();
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _errorController.add('Failed to connect to server: $e');
    }
  }

  void _setupPusherListeners() {
    // Player joined/left
    _pusherService.playerJoined.listen((data) {
      _updatePlayersFromData(data);
    });

    _pusherService.playerLeft.listen((data) {
      _updatePlayersFromData(data);
    });

    // Player ready status changed
    _pusherService.playerReady.listen((data) {
      _updatePlayersFromData(data);
    });

    // Game starting countdown
    _pusherService.gameStarting.listen((data) {
      final countdown = data['countdown'] as int?;
      if (countdown != null && _currentRoom != null) {
        _currentRoom = GameRoom(
          id: _currentRoom!.id,
          name: _currentRoom!.name,
          players: _currentRoom!.players,
          state: GameState.starting,
          currentRound: _currentRoom!.currentRound,
          totalRounds: _currentRoom!.totalRounds,
          locations: _currentRoom!.locations,
        );
        _roomController.add(_currentRoom);
      }
    });

    // Game started
    _pusherService.gameStarted.listen((data) {
      _updateRoomFromData(data);
      _updatePlayersFromData(data);
      _hasSubmittedCurrentRound = false;
      _startLocalTimer(data);
    });

    // Round timer - ignore server timer events (using local timer)
    _pusherService.roundTimer.listen((data) {
      // Server timer events are ignored - we use local timer
      // This is kept for backwards compatibility
    });

    // Player guessed
    _pusherService.playerGuessed.listen((data) {
      _updatePlayersFromData(data);
    });

    // Round ended
    _pusherService.roundEnded.listen((data) {
      _stopLocalTimer(); // Stop timer when round ends
      if (_currentRoom != null) {
        _currentRoom = GameRoom(
          id: _currentRoom!.id,
          name: _currentRoom!.name,
          players: _currentRoom!.players,
          state: GameState.roundResult,
          currentRound: _currentRoom!.currentRound,
          totalRounds: _currentRoom!.totalRounds,
          locations: _currentRoom!.locations,
        );
        _roomController.add(_currentRoom);
      }
    });

    // New round
    _pusherService.newRound.listen((data) {
      _updateRoomFromNewRound(data);
      _hasSubmittedCurrentRound = false;
      _startLocalTimer(data);
    });

    // Game finished
    _pusherService.gameFinished.listen((data) {
      _stopLocalTimer(); // Stop timer when game ends
      if (_currentRoom != null) {
        // Store final scores
        _finalScores = (data['finalScores'] as List<dynamic>?)
            ?.map((score) => Map<String, dynamic>.from(score))
            .toList();

        _currentRoom = GameRoom(
          id: _currentRoom!.id,
          name: _currentRoom!.name,
          players: _currentRoom!.players,
          state: GameState.gameOver,
          currentRound: _currentRoom!.currentRound,
          totalRounds: _currentRoom!.totalRounds,
          locations: _currentRoom!.locations,
        );
        _roomController.add(_currentRoom);
      }
    });

    // Errors
    _pusherService.error.listen((error) {
      _errorController.add(error);
    });
  }

  Future<void> createRoom(String playerName) async {
    _setLoading(true);
    try {
      _currentPlayerName = playerName;

      // Create room via REST API
      final roomData = await _apiService.createRoom();
      final roomId = roomData['roomId'] as String;

      // Subscribe to Pusher channel
      await _pusherService.subscribeToRoom(roomId);

      // Join the room via REST API
      final joinData = await _apiService.joinRoom(roomId, playerName);

      // Update room state from response
      _updateRoomFromData(joinData);
      _updatePlayersFromData(joinData);

      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _errorController.add('Failed to create room: $e');
    }
  }

  Future<void> joinRoom(String roomId, String playerName) async {
    _setLoading(true);
    try {
      _currentPlayerName = playerName;

      // Subscribe to Pusher channel first
      await _pusherService.subscribeToRoom(roomId);

      // Join room via REST API
      final joinData = await _apiService.joinRoom(roomId, playerName);

      // Update room state from response
      _updateRoomFromData(joinData);
      _updatePlayersFromData(joinData);

      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _errorController.add('Failed to join room: $e');
    }
  }

  Future<void> leaveRoom() async {
    if (_currentRoom != null && _currentPlayerName != null) {
      _stopLocalTimer();
      await _apiService.leaveRoom(_currentRoom!.id, _currentPlayerName!);
      await _pusherService.unsubscribeFromRoom();
      _currentRoom = null;
      _currentPlayer = null;
      _currentPlayerName = null;
      _hasSubmittedCurrentRound = false;
      _roomController.add(null);
    }
  }

  Future<void> setPlayerReady(bool isReady) async {
    if (_currentRoom != null && _currentPlayerName != null) {
      try {
        await _apiService.setPlayerReady(
          _currentRoom!.id,
          _currentPlayerName!,
          isReady,
        );
      } catch (e) {
        _errorController.add('Failed to set ready status: $e');
      }
    }
  }

  Future<void> startGame() async {
    if (_currentRoom != null) {
      try {
        await _apiService.startGame(_currentRoom!.id);
      } catch (e) {
        _errorController.add('Failed to start game: $e');
      }
    }
  }

  Future<void> submitGuess(LatLng? guessLocation) async {
    if (_currentRoom != null && _currentPlayerName != null) {
      try {
        _hasSubmittedCurrentRound = true; // Mark as submitted before API call

        final result = await _apiService.submitGuess(
          roomId: _currentRoom!.id,
          playerName: _currentPlayerName!,
          guessX: guessLocation?.longitude,
          guessY: guessLocation?.latitude,
        );

        // Process guess result
        final distance = (result['distance'] as num?)?.toDouble() ?? 0.0;
        final points = (result['points'] as num?)?.toInt() ?? 0;
        final actualLocation =
            result['actualLocation'] as Map<String, dynamic>?;

        if (actualLocation != null && _currentPlayer != null) {
          final roundResult = RoundResult(
            round: _currentRoom?.currentRound ?? 1,
            guessLocation: guessLocation,
            actualLocation: LatLng(
              (actualLocation['y'] as num).toDouble(),
              (actualLocation['x'] as num).toDouble(),
            ),
            distance: distance,
            score: points,
            timestamp: DateTime.now(),
          );

          _roundResultController.add(roundResult);

          // Update player score
          if (_currentPlayer != null) {
            _currentPlayer!.totalScore =
                (result['totalScore'] as num?)?.toInt() ??
                _currentPlayer!.totalScore;
            _playerController.add(_currentPlayer);
          }
        }
      } catch (e) {
        _errorController.add('Failed to submit guess: $e');
      }
    }
  }

  void _updateRoomFromData(Map<String, dynamic> data) {
    final roomId = data['roomId'] as String?;
    final gameState = data['gameState'] as String?;
    final currentRound = data['currentRound'] as int? ?? 1;
    final totalRounds = data['totalRounds'] as int? ?? 5;
    final photoData = data['photo'] as Map<String, dynamic>?;

    if (roomId != null) {
      final state = _parseGameState(gameState);

      // Extract photo data and create location if available
      List<Location> locations = _currentRoom?.locations ?? [];
      if (photoData != null && state == GameState.playing) {
        final location = _createLocationFromPhotoData(photoData, currentRound);
        if (location != null) {
          // Update or add the current round's location
          if (locations.length >= currentRound) {
            locations[currentRound - 1] = location;
          } else {
            // Pad with empty locations if needed
            while (locations.length < currentRound - 1) {
              locations.add(_createPlaceholderLocation(locations.length + 1));
            }
            locations.add(location);
          }
        }
      }

      _currentRoom = GameRoom(
        id: roomId,
        name: roomId,
        players: _currentRoom?.players ?? [],
        state: state,
        currentRound: currentRound,
        totalRounds: totalRounds,
        locations: locations,
      );

      _roomController.add(_currentRoom);
    }
  }

  void _updateRoomFromNewRound(Map<String, dynamic> data) {
    final currentRound = data['currentRound'] as int? ?? 1;
    final totalRounds = data['totalRounds'] as int? ?? 5;
    final photoData = data['photo'] as Map<String, dynamic>?;

    if (_currentRoom != null) {
      List<Location> locations = List.from(_currentRoom!.locations);

      // Extract photo data and create location for new round
      if (photoData != null) {
        final location = _createLocationFromPhotoData(photoData, currentRound);
        if (location != null) {
          // Update or add the current round's location
          if (locations.length >= currentRound) {
            locations[currentRound - 1] = location;
          } else {
            // Pad with empty locations if needed
            while (locations.length < currentRound - 1) {
              locations.add(_createPlaceholderLocation(locations.length + 1));
            }
            locations.add(location);
          }
        }
      }

      _currentRoom = GameRoom(
        id: _currentRoom!.id,
        name: _currentRoom!.name,
        players: _currentRoom!.players,
        state: GameState.playing,
        currentRound: currentRound,
        totalRounds: totalRounds,
        locations: locations,
      );
      _roomController.add(_currentRoom);
    }
  }

  void _updatePlayersFromData(Map<String, dynamic> data) {
    final playersData = data['players'] as List<dynamic>?;

    if (playersData != null) {
      final players = playersData.map((playerData) {
        final playerMap = playerData as Map<String, dynamic>;
        final player = Player(
          id: playerMap['name'],
          name: playerMap['name'],
          totalScore: playerMap['score'] ?? 0,
          isReady: playerMap['isReady'] ?? false,
          hasSubmittedGuess: playerMap['hasSubmittedGuess'] ?? false,
        );

        // Update current player if this is them
        if (player.name == _currentPlayerName) {
          _currentPlayer = player;
          _playerController.add(_currentPlayer);
        }

        return player;
      }).toList();

      if (_currentRoom != null) {
        _currentRoom = GameRoom(
          id: _currentRoom!.id,
          name: _currentRoom!.name,
          players: players,
          state: _currentRoom!.state,
          currentRound: _currentRoom!.currentRound,
          totalRounds: _currentRoom!.totalRounds,
          locations: _currentRoom!.locations,
        );
        _roomController.add(_currentRoom);
      }

      _playersController.add(players);
    }
  }

  GameState _parseGameState(String? gameState) {
    switch (gameState) {
      case 'lobby':
        return GameState.waiting;
      case 'starting':
        return GameState.starting;
      case 'playing':
        return GameState.playing;
      case 'finished':
        return GameState.gameOver;
      default:
        return GameState.waiting;
    }
  }

  void _setLoading(bool loading) {
    _loadingController.add(loading);
  }

  // Start local timer based on server's roundStartTime and roundDuration
  void _startLocalTimer(Map<String, dynamic> data) {
    _stopLocalTimer();

    // Get round duration from server (in milliseconds, convert to seconds)
    final durationMs = data['roundDuration'] as int? ?? 30000;
    _roundDuration = durationMs ~/ 1000;

    // Get round start time from server
    final roundStartTimeStr = data['roundStartTime'] as String?;
    DateTime roundStartTime;
    if (roundStartTimeStr != null) {
      roundStartTime = DateTime.parse(roundStartTimeStr);
    } else {
      roundStartTime = DateTime.now();
    }

    // Calculate initial time left based on server time
    final now = DateTime.now();
    final elapsed = now.difference(roundStartTime).inSeconds;
    _currentTimeLeft = (_roundDuration - elapsed).clamp(0, _roundDuration);

    if (kDebugMode) {
      print('⏱️ Starting local timer: $_currentTimeLeft seconds remaining');
      print('   Round start: $roundStartTime, Duration: $_roundDuration s');
    }

    // Emit initial time
    _roundTimerController.add(_currentTimeLeft);

    // Start the timer
    _roundTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _currentTimeLeft--;
      _roundTimerController.add(_currentTimeLeft);

      if (_currentTimeLeft <= 0) {
        timer.cancel();
        _onTimerExpired();
      }
    });
  }

  void _stopLocalTimer() {
    _roundTimer?.cancel();
    _roundTimer = null;
  }

  // Called when local timer expires
  void _onTimerExpired() {
    if (kDebugMode) {
      print('⏱️ Local timer expired');
    }

    // If player hasn't submitted yet, notify the server
    if (!_hasSubmittedCurrentRound &&
        _currentRoom != null &&
        _currentPlayerName != null) {
      if (kDebugMode) {
        print('⏱️ Auto-submitting due to time expiry');
      }
      _apiService.timeExpired(_currentRoom!.id, _currentPlayerName!);
    }
  }

  // Helper method to create Location from backend photo data
  Location? _createLocationFromPhotoData(
    Map<String, dynamic> photoData,
    int round,
  ) {
    try {
      final imageUrl = photoData['imageUrl'] as String?;
      final locationName = photoData['location'] as String?;
      final coordX = photoData['coordX'] as num?;
      final coordY = photoData['coordY'] as num?;

      if (imageUrl == null) {
        if (kDebugMode) {
          print('❌ No imageUrl in photo data: $photoData');
        }
        return null;
      }

      // Backend stores: coordX=latitude, coordY=longitude
      final lat = coordX?.toDouble() ?? (19.0760 + (round * 0.001));
      final lng = coordY?.toDouble() ?? (72.8777 + (round * 0.001));

      if (kDebugMode) {
        print(
          '📍 Creating location: $locationName at ($lat, $lng) with image: $imageUrl',
        );
      }

      return Location(
        id: 'round_$round',
        name: locationName ?? 'Campus Location $round',
        coordinates: LatLng(lat, lng),
        imageUrl: imageUrl,
        description: locationName ?? 'Campus location for round $round',
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating location from photo data: $e');
      }
      return null;
    }
  }

  // Helper method to create placeholder location
  Location _createPlaceholderLocation(int round) {
    final defaultLat = 19.0760 + (round * 0.001);
    final defaultLng = 72.8777 + (round * 0.001);

    return Location(
      id: 'placeholder_$round',
      name: 'Loading...',
      coordinates: LatLng(defaultLat, defaultLng),
      imageUrl: 'https://via.placeholder.com/400x300?text=Loading...',
      description: 'Loading location data...',
    );
  }

  void dispose() {
    _stopLocalTimer();
    _pusherService.dispose();
    _roomController.close();
    _playerController.close();
    _playersController.close();
    _roundTimerController.close();
    _roundResultController.close();
    _errorController.close();
    _loadingController.close();
  }
}
