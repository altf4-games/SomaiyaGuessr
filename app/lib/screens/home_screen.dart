import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/realtime_game_provider.dart';
import '../utils/theme.dart';
import 'game_screen.dart';
import 'lobby_screen.dart';
import 'realtime_test_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  final _roomNameController = TextEditingController();
  final _playerNameController = TextEditingController();
  final _joinRoomController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _pulseController; // Added pulse animation for guest button
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
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
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView( // Added scroll view for better mobile compatibility
            padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0), // Responsive padding
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: isSmallScreen ? 20 : 40), // Responsive spacing
                _buildHeader(isSmallScreen),
                SizedBox(height: isSmallScreen ? 30 : 40),
                _buildGuestPlaySection(), // Added guest play section
                SizedBox(height: isSmallScreen ? 20 : 30),
                _buildCreateRoomSection(isSmallScreen),
                SizedBox(height: isSmallScreen ? 20 : 30),
                _buildJoinRoomSection(isSmallScreen),
                SizedBox(height: isSmallScreen ? 20 : 30),
                _buildRealtimeTestButton(),
                SizedBox(height: isSmallScreen ? 20 : 40),
                _buildLoadingIndicator(),
                SizedBox(height: isSmallScreen ? 20 : 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isSmallScreen) {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppColors.primaryAccent, AppColors.successGreen],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            'SOMAIYA GUESSR',
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen ? 28 : 32, // Responsive font size
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
        Text(
          'Guess the campus locations and compete with friends!',
          style: GoogleFonts.poppins(
            fontSize: isSmallScreen ? 14 : 16, // Responsive font size
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
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
                onTap: _playAsGuest,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.play_circle_filled,
                        color: Colors.white,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'QUICK PLAY',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
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
    return Card(
      elevation: 8, // Increased elevation for better depth
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Rounded corners
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0), // Responsive padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row( // Added icon to section header
              children: [
                const Icon(Icons.add_circle, color: AppColors.primaryAccent, size: 24),
                const SizedBox(width: 8),
                Text(
                  'CREATE ROOM',
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 16 : 18, // Responsive font size
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryAccent,
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 16 : 20),
            TextField(
              controller: _roomNameController,
              decoration: InputDecoration(
                labelText: 'Room Name',
                hintText: 'Enter room name',
                prefixIcon: const Icon(Icons.meeting_room, color: AppColors.primaryAccent),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), // Rounded input borders
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primaryAccent, width: 2),
                ),
              ),
              style: GoogleFonts.poppins(color: AppColors.textPrimary),
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            TextField(
              controller: _playerNameController,
              decoration: InputDecoration(
                labelText: 'Your Name',
                hintText: 'Enter your name',
                prefixIcon: const Icon(Icons.person, color: AppColors.primaryAccent),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primaryAccent, width: 2),
                ),
              ),
              style: GoogleFonts.poppins(color: AppColors.textPrimary),
            ),
            SizedBox(height: isSmallScreen ? 16 : 24),
            ElevatedButton(
              onPressed: _createRoom,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAccent,
                padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 16), // Responsive button padding
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
              ),
              child: Text(
                'CREATE ROOM',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: isSmallScreen ? 14 : 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinRoomSection(bool isSmallScreen) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row( // Added icon to section header
              children: [
                const Icon(Icons.login, color: AppColors.primaryAccent, size: 24),
                const SizedBox(width: 8),
                Text(
                  'JOIN ROOM',
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryAccent,
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 16 : 20),
            TextField(
              controller: _joinRoomController,
              decoration: InputDecoration(
                labelText: 'Room ID',
                hintText: 'Enter room ID',
                prefixIcon: const Icon(Icons.vpn_key, color: AppColors.primaryAccent),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primaryAccent, width: 2),
                ),
              ),
              style: GoogleFonts.poppins(color: AppColors.textPrimary),
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            TextField(
              controller: _playerNameController,
              decoration: InputDecoration(
                labelText: 'Your Name',
                hintText: 'Enter your name',
                prefixIcon: const Icon(Icons.person, color: AppColors.primaryAccent),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primaryAccent, width: 2),
                ),
              ),
              style: GoogleFonts.poppins(color: AppColors.textPrimary),
            ),
            SizedBox(height: isSmallScreen ? 16 : 24),
            ElevatedButton(
              onPressed: _joinRoom,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.successGreen,
                padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
              ),
              child: Text(
                'JOIN ROOM',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: isSmallScreen ? 14 : 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRealtimeTestButton() {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const RealtimeTestScreen()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Realtime Test (Debug)',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
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
              color: AppColors.errorRed.withOpacity(0.1),
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
    final gameProvider = Provider.of<RealtimeGameProvider>(context, listen: false);

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

    final gameProvider = Provider.of<RealtimeGameProvider>(context, listen: false);
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

    final gameProvider = Provider.of<RealtimeGameProvider>(context, listen: false);
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
        content: Text(
          message,
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: AppColors.errorRed,
        behavior: SnackBarBehavior.floating, // Better snackbar styling
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
