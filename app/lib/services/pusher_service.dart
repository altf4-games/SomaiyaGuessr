import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dart_pusher_channels/dart_pusher_channels.dart';

class PusherService {
  static const String _apiKey = '7bbb6f68bfe0188e9322';
  static const String _cluster = 'ap2';

  PusherChannelsClient? _client;
  Channel? _currentChannel;
  String? _currentRoomId;
  bool _isConnected = false;

  // Stream controllers for real-time events
  final StreamController<Map<String, dynamic>> _playerJoinedController =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _playerLeftController =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _playerReadyController =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _gameStartingController =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _gameStartedController =
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
  final StreamController<String> _errorController =
      StreamController.broadcast();

  // Getters for streams
  Stream<Map<String, dynamic>> get playerJoined =>
      _playerJoinedController.stream;
  Stream<Map<String, dynamic>> get playerLeft => _playerLeftController.stream;
  Stream<Map<String, dynamic>> get playerReady => _playerReadyController.stream;
  Stream<Map<String, dynamic>> get gameStarting =>
      _gameStartingController.stream;
  Stream<Map<String, dynamic>> get gameStarted => _gameStartedController.stream;
  Stream<Map<String, dynamic>> get roundTimer => _roundTimerController.stream;
  Stream<Map<String, dynamic>> get playerGuessed =>
      _playerGuessedController.stream;
  Stream<Map<String, dynamic>> get roundEnded => _roundEndedController.stream;
  Stream<Map<String, dynamic>> get newRound => _newRoundController.stream;
  Stream<Map<String, dynamic>> get gameFinished =>
      _gameFinishedController.stream;
  Stream<String> get error => _errorController.stream;

  bool get isConnected => _isConnected;

  // Singleton pattern
  static final PusherService _instance = PusherService._internal();
  factory PusherService() => _instance;
  PusherService._internal();

  Future<void> connect() async {
    if (_client != null && _isConnected) {
      return;
    }

    try {
      final options = PusherChannelsOptions.fromHost(
        scheme: 'wss',
        host: 'ws-$_cluster.pusher.com',
        key: _apiKey,
        port: 443,
      );

      _client = PusherChannelsClient.websocket(
        options: options,
        connectionErrorHandler: (exception, trace, refresh) {
          if (kDebugMode) {
            print('❌ Pusher connection error: $exception');
          }
          _errorController.add('Connection error: $exception');
          refresh();
        },
      );

      _client!.onConnectionEstablished.listen((_) {
        _isConnected = true;
        if (kDebugMode) {
          print('🔗 Connected to Pusher');
        }
      });

      await _client!.connect();
      _isConnected = true;
      
      if (kDebugMode) {
        print('🔗 Pusher connection initiated');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to connect to Pusher: $e');
      }
      _errorController.add('Failed to connect: $e');
    }
  }

  Future<void> subscribeToRoom(String roomId) async {
    if (_client == null) {
      await connect();
    }

    // Unsubscribe from previous room if any
    if (_currentRoomId != null && _currentRoomId != roomId) {
      await unsubscribeFromRoom();
    }

    _currentRoomId = roomId;
    final channelName = 'room-$roomId';

    try {
      _currentChannel = _client!.publicChannel(channelName);
      
      // Subscribe to the channel
      _currentChannel!.subscribe();

      // Bind to all events
      _bindEvents();

      if (kDebugMode) {
        print('📺 Subscribed to channel: $channelName');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to subscribe to channel: $e');
      }
      _errorController.add('Failed to subscribe to room: $e');
    }
  }

  void _bindEvents() {
    if (_currentChannel == null) return;

    _currentChannel!.bind('player-joined').listen((event) {
      _handleEvent('player-joined', event.data);
    });

    _currentChannel!.bind('player-left').listen((event) {
      _handleEvent('player-left', event.data);
    });

    _currentChannel!.bind('player-ready-changed').listen((event) {
      _handleEvent('player-ready-changed', event.data);
    });

    _currentChannel!.bind('game-starting').listen((event) {
      _handleEvent('game-starting', event.data);
    });

    _currentChannel!.bind('game-started').listen((event) {
      _handleEvent('game-started', event.data);
    });

    _currentChannel!.bind('round-timer').listen((event) {
      _handleEvent('round-timer', event.data);
    });

    _currentChannel!.bind('player-guessed').listen((event) {
      _handleEvent('player-guessed', event.data);
    });

    _currentChannel!.bind('round-ended').listen((event) {
      _handleEvent('round-ended', event.data);
    });

    _currentChannel!.bind('new-round').listen((event) {
      _handleEvent('new-round', event.data);
    });

    _currentChannel!.bind('game-finished').listen((event) {
      _handleEvent('game-finished', event.data);
    });
  }

  void _handleEvent(String eventName, String? eventData) {
    if (kDebugMode) {
      print('📨 Received event: $eventName');
      print('   Data: $eventData');
    }

    try {
      final data = eventData != null && eventData.isNotEmpty
          ? Map<String, dynamic>.from(json.decode(eventData))
          : <String, dynamic>{};

      switch (eventName) {
        case 'player-joined':
          _playerJoinedController.add(data);
          break;
        case 'player-left':
          _playerLeftController.add(data);
          break;
        case 'player-ready-changed':
          _playerReadyController.add(data);
          break;
        case 'game-starting':
          _gameStartingController.add(data);
          break;
        case 'game-started':
          _gameStartedController.add(data);
          break;
        case 'round-timer':
          _roundTimerController.add(data);
          break;
        case 'player-guessed':
          _playerGuessedController.add(data);
          break;
        case 'round-ended':
          _roundEndedController.add(data);
          break;
        case 'new-round':
          _newRoundController.add(data);
          break;
        case 'game-finished':
          _gameFinishedController.add(data);
          break;
        default:
          if (kDebugMode) {
            print('⚠️ Unknown event: $eventName');
          }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error parsing event data: $e');
      }
    }
  }

  Future<void> unsubscribeFromRoom() async {
    if (_currentChannel != null) {
      try {
        _currentChannel!.unsubscribe();
        if (kDebugMode) {
          print('📺 Unsubscribed from channel: room-$_currentRoomId');
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error unsubscribing: $e');
        }
      }
      _currentChannel = null;
      _currentRoomId = null;
    }
  }

  Future<void> disconnect() async {
    await unsubscribeFromRoom();
    if (_client != null) {
      await _client!.disconnect();
      _isConnected = false;
      _client = null;
    }
  }

  void dispose() {
    disconnect();
    _playerJoinedController.close();
    _playerLeftController.close();
    _playerReadyController.close();
    _gameStartingController.close();
    _gameStartedController.close();
    _roundTimerController.close();
    _playerGuessedController.close();
    _roundEndedController.close();
    _newRoundController.close();
    _gameFinishedController.close();
    _errorController.close();
  }
}
