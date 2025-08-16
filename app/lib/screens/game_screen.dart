import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../providers/game_provider.dart';
import '../utils/theme.dart';
import '../widgets/campus_map.dart';
import 'round_result_screen.dart';
import 'game_over_screen.dart';
import 'home_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with TickerProviderStateMixin {
  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _buttonScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _buttonAnimationController,
      curve: Curves.easeInOut,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startGameIfNeeded();
    });
  }

  @override
  void dispose() {
    _buttonAnimationController.dispose();
    super.dispose();
  }

  void _startGameIfNeeded() async {
    if (!mounted) return;
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    if (gameProvider.currentRoom?.state.index == 0) { // rkg
      await gameProvider.startGame();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;
    
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        final room = gameProvider.currentRoom;
        final player = gameProvider.currentPlayer;
        final location = gameProvider.currentLocation;

        if (room == null || player == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
              ),
            ),
          );
        }

        // Navigate based on game state
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return; // Added mounted check
          if (room.state.index == 3) { // gameOver
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const GameOverScreen()),
            );
          }
        });

        return Scaffold(
          appBar: _buildAppBar(room, player),
          body: SafeArea( // Added SafeArea for better phone compatibility
            child: LayoutBuilder(
              builder: (context, constraints) {
                final availableHeight = constraints.maxHeight;
                final imageHeight = isSmallScreen ? 120.0 : 160.0;
                final buttonHeight = 56.0; // Fixed button height to prevent overflow
                final padding = 16.0;
                final mapHeight = availableHeight - imageHeight - buttonHeight - (padding * 2); // Account for top and bottom padding
                
                return Column(
                  children: [
                    if (location != null) 
                      _buildLocationImage(location.imageUrl, imageHeight),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(padding),
                        child: CampusMap(
                          onTap: (LatLng position) {
                            gameProvider.setGuess(position);
                          },
                          guessLocation: gameProvider.currentGuess,
                        ),
                      ),
                    ),
                    Container(
                      height: buttonHeight,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildSubmitButton(gameProvider),
                    ),
                    const SizedBox(height: 8), // Added bottom spacing for better mobile experience
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(room, player) {
    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.backgroundPrimary,
      title: Text(
        'Round ${room.currentRound}/${room.totalRounds}',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 18, // Slightly smaller for better mobile fit
          color: AppColors.textPrimary,
        ),
      ),
      actions: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // Reduced padding
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: AppColors.primaryAccent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '${player.totalScore} pts',
            style: GoogleFonts.poppins(
              color: AppColors.backgroundPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14, // Smaller font for mobile
            ),
          ),
        ),
      ],
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: () {
          _showExitDialog();
        },
      ),
    );
  }

  Widget _buildLocationImage(String imageUrl, double height) {
    return Container(
      height: height,
      width: double.infinity,
      margin: const EdgeInsets.all(8), // Added margin for better spacing
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12), // Consistent border radius
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: AppColors.backgroundSecondary,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_not_supported,
                      color: AppColors.textSecondary,
                      size: 48,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Image not available',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSubmitButton(GameProvider gameProvider) {
    return AnimatedBuilder(
      animation: _buttonScaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _buttonScaleAnimation.value,
          child: Container(
            width: double.infinity, // Full width button for better mobile UX
            height: 48, // Fixed height to prevent overflow
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: gameProvider.hasGuess && !gameProvider.isLoading
                  ? () => _submitGuess(gameProvider)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: gameProvider.hasGuess
                    ? AppColors.primaryAccent
                    : AppColors.textSecondary.withOpacity(0.5),
                padding: EdgeInsets.zero, // Remove padding to prevent overflow
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: gameProvider.isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.backgroundPrimary,
                        ),
                      ),
                    )
                  : Text(
                      gameProvider.hasGuess ? 'SUBMIT GUESS' : 'TAP ON MAP TO GUESS',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14, // Slightly larger font for better readability
                        color: AppColors.backgroundPrimary,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  void _submitGuess(GameProvider gameProvider) async {
    if (!mounted) return; // Added mounted check
    
    _buttonAnimationController.forward().then((_) {
      if (mounted) _buttonAnimationController.reverse();
    });

    final result = await gameProvider.submitGuess();
    if (result != null && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RoundResultScreen(result: result),
        ),
      );
    }
  }

  void _showExitDialog() {
    if (!mounted) return; // Added mounted check
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Exit Game?',
            style: GoogleFonts.poppins(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          content: Text(
            'Are you sure you want to exit the current game? Your progress will be lost.',
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'CANCEL',
                style: GoogleFonts.poppins(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),//rkg
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final gameProvider = Provider.of<GameProvider>(context, listen: false);
                gameProvider.resetGame();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.errorRed,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'EXIT',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
