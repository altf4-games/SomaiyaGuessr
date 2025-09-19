import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/main_navigation_screen.dart';
import 'providers/game_provider.dart';
import 'providers/realtime_game_provider.dart';
import 'utils/theme.dart';

void main() {
  runApp(const SomaiyaGuessrApp());
}

class SomaiyaGuessrApp extends StatelessWidget {
  const SomaiyaGuessrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameProvider()),
        ChangeNotifierProvider(create: (_) => RealtimeGameProvider()),
      ],
      child: MaterialApp(
        title: 'Somaiya Guessr',
        theme: AppTheme.darkTheme,
        home: const MainNavigationScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
