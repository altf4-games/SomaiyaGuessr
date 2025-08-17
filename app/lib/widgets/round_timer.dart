import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme.dart';

class RoundTimer extends StatefulWidget {
  final int timeLeft;
  final int totalTime;
  final VoidCallback? onTimeUp;
  final bool isActive;

  const RoundTimer({
    super.key,
    required this.timeLeft,
    this.totalTime = 30,
    this.onTimeUp,
    this.isActive = true,
  });

  @override
  State<RoundTimer> createState() => _RoundTimerState();
}

class _RoundTimerState extends State<RoundTimer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  int? _lastTimeLeft;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void didUpdateWidget(RoundTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Trigger animation when time changes
    if (widget.timeLeft != _lastTimeLeft) {
      _lastTimeLeft = widget.timeLeft;
      
      if (widget.timeLeft <= 5 && widget.timeLeft > 0) {
        // Animate for last 5 seconds
        _animationController.forward().then((_) {
          _animationController.reverse();
        });
      }
      
      // Call onTimeUp when timer reaches 0
      if (widget.timeLeft == 0 && oldWidget.timeLeft > 0) {
        widget.onTimeUp?.call();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.totalTime > 0 
        ? (widget.totalTime - widget.timeLeft) / widget.totalTime 
        : 1.0;
    
    final isUrgent = widget.timeLeft <= 10;
    final isCritical = widget.timeLeft <= 5;
    
    Color timerColor;
    if (isCritical) {
      timerColor = AppColors.errorRed;
    } else if (isUrgent) {
      timerColor = Colors.orange;
    } else {
      timerColor = AppColors.primaryAccent;
    }

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isCritical ? _scaleAnimation.value : 1.0,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.backgroundSecondary,
              border: Border.all(
                color: timerColor,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: timerColor.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Progress indicator
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 6,
                    backgroundColor: AppColors.textSecondary.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(timerColor),
                  ),
                ),
                
                // Time text
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${widget.timeLeft}',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: timerColor,
                      ),
                    ),
                    Text(
                      'seconds',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class CompactRoundTimer extends StatelessWidget {
  final int timeLeft;
  final int totalTime;
  final bool isActive;

  const CompactRoundTimer({
    super.key,
    required this.timeLeft,
    this.totalTime = 30,
    this.isActive = true,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalTime > 0 
        ? (totalTime - timeLeft) / totalTime 
        : 1.0;
    
    final isUrgent = timeLeft <= 10;
    final isCritical = timeLeft <= 5;
    
    Color timerColor;
    if (isCritical) {
      timerColor = AppColors.errorRed;
    } else if (isUrgent) {
      timerColor = Colors.orange;
    } else {
      timerColor = AppColors.primaryAccent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: timerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 3,
              backgroundColor: AppColors.textSecondary.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(timerColor),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${timeLeft}s',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: timerColor,
            ),
          ),
        ],
      ),
    );
  }
}

class TimerWarningDialog extends StatelessWidget {
  final int timeLeft;
  final VoidCallback? onSubmit;
  final VoidCallback? onContinue;

  const TimerWarningDialog({
    super.key,
    required this.timeLeft,
    this.onSubmit,
    this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.backgroundSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            Icons.timer,
            color: AppColors.errorRed,
            size: 28,
          ),
          const SizedBox(width: 8),
          Text(
            'Time Running Out!',
            style: GoogleFonts.poppins(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      content: Text(
        'Only $timeLeft seconds left! Submit your guess now or it will be auto-submitted.',
        style: GoogleFonts.poppins(
          color: AppColors.textSecondary,
        ),
      ),
      actions: [
        TextButton(
          onPressed: onContinue,
          child: Text(
            'Continue',
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: onSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryAccent,
          ),
          child: Text(
            'Submit Now',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
