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
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.backgroundSecondary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSection('Game Settings', [
            _buildSettingTile(
              icon: Icons.volume_up,
              title: 'Sound Effects',
              subtitle: 'Enable game sound effects',
              trailing: Switch(
                value: true,
                onChanged: (value) {
                  // TODO: Implement sound settings
                },
                activeColor: AppColors.primaryAccent,
              ),
            ),
            _buildSettingTile(
              icon: Icons.timer,
              title: 'Round Timer',
              subtitle: 'Default time per round',
              trailing: Text(
                '30s',
                style: GoogleFonts.poppins(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                // TODO: Show timer selection dialog
              },
            ),
            _buildSettingTile(
              icon: Icons.notifications,
              title: 'Notifications',
              subtitle: 'Game and room notifications',
              trailing: Switch(
                value: true,
                onChanged: (value) {
                  // TODO: Implement notification settings
                },
                activeColor: AppColors.primaryAccent,
              ),
            ),
          ]),
          const SizedBox(height: 24),
          _buildSection('App Settings', [
            _buildSettingTile(
              icon: Icons.dark_mode,
              title: 'Dark Theme',
              subtitle: 'Always enabled for better experience',
              trailing: Icon(Icons.check, color: AppColors.successGreen),
            ),
            _buildSettingTile(
              icon: Icons.language,
              title: 'Language',
              subtitle: 'English',
              trailing: Icon(
                Icons.arrow_forward_ios,
                color: AppColors.textSecondary,
                size: 16,
              ),
              onTap: () {
                // TODO: Show language selection
              },
            ),
          ]),
          const SizedBox(height: 24),
          _buildSection('About', [
            _buildSettingTile(
              icon: Icons.info,
              title: 'About Somaiya Guessr',
              subtitle: 'Version 1.0.0',
              onTap: () {
                _showAboutDialog(context);
              },
            ),
            _buildSettingTile(
              icon: Icons.help,
              title: 'How to Play',
              subtitle: 'Learn the game rules',
              onTap: () {
                _showHowToPlay(context);
              },
            ),
            _buildSettingTile(
              icon: Icons.feedback,
              title: 'Send Feedback',
              subtitle: 'Help us improve the game',
              onTap: () {
                // TODO: Implement feedback functionality
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
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryAccent,
            ),
          ),
        ),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primaryAccent, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'About Somaiya Guessr',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Somaiya Guessr is a location guessing game focused on the Somaiya campus. Test your knowledge of campus locations and compete with friends!\n\nVersion 1.0.0',
          style: GoogleFonts.poppins(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(
                color: AppColors.primaryAccent,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showHowToPlay(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'How to Play',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildRule('1.', 'Create or join a room to play with friends'),
              _buildRule('2.', 'Look at the campus location image shown'),
              _buildRule(
                '3.',
                'Tap on the map where you think the location is',
              ),
              _buildRule('4.', 'Submit your guess before time runs out'),
              _buildRule('5.', 'Get points based on how close your guess is'),
              _buildRule('6.', 'Player with the highest total score wins!'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Got it!',
              style: GoogleFonts.poppins(
                color: AppColors.primaryAccent,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRule(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number,
            style: GoogleFonts.poppins(
              color: AppColors.primaryAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
