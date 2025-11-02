import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/realtime_game_provider.dart';
import '../models/game_models.dart';
import '../utils/theme.dart';
import 'game_screen.dart';

class LobbyScreen extends StatefulWidget {
  final String roomId;
  final String playerName;

  const LobbyScreen({
    super.key,
    required this.roomId,
    required this.playerName,
  });

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  bool _isReady = false;
  int? _countdown;

  @override
  void initState() {
    super.initState();
    _setupListeners();

    // For realtime provider, no need to manually refresh
    // The provider will automatically update via socket events
  }

  void _setupListeners() {
    // Listen to realtime provider streams for game state changes
    final provider = Provider.of<RealtimeGameProvider>(context, listen: false);

    // Listen for game state changes
    provider.roomStream.listen((room) {
      if (!mounted) return;

      if (room != null && room.state == GameState.playing) {
        // Navigate to game screen when game starts
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const GameScreen()),
        );
      }
    });
  }

  void _copyRoomCode(String roomCode) async {
    await Clipboard.setData(ClipboardData(text: roomCode));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Room code copied: $roomCode',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.successGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Clean up when leaving lobby
        final provider = Provider.of<RealtimeGameProvider>(
          context,
          listen: false,
        );
        provider.resetGame();
        return true;
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundSecondary,
          elevation: 0,
          title: Text(
            'Room: ${widget.roomId}',
            style: GoogleFonts.poppins(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () {
              final provider = Provider.of<RealtimeGameProvider>(
                context,
                listen: false,
              );
              provider.resetGame();
              Navigator.of(context).pop();
            },
          ),
        ),
        body: Consumer<RealtimeGameProvider>(
          builder: (context, provider, child) {
            final room = provider.currentRoom;
            // Get all players from the room
            final players = room?.players ?? [];
            final isLoading = provider.isLoading;

            print('🎮 Lobby: Showing ${players.length} players');
            for (var player in players) {
              print('  - ${player.name} (Ready: ${player.isReady})');
            }

            if (isLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryAccent,
                  ),
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Room info card
                  _buildRoomInfoCard(room),
                  const SizedBox(height: 20),

                  // Countdown display
                  if (_countdown != null && _countdown! > 0)
                    _buildCountdownCard(),

                  // Players list
                  Expanded(child: _buildPlayersList(players)),

                  const SizedBox(height: 20),

                  // Ready button
                  _buildReadyButton(provider),

                  const SizedBox(height: 10),

                  // Start game button (for room creator)
                  if (players.isNotEmpty &&
                      players.first.name == widget.playerName)
                    _buildStartGameButton(provider, players),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRoomInfoCard(GameRoom? room) {
    // Generate a shorter room code for display (first 6 characters)
    final displayRoomCode = widget.roomId.length > 6
        ? widget.roomId.substring(0, 6).toUpperCase()
        : widget.roomId.toUpperCase();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.textSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Waiting for Players',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // Room code with copy button
          Row(
            children: [
              Text(
                'Room Code:',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent.withOpacity(
                      0.1.clamp(0.0, 1.0),
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primaryAccent),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        displayRoomCode,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryAccent,
                          letterSpacing: 2,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _copyRoomCode(displayRoomCode),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryAccent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.copy,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          if (room != null) ...[
            const SizedBox(height: 12),
            Text(
              'Rounds: ${room.totalRounds}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCountdownCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.primaryAccent.withOpacity(0.1.clamp(0.0, 1.0)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryAccent),
      ),
      child: Column(
        children: [
          Text(
            'Game Starting In',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$_countdown',
            style: GoogleFonts.poppins(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersList(List<Player> players) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.textSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Players (${players.length})',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const Divider(color: AppColors.textSecondary, height: 1),
          Expanded(
            child: players.isEmpty
                ? Center(
                    child: Text(
                      'No players yet',
                      style: GoogleFonts.poppins(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: players.length,
                    itemBuilder: (context, index) {
                      final player = players[index];
                      final isCurrentPlayer = player.name == widget.playerName;

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isCurrentPlayer
                              ? AppColors.primaryAccent.withOpacity(
                                  0.1.clamp(0.0, 1.0),
                                )
                              : Colors.transparent,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: isCurrentPlayer
                                  ? AppColors.primaryAccent
                                  : AppColors.textSecondary,
                              child: Text(
                                player.name[0].toUpperCase(),
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    player.name,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  if (isCurrentPlayer)
                                    Text(
                                      'You',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: AppColors.primaryAccent,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // Ready status
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: player.isReady
                                    ? Colors.green.withOpacity(
                                        0.2.clamp(0.0, 1.0),
                                      )
                                    : Colors.orange.withOpacity(
                                        0.2.clamp(0.0, 1.0),
                                      ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                player.isReady ? 'Ready' : 'Not Ready',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: player.isReady
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadyButton(RealtimeGameProvider provider) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _isReady = !_isReady;
        });
        // Update player ready status in the realtime game service
        provider.setPlayerReady(_isReady);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: _isReady ? Colors.green : AppColors.primaryAccent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        _isReady ? 'Ready!' : 'Mark as Ready',
        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildStartGameButton(
    RealtimeGameProvider provider,
    List<Player> players,
  ) {
    final allReady = players.every((player) => player.isReady);
    final canStart = players.isNotEmpty && allReady;

    return ElevatedButton(
      onPressed: canStart
          ? () {
              // Start the game via realtime provider
              provider.startGame();
            }
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: canStart
            ? AppColors.successGreen
            : AppColors.textSecondary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        canStart ? 'Start Game' : 'Waiting for all players to be ready',
        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }
}
