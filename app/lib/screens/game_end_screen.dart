import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../utils/theme.dart';
import '../providers/realtime_game_provider.dart';
import '../models/game_models.dart';

class GameEndScreen extends StatefulWidget {
  final List<Map<String, dynamic>> finalScores;
  final String roomName;

  const GameEndScreen({
    super.key,
    required this.finalScores,
    required this.roomName,
  });

  @override
  State<GameEndScreen> createState() => _GameEndScreenState();
}

class _GameEndScreenState extends State<GameEndScreen>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late AnimationController _scoreController;
  late Animation<double> _confettiAnimation;
  late Animation<double> _scoreAnimation;

  @override
  void initState() {
    super.initState();

    _confettiController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _scoreController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _confettiAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _confettiController, curve: Curves.easeOut),
    );

    _scoreAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scoreController, curve: Curves.elasticOut),
    );

    // Start animations
    _confettiController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      _scoreController.forward();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Header
              _buildHeader(),

              const SizedBox(height: 30),

              // Scores List
              Expanded(child: _buildScoresList()),

              const SizedBox(height: 30),

              // Action Buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _confettiAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _confettiAnimation.value,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryAccent.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.emoji_events,
                  size: 60,
                  color: Colors.white,
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 20),

        Text(
          'Game Complete!',
          style: GoogleFonts.poppins(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'Room: ${widget.roomName}',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildScoresList() {
    return AnimatedBuilder(
      animation: _scoreAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _scoreAnimation.value)),
          child: Opacity(
            opacity: _scoreAnimation.value.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderLight, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent.withValues(alpha: 0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Final Scores',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.leaderboard,
                          color: AppColors.primaryAccent,
                          size: 24,
                        ),
                      ],
                    ),
                  ),

                  // Scores
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: widget.finalScores.length,
                      itemBuilder: (context, index) {
                        final score = widget.finalScores[index];
                        final isWinner = index == 0;

                        return _buildScoreItem(
                          rank: index + 1,
                          playerName: score['name'] as String,
                          score: score['score'] as int,
                          isWinner: isWinner,
                          delay: index * 200,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScoreItem({
    required int rank,
    required String playerName,
    required int score,
    required bool isWinner,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isWinner
                  ? AppColors.primaryAccent.withValues(alpha: 0.1)
                  : AppColors.backgroundPrimary,
              borderRadius: BorderRadius.circular(12),
              border: isWinner
                  ? Border.all(color: AppColors.primaryAccent, width: 2)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Rank
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isWinner
                        ? AppColors.primaryAccent
                        : AppColors.textSecondary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isWinner
                        ? const Icon(
                            Icons.emoji_events,
                            color: Colors.white,
                            size: 20,
                          )
                        : Text(
                            '$rank',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                  ),
                ),

                const SizedBox(width: 16),

                // Player Name
                Expanded(
                  child: Text(
                    playerName,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: isWinner ? FontWeight.w600 : FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),

                // Score
                Text(
                  '$score pts',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isWinner
                        ? AppColors.primaryAccent
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Play Again Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _playAgain,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
            child: Text(
              'Play Again',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Return to Home Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: _returnToHome,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.primaryAccent, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Return to Home',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryAccent,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _playAgain() {
    // Navigate back to home screen to create/join a new room
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  void _returnToHome() {
    // Navigate back to home screen
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }
}
