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
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Consumer<GameProvider>(
              builder: (context, gameProvider, child) {
                final player = gameProvider.currentPlayer;

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
          decoration: AppTheme.brutalistContainer(
            backgroundColor: AppColors.brutalistYellow,
            addShadow: true,
          ),
          child: const Icon(
            Icons.emoji_events,
            size: 60,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'GAME OVER!',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 40,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: AppTheme.brutalistContainer(
            backgroundColor: AppColors.brutalistPink,
            addShadow: false,
          ),
          child: Text(
            'GREAT JOB!',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildFinalScore() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: AppTheme.brutalistContainer(
        backgroundColor: AppColors.backgroundTertiary,
        addShadow: true,
      ),
      child: Column(
        children: [
          Text(
            'FINAL SCORE',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _scoreAnimation,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.brutalistCyan,
                  border: Border.all(
                    color: AppColors.brutalistBorder,
                    width: 4,
                  ),
                ),
                child: Text(
                  '${_scoreAnimation.value}',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            'POINTS',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: 2,
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
        GestureDetector(
          onTap: () => _playAgain(gameProvider),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: AppTheme.brutalistButton(
              backgroundColor: AppColors.brutalistGreen,
            ),
            child: Center(
              child: Text(
                'PLAY AGAIN',
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: AppColors.textPrimary,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => _backToHome(gameProvider),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: AppColors.backgroundTertiary,
              border: Border.all(
                color: AppColors.brutalistBorder,
                width: AppColors.brutalistBorderWidth,
              ),
            ),
            child: Center(
              child: Text(
                'BACK TO HOME',
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: AppColors.textPrimary,
                  letterSpacing: 1,
                ),
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
