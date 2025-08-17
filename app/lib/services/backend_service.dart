import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;

class BackendService {
  Future<Map<String, dynamic>?> getRoom(String roomId) async {
    final res = await http.get(Uri.parse('$baseUrl/room/$roomId'));
    if (res.statusCode == 200) return jsonDecode(res.body);
    return null;
  }

  static final BackendService _instance = BackendService._internal();
  factory BackendService() => _instance;
  BackendService._internal();

  final String baseUrl = 'https://somaiyaguessr.skillversus.xyz/api/game';
  final String socketUrl = 'https://somaiyaguessr.skillversus.xyz';

  IO.Socket? _socket;

  // HTTP API methods
  Future<Map<String, dynamic>?> createRoom(String playerName) async {
    final res = await http.post(
      Uri.parse('$baseUrl/create-room'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'playerName': playerName}),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    return null;
  }

  Future<Map<String, dynamic>?> joinRoom(
    String roomId,
    String playerName,
  ) async {
    final res = await http.post(
      Uri.parse('$baseUrl/join-room'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'roomId': roomId, 'playerName': playerName}),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    return null;
  }

  Future<Map<String, dynamic>?> submitGuess(
    String roomId,
    String playerName,
    double guessX,
    double guessY,
  ) async {
    final res = await http.post(
      Uri.parse('$baseUrl/submit-guess'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'roomId': roomId,
        'playerName': playerName,
        'guessX': guessX,
        'guessY': guessY,
      }),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    return null;
  }

  Future<Map<String, dynamic>?> nextRound(String roomId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/next-round'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'roomId': roomId}),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    return null;
  }

  // WebSocket methods
  void connectSocket({
    required String playerName,
    required String roomId,
    required Function(dynamic) onEvent,
  }) {
    _socket = IO.io(socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    _socket!.connect();
    _socket!.onConnect((_) {
      _socket!.emit('join-room', {'roomId': roomId, 'playerName': playerName});
    });
    _socket!.onAny((event, [data]) {
      onEvent({'event': event, 'data': data});
    });
  }

  void submitGuessSocket(
    String roomId,
    String playerName,
    double guessX,
    double guessY,
  ) {
    _socket?.emit('submit-guess', {
      'roomId': roomId,
      'playerName': playerName,
      'guessX': guessX,
      'guessY': guessY,
    });
  }

  void nextRoundSocket(String roomId) {
    _socket?.emit('next-round', {'roomId': roomId});
  }

  void playerReady(String roomId, String playerName, bool ready) {
    _socket?.emit('player-ready', {
      'roomId': roomId,
      'playerName': playerName,
      'ready': ready,
    });
  }

  void startGameSocket(String roomId) {
    _socket?.emit('start-game', {'roomId': roomId});
  }

  void disconnectSocket() {
    _socket?.disconnect();
    _socket = null;
  }
}
