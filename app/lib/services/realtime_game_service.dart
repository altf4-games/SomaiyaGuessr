import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../models/game_models.dart';
import 'socket_service.dart';
import 'api_service.dart';

class RealtimeGameService {
  final SocketService _socketService = SocketService();
  final ApiService _apiService = ApiService();
  
  // Current game state
  GameRoom? _currentRoom;
  Player? _currentPlayer;
  String? _currentPlayerName;
  List<Map<String, dynamic>>? _finalScores;
  
  // Stream controllers for game state changes
  final StreamController<GameRoom?> _roomController = StreamController.broadcast();
  final StreamController<Player?> _playerController = StreamController.broadcast();
  final StreamController<List<Player>> _playersController = StreamController.broadcast();
  final StreamController<int> _roundTimerController = StreamController.broadcast();
  final StreamController<RoundResult?> _roundResultController = StreamController.broadcast();
  final StreamController<String> _errorController = StreamController.broadcast();
  final StreamController<bool> _loadingController = StreamController.broadcast();

  // Getters for streams
  Stream<GameRoom?> get roomStream => _roomController.stream;
  Stream<Player?> get playerStream => _playerController.stream;
  Stream<List<Player>> get playersStream => _playersController.stream;
  Stream<int> get roundTimerStream => _roundTimerController.stream;
  Stream<RoundResult?> get roundResultStream => _roundResultController.stream;
  Stream<String> get errorStream => _errorController.stream;
  Stream<bool> get loadingStream => _loadingController.stream;

  // Additional streams for lobby functionality
  Stream<Map<String, dynamic>> get gameStartingStream => _socketService.gameStarting;
  Stream<Map<String, dynamic>> get playerJoinedStream => _socketService.playerJoined;
  Stream<Map<String, dynamic>> get playerLeftStream => _socketService.playerLeft;
  Stream<Map<String, dynamic>> get playerReadyStream => _socketService.playerReady;

  // Getters for current state
  GameRoom? get currentRoom => _currentRoom;
  Player? get currentPlayer => _currentPlayer;
  String? get currentPlayerName => _currentPlayerName;
  List<Map<String, dynamic>>? get finalScores => _finalScores;

  // Singleton pattern
  static final RealtimeGameService _instance = RealtimeGameService._internal();
  factory RealtimeGameService() => _instance;
  RealtimeGameService._internal() {
    _setupSocketListeners();
  }

  Future<void> initialize() async {
    _setLoading(true);
    try {
      await _socketService.connect();
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _errorController.add('Failed to connect to server: $e');
    }
  }

  void _setupSocketListeners() {
    // Room joined
    _socketService.roomJoined.listen((data) {
      _updateRoomFromData(data);
      _updatePlayersFromData(data);
    });

    // Player joined/left
    _socketService.playerJoined.listen((data) {
      _updatePlayersFromData(data);
    });

    _socketService.playerLeft.listen((data) {
      _updatePlayersFromData(data);
    });

    // Player ready status changed
    _socketService.playerReady.listen((data) {
      _updatePlayersFromData(data);
    });

    // Game starting countdown
    _socketService.gameStarting.listen((data) {
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

    // Round timer
    _socketService.roundTimer.listen((data) {
      final timeLeft = data['timeLeft'] as int?;
      if (timeLeft != null) {
        _roundTimerController.add(timeLeft);
      }
    });

    // Player guessed
    _socketService.playerGuessed.listen((data) {
      _updatePlayersFromData(data);
    });

    // Round ended
    _socketService.roundEnded.listen((data) {
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

        // Note: Round advancement is now handled entirely by the backend
        // The backend will automatically advance to the next round after a delay
      }
    });

    // New round
    _socketService.newRound.listen((data) {
      _updateRoomFromNewRound(data);
    });

    // Game finished
    _socketService.gameFinished.listen((data) {
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

    // Guess result
    _socketService.guessResult.listen((data) {
      final distance = (data['distance'] as num?)?.toDouble() ?? 0.0;
      final points = (data['points'] as num?)?.toInt() ?? 0;
      final actualLocation = data['actualLocation'] as Map<String, dynamic>?;
      
      if (actualLocation != null && _currentPlayer != null) {
        final result = RoundResult(
          round: _currentRoom?.currentRound ?? 1,
          guessLocation: null, // Will be set from the guess
          actualLocation: LatLng(
            (actualLocation['y'] as num).toDouble(),
            (actualLocation['x'] as num).toDouble(),
          ),
          distance: distance,
          score: points,
          timestamp: DateTime.now(),
        );
        
        _roundResultController.add(result);
        
        // Update player score
        if (_currentPlayer != null) {
          _currentPlayer!.totalScore = (data['totalScore'] as num?)?.toInt() ?? _currentPlayer!.totalScore;
          _playerController.add(_currentPlayer);
        }
      }
    });

    // Errors
    _socketService.error.listen((error) {
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

      // Join the room via Socket.IO and wait for the room-joined event
      _socketService.joinRoom(roomId, playerName);

      // Wait for the room to be set (with timeout)
      await _waitForRoom(timeout: const Duration(seconds: 5));

    } catch (e) {
      _setLoading(false);
      _errorController.add('Failed to create room: $e');
    }
  }

  Future<void> joinRoom(String roomId, String playerName) async {
    _setLoading(true);
    try {
      _currentPlayerName = playerName;

      // Join room via Socket.IO
      _socketService.joinRoom(roomId, playerName);

      // Wait for the room to be set (with timeout)
      await _waitForRoom(timeout: const Duration(seconds: 5));

    } catch (e) {
      _setLoading(false);
      _errorController.add('Failed to join room: $e');
    }
  }

  void setPlayerReady(bool isReady) {
    if (_currentRoom != null && _currentPlayerName != null) {
      _socketService.setPlayerReady(_currentRoom!.id, _currentPlayerName!, isReady);
    }
  }

  void startGame() {
    if (_currentRoom != null) {
      _socketService.startGame(_currentRoom!.id);
    }
  }

  void submitGuess(LatLng? guessLocation) {
    if (_currentRoom != null && _currentPlayerName != null) {
      _socketService.submitGuess(
        _currentRoom!.id,
        _currentPlayerName!,
        guessLocation?.longitude,
        guessLocation?.latitude,
      );
    }
  }

  // Note: Round advancement is now handled automatically by the backend
  // No manual nextRound() method needed

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
        name: roomId, // Use roomId as name for now
        players: _currentRoom?.players ?? [],
        state: state,
        currentRound: currentRound,
        totalRounds: totalRounds,
        locations: locations,
      );

      _roomController.add(_currentRoom);
      _setLoading(false);
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
          id: playerMap['name'], // Use name as ID for now
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
        return GameState.waiting;
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

  // Helper method to wait for room to be set with timeout
  Future<void> _waitForRoom({Duration timeout = const Duration(seconds: 5)}) async {
    final completer = Completer<void>();
    Timer? timeoutTimer;
    StreamSubscription? roomSubscription;

    // Set up timeout
    timeoutTimer = Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.completeError('Timeout waiting for room');
      }
    });

    // Listen for room updates
    roomSubscription = _roomController.stream.listen((room) {
      if (room != null && !completer.isCompleted) {
        timeoutTimer?.cancel();
        roomSubscription?.cancel();
        _setLoading(false);
        completer.complete();
      }
    });

    try {
      await completer.future;
    } finally {
      timeoutTimer?.cancel();
      roomSubscription?.cancel();
    }
  }

  // Helper method to create Location from backend photo data
  Location? _createLocationFromPhotoData(Map<String, dynamic> photoData, int round) {
    try {
      final imageUrl = photoData['imageUrl'] as String?;
      final locationName = photoData['location'] as String?;
      final difficulty = photoData['difficulty'] as String?;
      final coordX = photoData['coordX'] as num?;
      final coordY = photoData['coordY'] as num?;

      if (imageUrl == null) {
        print('❌ No imageUrl in photo data: $photoData');
        return null;
      }

      // Backend stores: coordX=latitude, coordY=longitude (swapped!)
      // We need: lat=latitude, lng=longitude
      final lat = coordX?.toDouble() ?? (19.0760 + (round * 0.001));  // coordX is latitude
      final lng = coordY?.toDouble() ?? (72.8777 + (round * 0.001));  // coordY is longitude

      print('📍 Creating location: $locationName at ($lat, $lng) with image: $imageUrl');

      return Location(
        id: 'round_$round',
        name: locationName ?? 'Campus Location $round',
        coordinates: LatLng(lat, lng),
        imageUrl: imageUrl,
        description: locationName ?? 'Campus location for round $round',
      );
    } catch (e) {
      print('❌ Error creating location from photo data: $e');
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
    _socketService.dispose();
    _roomController.close();
    _playerController.close();
    _playersController.close();
    _roundTimerController.close();
    _roundResultController.close();
    _errorController.close();
    _loadingController.close();
  }
}
