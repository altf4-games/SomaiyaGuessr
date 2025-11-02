import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
            'SETTINGS',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: 2,
            ),
          ),
        ),
        backgroundColor: AppColors.brutalistPurple,
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Container(color: AppColors.brutalistBorder, height: 4),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          _buildSection('ABOUT', [
            _buildSettingTile(
              context: context,
              icon: Icons.info,
              title: 'ABOUT SOMAIYA GUESSR',
              subtitle: 'Version 1.0.0',
              color: AppColors.brutalistCyan,
              onTap: () {
                _showAboutDialog(context);
              },
            ),
          ]),
          const SizedBox(height: 24),
          _buildSection('HELP', [
            _buildSettingTile(
              context: context,
              icon: Icons.help,
              title: 'HOW TO PLAY',
              subtitle: 'Learn the game rules',
              color: AppColors.brutalistGreen,
              onTap: () {
                _showHowToPlay(context);
              },
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.brutalistYellow,
            border: Border.all(color: AppColors.brutalistBorder, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowColor,
                offset: const Offset(4, 4),
                blurRadius: 0,
              ),
            ],
          ),
          child: Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: 1,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildSettingTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.brutalistContainer(
          backgroundColor: AppColors.backgroundTertiary,
          addShadow: true,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                border: Border.all(color: AppColors.brutalistBorder, width: 3),
              ),
              child: Icon(icon, color: AppColors.textPrimary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward, color: AppColors.textPrimary, size: 24),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: AppTheme.brutalistContainer(
            backgroundColor: AppColors.backgroundTertiary,
            addShadow: true,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.brutalistCyan,
                  border: Border.all(
                    color: AppColors.brutalistBorder,
                    width: 3,
                  ),
                ),
                child: Text(
                  'ABOUT',
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    color: AppColors.textPrimary,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Somaiya Guessr is a location guessing game focused on the Somaiya campus. Test your knowledge of campus locations and compete with friends!',
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.brutalistPink,
                  border: Border.all(
                    color: AppColors.brutalistBorder,
                    width: 2,
                  ),
                ),
                child: Text(
                  'VERSION 1.0.0',
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: AppTheme.brutalistButton(
                    backgroundColor: AppColors.brutalistGreen,
                  ),
                  child: Center(
                    child: Text(
                      'GOT IT!',
                      style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHowToPlay(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: AppTheme.brutalistContainer(
            backgroundColor: AppColors.backgroundTertiary,
            addShadow: true,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.brutalistGreen,
                  border: Border.all(
                    color: AppColors.brutalistBorder,
                    width: 3,
                  ),
                ),
                child: Text(
                  'HOW TO PLAY',
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    color: AppColors.textPrimary,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildRule('1', 'Create or join a room'),
              _buildRule('2', 'Look at the campus location image'),
              _buildRule('3', 'Tap on the map where you think it is'),
              _buildRule('4', 'Submit your guess before time runs out'),
              _buildRule('5', 'Get points based on accuracy'),
              _buildRule('6', 'Highest total score wins!'),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: AppTheme.brutalistButton(
                    backgroundColor: AppColors.brutalistOrange,
                  ),
                  child: Center(
                    child: Text(
                      'GOT IT!',
                      style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRule(String number, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        border: Border.all(color: AppColors.brutalistBorder, width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.brutalistYellow,
              border: Border.all(color: AppColors.brutalistBorder, width: 2),
            ),
            child: Center(
              child: Text(
                number,
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
