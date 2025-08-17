import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/game_models.dart';

class SocketService {
  static const String _baseUrl = 'https://somaiyaguessr.skillversus.xyz';

  IO.Socket? _socket;
  bool _isConnected = false;

  // Stream controllers for real-time events
  final StreamController<Map<String, dynamic>> _roomJoinedController =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _playerJoinedController =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _playerLeftController =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _playerReadyController =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _gameStartingController =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _roundTimerController =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _playerGuessedController =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _roundEndedController =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _newRoundController =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _gameFinishedController =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _guessResultController =
      StreamController.broadcast();
  final StreamController<String> _errorController =
      StreamController.broadcast();

  // Getters for streams
  Stream<Map<String, dynamic>> get roomJoined => _roomJoinedController.stream;
  Stream<Map<String, dynamic>> get playerJoined =>
      _playerJoinedController.stream;
  Stream<Map<String, dynamic>> get playerLeft => _playerLeftController.stream;
  Stream<Map<String, dynamic>> get playerReady => _playerReadyController.stream;
  Stream<Map<String, dynamic>> get gameStarting =>
      _gameStartingController.stream;
  Stream<Map<String, dynamic>> get roundTimer => _roundTimerController.stream;
  Stream<Map<String, dynamic>> get playerGuessed =>
      _playerGuessedController.stream;
  Stream<Map<String, dynamic>> get roundEnded => _roundEndedController.stream;
  Stream<Map<String, dynamic>> get newRound => _newRoundController.stream;
  Stream<Map<String, dynamic>> get gameFinished =>
      _gameFinishedController.stream;
  Stream<Map<String, dynamic>> get guessResult => _guessResultController.stream;
  Stream<String> get error => _errorController.stream;

  bool get isConnected => _isConnected;

  // Singleton pattern
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  Future<void> connect() async {
    if (_socket != null && _isConnected) {
      return;
    }

    try {
      _socket = IO.io(
        _baseUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .build(),
      );

      _socket!.connect();

      _socket!.onConnect((_) {
        _isConnected = true;
        if (kDebugMode) {
          print('🔗 Connected to server');
        }
      });

      _socket!.onDisconnect((_) {
        _isConnected = false;
        if (kDebugMode) {
          print('🔌 Disconnected from server');
        }
      });

      _socket!.onConnectError((error) {
        _isConnected = false;
        if (kDebugMode) {
          print('❌ Connection error: $error');
        }
        _errorController.add('Connection error: $error');
      });

      // Set up event listeners
      _setupEventListeners();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to connect: $e');
      }
      _errorController.add('Failed to connect: $e');
    }
  }

  void _setupEventListeners() {
    _socket!.on('room-joined', (data) {
      if (kDebugMode) {
        print('🏠 Room joined: $data');
      }
      _roomJoinedController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('player-joined', (data) {
      if (kDebugMode) {
        print('👤 Player joined: $data');
      }
      _playerJoinedController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('player-left', (data) {
      if (kDebugMode) {
        print('👋 Player left: $data');
      }
      _playerLeftController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('player-ready-changed', (data) {
      if (kDebugMode) {
        print('✅ Player ready changed: $data');
      }
      _playerReadyController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('game-starting', (data) {
      if (kDebugMode) {
        print('🚀 Game starting: $data');
      }
      _gameStartingController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('game-started', (data) {
      if (kDebugMode) {
        print('🎮 Game started: $data');
      }
      _roomJoinedController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('round-timer', (data) {
      if (kDebugMode) {
        print('⏰ Round timer: $data');
      }
      _roundTimerController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('player-guessed', (data) {
      if (kDebugMode) {
        print('🎯 Player guessed: $data');
      }
      _playerGuessedController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('round-ended', (data) {
      if (kDebugMode) {
        print('🏁 Round ended: $data');
      }
      _roundEndedController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('new-round', (data) {
      if (kDebugMode) {
        print('🔄 New round: $data');
      }
      _newRoundController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('game-finished', (data) {
      if (kDebugMode) {
        print('🏆 Game finished: $data');
      }
      _gameFinishedController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('guess-result', (data) {
      if (kDebugMode) {
        print('📊 Guess result: $data');
      }
      _guessResultController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('error', (data) {
      if (kDebugMode) {
        print('❌ Server error: $data');
      }
      final message = data is Map
          ? data['message'] ?? 'Unknown error'
          : data.toString();
      _errorController.add(message);
    });
  }

  // Socket event emitters
  void joinRoom(String roomId, String playerName) {
    if (!_isConnected || _socket == null) {
      _errorController.add('Not connected to server');
      return;
    }

    _socket!.emit('join-room', {'roomId': roomId, 'playerName': playerName});
  }

  void setPlayerReady(String roomId, String playerName, bool isReady) {
    if (!_isConnected || _socket == null) {
      _errorController.add('Not connected to server');
      return;
    }

    _socket!.emit('player-ready', {
      'roomId': roomId,
      'playerName': playerName,
      'isReady': isReady,
    });
  }

  void startGame(String roomId) {
    if (!_isConnected || _socket == null) {
      _errorController.add('Not connected to server');
      return;
    }

    _socket!.emit('start-game', {'roomId': roomId});
  }

  void submitGuess(
    String roomId,
    String playerName,
    double? guessX,
    double? guessY,
  ) {
    if (!_isConnected || _socket == null) {
      _errorController.add('Not connected to server');
      return;
    }

    _socket!.emit('submit-guess', {
      'roomId': roomId,
      'playerName': playerName,
      'guessX': guessX,
      'guessY': guessY,
    });
  }

  void nextRound(String roomId) {
    if (!_isConnected || _socket == null) {
      _errorController.add('Not connected to server');
      return;
    }

    _socket!.emit('next-round', {'roomId': roomId});
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }

  void dispose() {
    disconnect();
    _roomJoinedController.close();
    _playerJoinedController.close();
    _playerLeftController.close();
    _playerReadyController.close();
    _gameStartingController.close();
    _roundTimerController.close();
    _playerGuessedController.close();
    _roundEndedController.close();
    _newRoundController.close();
    _gameFinishedController.close();
    _guessResultController.close();
    _errorController.close();
  }
}
