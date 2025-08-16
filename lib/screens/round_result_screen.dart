import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/game_models.dart';
import '../providers/game_provider.dart';
import '../utils/theme.dart';
import 'game_screen.dart';
import 'game_over_screen.dart';

class RoundResultScreen extends StatefulWidget {
  final RoundResult result;

  const RoundResultScreen({
    super.key,
    required this.result,
  });

  @override
  State<RoundResultScreen> createState() => _RoundResultScreenState();
}

class _RoundResultScreenState extends State<RoundResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _scoreController;
  late Animation<Offset> _slideAnimation;
  late Animation<int> _scoreAnimation;

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scoreController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _scoreAnimation = IntTween(
      begin: 0,
      end: widget.result.score,
    ).animate(CurvedAnimation(
      parent: _scoreController,
      curve: Curves.easeOutCubic,
    ));

    _slideController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      _scoreController.forward();
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Round ${widget.result.round} Result',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: _buildResultMap(),
          ),
          Expanded(
            flex: 2,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildResultCard(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultMap() {
    final bounds = widget.result.guessLocation != null
        ? LatLngBounds.fromPoints([
            widget.result.guessLocation!,
            widget.result.actualLocation,
          ])
        : LatLngBounds.fromPoints([widget.result.actualLocation]);

    return FlutterMap(
      options: MapOptions(
        initialCenter: widget.result.actualLocation,
        initialZoom: 13,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.somaiya.guessr',
        ),
        if (widget.result.guessLocation != null)
          PolylineLayer(
            polylines: [
              Polyline(
                points: [
                  widget.result.guessLocation!,
                  widget.result.actualLocation,
                ],
                color: AppColors.textPrimary,
                strokeWidth: 3,
                pattern: StrokePattern.dashed(segments: [10, 6]),
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            if (widget.result.guessLocation != null)
              Marker(
                point: widget.result.guessLocation!,
                width: 40,
                height: 40,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.primaryAccent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            Marker(
              point: widget.result.actualLocation,
              width: 40,
              height: 40,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.successGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.flag,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResultCard() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            _buildScoreDisplay(),
            const SizedBox(height: 24),
            _buildDistanceInfo(),
            const Spacer(),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreDisplay() {
    return Column(
      children: [
        Text(
          'ROUND SCORE',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _scoreAnimation,
          builder: (context, child) {
            return Text(
              '+${_scoreAnimation.value}',
              style: GoogleFonts.poppins(
                fontSize: 48,
                fontWeight: FontWeight.w700,
                color: AppColors.successGreen,
              ),
            );
          },
        ),
        Text(
          'POINTS',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildDistanceInfo() {
    final distance = widget.result.distance;
    final distanceText = distance < 1000
        ? '${distance.toInt()}m'
        : '${(distance / 1000).toStringAsFixed(1)}km';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundPrimary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.straighten,
            color: AppColors.primaryAccent,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            widget.result.guessLocation != null
                ? '$distanceText away'
                : 'No guess made',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        final room = gameProvider.currentRoom;
        final isLastRound = room != null && room.currentRound >= room.totalRounds;

        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: gameProvider.isLoading ? null : () => _nextAction(gameProvider, isLastRound),
            child: gameProvider.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.backgroundPrimary,
                      ),
                    ),
                  )
                : Text(
                    isLastRound ? 'VIEW FINAL RESULTS' : 'NEXT ROUND',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
          ),
        );
      },
    );
  }

  void _nextAction(GameProvider gameProvider, bool isLastRound) async {
    if (!mounted) return;
    
    try {
      if (isLastRound) {
        // End the game and navigate to game over
        await gameProvider.endGame();
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const GameOverScreen()),
          );
        }
      } else {
        // Start next round
        await gameProvider.nextRound();
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const GameScreen()),
          );
        }
      }
    } catch (e) {
      // Handle errors gracefully
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }
}
