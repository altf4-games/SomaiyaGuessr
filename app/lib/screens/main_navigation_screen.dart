import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme.dart';
import 'home_screen.dart';
import 'settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [const HomeScreen(), const SettingsScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundTertiary,
          border: Border(
            top: BorderSide(color: AppColors.brutalistBorder, width: 4),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppColors.brutalistPurple,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: 1,
          ),
          unselectedLabelStyle: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          items: [
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: _currentIndex == 0
                    ? BoxDecoration(
                        color: AppColors.brutalistYellow,
                        border: Border.all(
                          color: AppColors.brutalistBorder,
                          width: 3,
                        ),
                      )
                    : null,
                child: Icon(
                  _currentIndex == 0 ? Icons.home : Icons.home_outlined,
                  size: 24,
                  color: _currentIndex == 0
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
              label: 'HOME',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: _currentIndex == 1
                    ? BoxDecoration(
                        color: AppColors.brutalistPurple,
                        border: Border.all(
                          color: AppColors.brutalistBorder,
                          width: 3,
                        ),
                      )
                    : null,
                child: Icon(
                  _currentIndex == 1 ? Icons.settings : Icons.settings_outlined,
                  size: 24,
                  color: _currentIndex == 1
                      ? AppColors.backgroundTertiary
                      : AppColors.textSecondary,
                ),
              ),
              label: 'SETTINGS',
            ),
          ],
        ),
      ),
    );
  }
}
