import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../providers/realtime_game_provider.dart';
import '../models/game_models.dart';
import '../services/timer_service.dart';
import '../utils/theme.dart';
import '../widgets/campus_map.dart';
import 'game_end_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonScaleAnimation;
  final TimerService _timerService = TimerService();
  int _timeLeft = 30;
  bool _hasSubmitted = false;

  @override
  void initState() {
    super.initState();
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _buttonAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Setup timer polling to get shared timer value
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final gameProvider = Provider.of<RealtimeGameProvider>(
        context,
        listen: false,
      );

      // For realtime provider, we'll use the timeLeft from the provider directly
      final newTimeLeft = gameProvider.timeLeft;
      if (newTimeLeft != _timeLeft) {
        setState(() {
          _timeLeft = newTimeLeft;
        });
        print('🎮 Timer update: ${_timeLeft}s remaining');

        // Note: Auto-submit is now handled entirely by the backend
        // Frontend just displays the timer countdown
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startGameIfNeeded();
      _setupRoundListeners();
    });
  }

  void _setupRoundListeners() {
    final gameProvider = Provider.of<RealtimeGameProvider>(
      context,
      listen: false,
    );

    // Listen for round completion events
    gameProvider.roomStream.listen((room) {
      if (!mounted) return;

      if (room != null && room.state == GameState.roundResult) {
        // Round ended, dismiss waiting dialog if it's showing
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(); // Close waiting dialog
        }

        // Show round result briefly, then auto-advance
        _showRoundResultBriefly();
      } else if (room != null && room.state == GameState.playing) {
        // New round started, reset submission state
        _hasSubmitted = false;
      } else if (room != null && room.state == GameState.gameOver) {
        // Game finished, navigate to end screen
        _navigateToEndScreen(gameProvider);
      }
    });
  }

  @override
  void dispose() {
    _buttonAnimationController.dispose();
    _timerService.stopTimer();
    super.dispose();
  }

  void _autoSubmitGuess() async {
    final gameProvider = Provider.of<RealtimeGameProvider>(
      context,
      listen: false,
    );
    if (!_hasSubmitted) {
      _hasSubmitted = true;

      // If no guess was made, set coordinates to 0,0 for 0 points
      if (gameProvider.currentGuess == null) {
        gameProvider.setGuess(const LatLng(0, 0));
        print(
          '⏰ Timer expired - auto-submitting with 0,0 coordinates for 0 points',
        );
      }

      // Submit the guess but don't auto-advance - wait for all players
      gameProvider.submitGuess();

      if (mounted) {
        _showWaitingForPlayersDialog();
      }
    }
  }

  void _showRoundResultBriefly() {
    // Show a brief "Round Complete" message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Round Complete! Moving to next round...',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryAccent,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showRoundResult(RoundResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'Round ${result.round} Complete!',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Score: ${result.score} points',
              style: GoogleFonts.poppins(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Distance: ${result.distance.toStringAsFixed(0)}m',
              style: GoogleFonts.poppins(),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Continue',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // Note: Round advancement is now handled automatically by the backend
  // No manual _startNextRound() method needed

  void _navigateToEndScreen(RealtimeGameProvider gameProvider) {
    final finalScores = gameProvider.finalScores;
    final roomName = gameProvider.currentRoom?.name ?? 'Unknown Room';

    if (finalScores != null && finalScores.isNotEmpty) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) =>
              GameEndScreen(finalScores: finalScores, roomName: roomName),
        ),
      );
    } else {
      // Fallback if no scores available
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  // Removed redundant _showGameOverDialog - now using GameEndScreen instead

  void _showWaitingForPlayersDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundSecondary,
        title: Text(
          'Waiting for Other Players',
          style: GoogleFonts.poppins(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.primaryAccent,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Please wait while other players complete their guesses...',
              style: GoogleFonts.poppins(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    // Note: Dialog will be automatically dismissed by _setupRoundListeners
    // when round-ended event is received from the backend
  }

  void _showAutoSubmitDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundSecondary,
        title: Text(
          'Time\'s Up!',
          style: GoogleFonts.poppins(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Your guess has been automatically submitted.',
          style: GoogleFonts.poppins(color: AppColors.textSecondary),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _startRoundTimer() {
    _hasSubmitted = false;
    // For realtime provider, the timer is handled by the backend via socket events
    // No need to start timer manually here
    print('🎮 Round timer will be handled by backend socket events');
  }

  void _startGameIfNeeded() async {
    if (!mounted) return;
    final gameProvider = Provider.of<RealtimeGameProvider>(
      context,
      listen: false,
    );

    print(
      '🎮 Game screen: Current room state: ${gameProvider.currentRoom?.state}',
    );
    print(
      '🎮 Game screen: Current location: ${gameProvider.currentLocation?.name}',
    );

    // For realtime provider, the game is already started via socket events
    // No need to call startGame() here

    // Start the round timer when entering the game screen
    _startRoundTimer();
    print('🎮 Game screen loaded, timer started');
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;

    return Consumer<RealtimeGameProvider>(
      builder: (context, gameProvider, child) {
        final room = gameProvider.currentRoom;
        final player = gameProvider.currentPlayer;
        final location = gameProvider.currentLocation;

        if (room == null || player == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryAccent,
                ),
              ),
            ),
          );
        }

        // Note: Game over navigation is now handled by _setupRoundListeners
        // which automatically navigates to GameEndScreen when state becomes gameOver

        return Scaffold(
          backgroundColor: AppColors.backgroundPrimary,
          appBar: _buildAppBar(room, player),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.backgroundPrimary,
                  AppColors.backgroundSecondary,
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Image section with modern styling
                  if (location != null)
                    Container(
                      height: isSmallScreen ? 140.0 : 180.0,
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: _buildLocationImage(location.imageUrl),
                      ),
                    ),

                  // Map section with modern container
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: AppTheme.brutalistContainer(
                        backgroundColor: AppColors.backgroundTertiary,
                        addShadow: true,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          0,
                        ), // No rounded corners in brutalism
                        child: CampusMap(
                          onTap: (LatLng position) {
                            gameProvider.setGuess(position);
                          },
                          guessLocation: gameProvider.currentGuess,
                        ),
                      ),
                    ),
                  ),

                  // Button section with modern styling
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: _buildSubmitButton(gameProvider),
                  ),
                ],
              ),
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
        // Timer widget
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primaryAccent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '${_timeLeft}s',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Score widget
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ), // Reduced padding
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

  Widget _buildLocationImage(String imageUrl) {
    return GestureDetector(
      onTap: () => _showFullscreenImage(imageUrl),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.all(8),
        decoration: AppTheme.brutalistContainer(
          backgroundColor: AppColors.backgroundSecondary,
          addShadow: true,
        ),
        child: Stack(
          children: [
            ClipRRect(
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primaryAccent,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholderImage();
                },
              ),
            ),
            // Fullscreen icon in the corner
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: AppTheme.brutalistButton(
                  backgroundColor: AppColors.brutalistYellow,
                  addShadow: false,
                ),
                child: const Icon(
                  Icons.fullscreen,
                  color: AppColors.textPrimary,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullscreenImage(String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(0),
        child: Stack(
          children: [
            // Full screen image
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildPlaceholderImage();
                  },
                ),
              ),
            ),
            // Close button
            Positioned(
              top: 40,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: AppTheme.brutalistButton(
                    backgroundColor: AppColors.brutalistRed,
                    addShadow: true,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: AppColors.backgroundTertiary,
                    size: 32,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: AppColors.backgroundSecondary,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_on, color: AppColors.primaryAccent, size: 48),
            SizedBox(height: 8),
            Text(
              'Campus Location',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(RealtimeGameProvider gameProvider) {
    return AnimatedBuilder(
      animation: _buttonScaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _buttonScaleAnimation.value,
          child: Container(
            width: double.infinity, // Full width button for better mobile UX
            height: 48, // Fixed height to prevent overflow
            decoration: gameProvider.hasGuess && !gameProvider.isLoading
                ? AppTheme.brutalistButton(
                    backgroundColor: AppColors.brutalistGreen,
                  )
                : BoxDecoration(
                    color: AppColors.backgroundSecondary,
                    border: Border.all(
                      color: AppColors.brutalistBorder,
                      width: AppColors.brutalistBorderWidth,
                    ),
                  ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: gameProvider.hasGuess && !gameProvider.isLoading
                    ? () => _submitGuess(gameProvider)
                    : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (gameProvider.isLoading) ...[
                        const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ] else if (gameProvider.hasGuess) ...[
                        const Icon(
                          Icons.send_rounded,
                          color: AppColors.textPrimary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                      ],
                      Text(
                        gameProvider.isLoading
                            ? 'Submitting...'
                            : gameProvider.hasGuess
                            ? 'SUBMIT GUESS'
                            : 'TAP ON MAP TO GUESS',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color:
                              gameProvider.hasGuess && !gameProvider.isLoading
                              ? Colors.white
                              : AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _submitGuess(RealtimeGameProvider gameProvider) async {
    if (!mounted || _hasSubmitted)
      return; // Added mounted check and submission check

    _hasSubmitted = true;
    _timerService.stopTimer(); // Stop the timer when guess is submitted

    _buttonAnimationController.forward().then((_) {
      if (mounted) _buttonAnimationController.reverse();
    });

    gameProvider.submitGuess();

    // For realtime provider, we'll listen to the round result stream
    // The result will be handled by the stream listeners in the provider
    if (mounted) {
      _showWaitingForPlayersDialog();
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
                ), //rkg
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final gameProvider = Provider.of<RealtimeGameProvider>(
                  context,
                  listen: false,
                );
                gameProvider.resetGame();
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/', (route) => false);
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
