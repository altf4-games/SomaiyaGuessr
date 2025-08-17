import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/realtime_game_provider.dart';
import '../utils/theme.dart';

class RealtimeTestScreen extends StatefulWidget {
  const RealtimeTestScreen({super.key});

  @override
  State<RealtimeTestScreen> createState() => _RealtimeTestScreenState();
}

class _RealtimeTestScreenState extends State<RealtimeTestScreen> {
  final TextEditingController _roomIdController = TextEditingController();
  final TextEditingController _playerNameController = TextEditingController();

  @override
  void dispose() {
    _roomIdController.dispose();
    _playerNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Realtime Test',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.backgroundSecondary,
      ),
      body: Consumer<RealtimeGameProvider>(
        builder: (context, provider, child) {
          final room = provider.currentRoom;
          final location = provider.getCurrentLocation();

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Connection controls
                if (room == null) ...[
                  TextField(
                    controller: _roomIdController,
                    decoration: const InputDecoration(
                      labelText: 'Room ID',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _playerNameController,
                    decoration: const InputDecoration(
                      labelText: 'Player Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: provider.isLoading
                              ? null
                              : () {
                                  provider.createRoom(
                                    _playerNameController.text.trim(),
                                  );
                                },
                          child: const Text('Create Room'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: provider.isLoading
                              ? null
                              : () {
                                  provider.joinRoom(
                                    _roomIdController.text.trim(),
                                    _playerNameController.text.trim(),
                                  );
                                },
                          child: const Text('Join Room'),
                        ),
                      ),
                    ],
                  ),
                ],

                // Room info
                if (room != null) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Room: ${room.id}',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text('State: ${room.state}'),
                          Text(
                            'Round: ${room.currentRound}/${room.totalRounds}',
                          ),
                          Text('Players: ${room.players.length}'),
                          Text('Timer: ${provider.timeLeft}s'),
                          const SizedBox(height: 8),
                          Text(
                            'Player List:',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          ...room.players.map(
                            (player) => Text(
                              '  - ${player.name} (Score: ${player.totalScore})',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(
                                0.1.clamp(0.0, 1.0),
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '✅ Socket Connected',
                              style: TextStyle(color: Colors.green),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Current location/image
                if (location != null) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Location',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Name: ${location.name}'),
                          Text(
                            'Coordinates: ${location.coordinates.latitude}, ${location.coordinates.longitude}',
                          ),
                          const SizedBox(height: 16),
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                location.imageUrl,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    },
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.error,
                                          color: Colors.red,
                                        ),
                                        const SizedBox(height: 8),
                                        Text('Failed to load image'),
                                        Text('URL: ${location.imageUrl}'),
                                        Text('Error: $error'),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Controls
                if (room != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (room.state.toString().contains('waiting'))
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => provider.setPlayerReady(true),
                            child: const Text('Ready'),
                          ),
                        ),
                      if (room.state.toString().contains('waiting') &&
                          room.players.every((p) => p.isReady))
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => provider.startGame(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            child: const Text('Start Game'),
                          ),
                        ),
                      if (room.state.toString().contains('playing'))
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => provider.submitGuess(),
                            child: const Text('Submit Guess'),
                          ),
                        ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => provider.resetGame(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('Reset'),
                        ),
                      ),
                    ],
                  ),
                ],

                // Error display
                if (provider.error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1.clamp(0.0, 1.0)),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Text(
                      'Error: ${provider.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],

                // Loading indicator
                if (provider.isLoading) ...[
                  const SizedBox(height: 16),
                  const Center(child: CircularProgressIndicator()),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
