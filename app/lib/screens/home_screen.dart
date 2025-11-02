import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/realtime_game_provider.dart';
import '../utils/theme.dart';
import 'game_screen.dart';
import 'lobby_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _roomNameController = TextEditingController();
  final _playerNameController = TextEditingController();
  final _joinRoomController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController
  _pulseController; // Added pulse animation for guest button
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _animationController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _roomNameController.dispose();
    _playerNameController.dispose();
    _joinRoomController.dispose();
    _animationController.dispose();
    _pulseController.dispose(); // Proper cleanup
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.backgroundPrimary,
            border: Border.all(color: AppColors.brutalistBorder, width: 3),
          ),
          child: Text(
            'SOMAIYA GUESSR',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: 2,
            ),
          ),
        ),
        backgroundColor: AppColors.brutalistCyan,
        elevation: 0,
        centerTitle: true,
        // Add hard shadow below app bar
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Container(color: AppColors.brutalistBorder, height: 4),
        ),
      ),
      body: Container(
        color: AppColors.backgroundPrimary,
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              // Added scroll view for better mobile compatibility
              padding: EdgeInsets.all(
                isSmallScreen ? 16.0 : 24.0,
              ), // Responsive padding
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: isSmallScreen ? 10 : 20,
                  ), // Reduced top spacing since we have app bar
                  _buildWelcomeSection(isSmallScreen),
                  SizedBox(height: isSmallScreen ? 20 : 30),
                  _buildGuestPlaySection(), // Added guest play section
                  SizedBox(height: isSmallScreen ? 20 : 30),
                  _buildCreateRoomSection(isSmallScreen),
                  SizedBox(height: isSmallScreen ? 20 : 30),
                  _buildJoinRoomSection(isSmallScreen),
                  SizedBox(height: isSmallScreen ? 20 : 40),
                  _buildLoadingIndicator(),
                  SizedBox(height: isSmallScreen ? 20 : 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(bool isSmallScreen) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: AppTheme.brutalistContainer(
            backgroundColor: AppColors.brutalistPink,
            addShadow: true,
          ),
          child: Text(
            'GUESS THE CAMPUS LOCATIONS!',
            style: GoogleFonts.spaceGrotesk(
              fontSize: isSmallScreen ? 16 : 18,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildGuestPlaySection() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: GestureDetector(
            onTap: _playAsGuest,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32.0),
              decoration: AppTheme.brutalistButton(
                backgroundColor: AppColors.brutalistYellow,
                addShadow: true,
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.textPrimary,
                      border: Border.all(
                        color: AppColors.brutalistBorder,
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      Icons.play_circle_filled,
                      color: AppColors.brutalistYellow,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'QUICK PLAY',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'START INSTANTLY!',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
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

  Widget _buildCreateRoomSection(bool isSmallScreen) {
    return Container(
      decoration: AppTheme.brutalistContainer(
        backgroundColor: AppColors.backgroundTertiary,
        addShadow: true,
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 20.0 : 28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.brutalistPurple,
                    border: Border.all(
                      color: AppColors.brutalistBorder,
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    Icons.add_circle,
                    color: AppColors.backgroundTertiary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'CREATE ROOM',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: isSmallScreen ? 20 : 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 20 : 24),
            TextField(
              controller: _roomNameController,
              decoration: InputDecoration(
                labelText: 'ROOM NAME',
                hintText: 'Enter room name',
                labelStyle: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.brutalistYellow,
                    border: Border.all(
                      color: AppColors.brutalistBorder,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.meeting_room,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: isSmallScreen ? 16 : 20),
            TextField(
              controller: _playerNameController,
              decoration: InputDecoration(
                labelText: 'YOUR NAME',
                hintText: 'Enter your name',
                labelStyle: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.brutalistYellow,
                    border: Border.all(
                      color: AppColors.brutalistBorder,
                      width: 2,
                    ),
                  ),
                  child: const Icon(Icons.person, color: AppColors.textPrimary),
                ),
              ),
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: isSmallScreen ? 20 : 28),
            GestureDetector(
              onTap: _createRoom,
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: isSmallScreen ? 18 : 22,
                ),
                decoration: AppTheme.brutalistButton(
                  backgroundColor: AppColors.brutalistPurple,
                ),
                child: Center(
                  child: Text(
                    'CREATE ROOM',
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w900,
                      fontSize: isSmallScreen ? 16 : 18,
                      color: AppColors.backgroundTertiary,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinRoomSection(bool isSmallScreen) {
    return Container(
      decoration: AppTheme.brutalistContainer(
        backgroundColor: AppColors.backgroundTertiary,
        addShadow: true,
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 20.0 : 28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.brutalistGreen,
                    border: Border.all(
                      color: AppColors.brutalistBorder,
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    Icons.login,
                    color: AppColors.backgroundTertiary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'JOIN ROOM',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: isSmallScreen ? 20 : 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 20 : 24),
            TextField(
              controller: _joinRoomController,
              decoration: InputDecoration(
                labelText: 'ROOM ID',
                hintText: 'Enter room ID',
                labelStyle: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.brutalistCyan,
                    border: Border.all(
                      color: AppColors.brutalistBorder,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.vpn_key,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: isSmallScreen ? 16 : 20),
            TextField(
              controller: _playerNameController,
              decoration: InputDecoration(
                labelText: 'YOUR NAME',
                hintText: 'Enter your name',
                labelStyle: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.brutalistCyan,
                    border: Border.all(
                      color: AppColors.brutalistBorder,
                      width: 2,
                    ),
                  ),
                  child: const Icon(Icons.person, color: AppColors.textPrimary),
                ),
              ),
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: isSmallScreen ? 20 : 28),
            GestureDetector(
              onTap: _joinRoom,
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: isSmallScreen ? 18 : 22,
                ),
                decoration: AppTheme.brutalistButton(
                  backgroundColor: AppColors.brutalistGreen,
                ),
                child: Center(
                  child: Text(
                    'JOIN ROOM',
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w900,
                      fontSize: isSmallScreen ? 16 : 18,
                      color: AppColors.backgroundTertiary,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Consumer<RealtimeGameProvider>(
      builder: (context, gameProvider, child) {
        if (gameProvider.isLoading) {
          return const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
          );
        }
        if (gameProvider.error != null) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.errorRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.errorRed),
            ),
            child: Row(
              children: [
                const Icon(Icons.error, color: AppColors.errorRed),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    gameProvider.error!,
                    style: GoogleFonts.poppins(
                      color: AppColors.errorRed,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => gameProvider.clearError(),
                  icon: const Icon(Icons.close, color: AppColors.errorRed),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _playAsGuest() async {
    final gameProvider = Provider.of<RealtimeGameProvider>(
      context,
      listen: false,
    );

    // For single-player mode, create a room and auto-start the game
    await gameProvider.createRoom('Guest Player');

    if (gameProvider.currentRoom != null && mounted) {
      // Auto-ready and start the game for single player
      gameProvider.setPlayerReady(true);

      // Small delay to ensure ready state is processed
      await Future.delayed(const Duration(milliseconds: 300));

      // Auto-start the game immediately for single player
      gameProvider.startGame();

      // Navigate directly to game screen, skipping lobby
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const GameScreen()));
    }
  }

  void _createRoom() async {
    if (_roomNameController.text.trim().isEmpty ||
        _playerNameController.text.trim().isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    final gameProvider = Provider.of<RealtimeGameProvider>(
      context,
      listen: false,
    );
    await gameProvider.createRoom(_playerNameController.text.trim());

    if (gameProvider.currentRoom != null && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => LobbyScreen(
            roomId: gameProvider.currentRoom!.id,
            playerName: _playerNameController.text.trim(),
          ),
        ),
      );
    } else if (gameProvider.error != null) {
      _showError(gameProvider.error!);
    }
  }

  void _joinRoom() async {
    if (_joinRoomController.text.trim().isEmpty ||
        _playerNameController.text.trim().isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    final gameProvider = Provider.of<RealtimeGameProvider>(
      context,
      listen: false,
    );
    await gameProvider.joinRoom(
      _joinRoomController.text.trim(),
      _playerNameController.text.trim(),
    );

    if (gameProvider.currentRoom != null && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => LobbyScreen(
            roomId: _joinRoomController.text.trim(),
            playerName: _playerNameController.text.trim(),
          ),
        ),
      );
    } else if (gameProvider.error != null) {
      _showError(gameProvider.error!);
    }
  }

  void _showError(String message) {
    if (!mounted) return; // Added mounted check
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: AppColors.errorRed,
        behavior: SnackBarBehavior.floating, // Better snackbar styling
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
