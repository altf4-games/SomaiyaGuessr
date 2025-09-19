import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/game_provider.dart';
import '../utils/theme.dart';
import 'game_screen.dart';

class GameOverScreen extends StatefulWidget {
  const GameOverScreen({super.key});

  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scoreController;
  late Animation<double> _fadeAnimation;
  late Animation<int> _scoreAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scoreController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final finalScore = gameProvider.currentPlayer?.totalScore ?? 0;

    _scoreAnimation = IntTween(begin: 0, end: finalScore).animate(
      CurvedAnimation(parent: _scoreController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      _scoreController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Consumer<GameProvider>(
              builder: (context, gameProvider, child) {
                final player = gameProvider.currentPlayer;
                final room = gameProvider.currentRoom;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildGameOverHeader(),
                    const SizedBox(height: 40),
                    _buildFinalScore(),
                    const SizedBox(height: 40),
                    if (player != null) _buildRoundSummary(player),
                    const SizedBox(height: 40),
                    _buildActionButtons(gameProvider),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameOverHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryAccent.withOpacity(0.2.clamp(0.0, 1.0)),
            border: Border.all(color: AppColors.primaryAccent, width: 3),
          ),
          child: const Icon(
            Icons.emoji_events,
            size: 60,
            color: AppColors.primaryAccent,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'GAME OVER!',
          style: GoogleFonts.poppins(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Great job exploring Somaiya Campus!',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFinalScore() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryAccent.withOpacity(0.3.clamp(0.0, 1.0)),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            'FINAL SCORE',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _scoreAnimation,
            builder: (context, child) {
              return Text(
                '${_scoreAnimation.value}',
                style: GoogleFonts.poppins(
                  fontSize: 64,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryAccent,
                ),
              );
            },
          ),
          Text(
            'POINTS',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundSummary(player) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ROUND BREAKDOWN',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryAccent,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),
            ...player.roundResults.asMap().entries.map((entry) {
              final index = entry.key;
              final result = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Round ${index + 1}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '+${result.score} pts',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.successGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(GameProvider gameProvider) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _playAgain(gameProvider),
            child: Text(
              'PLAY AGAIN',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => _backToHome(gameProvider),
            child: Text(
              'BACK TO HOME',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _playAgain(GameProvider gameProvider) async {
    final currentRoom = gameProvider.currentRoom;
    final currentPlayer = gameProvider.currentPlayer;

    if (currentRoom != null && currentPlayer != null) {
      gameProvider.resetGame();
      await gameProvider.createRoom(
        '${currentRoom.name} - New Game',
        currentPlayer.name,
      );

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const GameScreen()),
          (route) => false,
        );
      }
    }
  }

  void _backToHome(GameProvider gameProvider) {
    gameProvider.resetGame();
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }
}
