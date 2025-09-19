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
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppColors.primaryAccent, AppColors.successGreen],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            'SOMAIYA GUESSR',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
        ),
        backgroundColor: AppColors.backgroundSecondary,
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.3),
        centerTitle: true,
      ),
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
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryAccent.withOpacity(0.1),
                AppColors.successGreen.withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primaryAccent.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            'Guess the campus locations and compete with friends!',
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen ? 14 : 16,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
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
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryAccent, AppColors.successGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryAccent.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: AppColors.successGreen.withOpacity(0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _playAsGuest,
                child: Container(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Icon(
                          Icons.play_circle_filled,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'QUICK PLAY',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start playing instantly as a guest',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w400,
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

  Widget _buildCreateRoomSection(bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.backgroundCard,
            AppColors.backgroundCard.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryAccent.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
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
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryAccent, AppColors.accentPurple],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.add_circle,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'CREATE ROOM',
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 18 : 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 20 : 24),
            TextField(
              controller: _roomNameController,
              decoration: InputDecoration(
                labelText: 'Room Name',
                hintText: 'Enter room name',
                prefixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.meeting_room,
                    color: AppColors.primaryAccent,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.borderMedium),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.primaryAccent,
                    width: 2,
                  ),
                ),
              ),
              style: GoogleFonts.poppins(color: AppColors.textPrimary),
            ),
            SizedBox(height: isSmallScreen ? 16 : 20),
            TextField(
              controller: _playerNameController,
              decoration: InputDecoration(
                labelText: 'Your Name',
                hintText: 'Enter your name',
                prefixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: AppColors.primaryAccent,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.borderMedium),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.primaryAccent,
                    width: 2,
                  ),
                ),
              ),
              style: GoogleFonts.poppins(color: AppColors.textPrimary),
            ),
            SizedBox(height: isSmallScreen ? 20 : 28),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryAccent, AppColors.accentPurple],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryAccent.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _createRoom,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: isSmallScreen ? 16 : 20,
                    ),
                    child: Center(
                      child: Text(
                        'CREATE ROOM',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: isSmallScreen ? 16 : 18,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.backgroundCard,
            AppColors.backgroundCard.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.successGreen.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
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
                    gradient: const LinearGradient(
                      colors: [AppColors.successGreen, AppColors.accentGreen],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.login, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  'JOIN ROOM',
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 18 : 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 20 : 24),
            TextField(
              controller: _joinRoomController,
              decoration: InputDecoration(
                labelText: 'Room ID',
                hintText: 'Enter room ID',
                prefixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.vpn_key,
                    color: AppColors.successGreen,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.borderMedium),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.successGreen,
                    width: 2,
                  ),
                ),
              ),
              style: GoogleFonts.poppins(color: AppColors.textPrimary),
            ),
            SizedBox(height: isSmallScreen ? 16 : 20),
            TextField(
              controller: _playerNameController,
              decoration: InputDecoration(
                labelText: 'Your Name',
                hintText: 'Enter your name',
                prefixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: AppColors.successGreen,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.borderMedium),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.successGreen,
                    width: 2,
                  ),
                ),
              ),
              style: GoogleFonts.poppins(color: AppColors.textPrimary),
            ),
            SizedBox(height: isSmallScreen ? 20 : 28),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.successGreen, AppColors.accentGreen],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.successGreen.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _joinRoom,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: isSmallScreen ? 16 : 20,
                    ),
                    child: Center(
                      child: Text(
                        'JOIN ROOM',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: isSmallScreen ? 16 : 18,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
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

    // For realtime provider, create a room and join as guest
    await gameProvider.createRoom('Guest Player');

    if (gameProvider.currentRoom != null && mounted) {
      // Navigate to lobby first, then to game when ready
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => LobbyScreen(
            roomId: gameProvider.currentRoom!.id,
            playerName: 'Guest Player',
          ),
        ),
      );
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
