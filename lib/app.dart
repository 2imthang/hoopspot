import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';

class HoopSpotApp extends StatelessWidget {
  const HoopSpotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HoopSpot',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const _SetupPlaceholder(),
    );
  }
}

/// Placeholder home so the app builds and runs after the architecture
/// setup (TASK-002). Replaced by the real Splash screen in TASK-008.
class _SetupPlaceholder extends StatelessWidget {
  const _SetupPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('HoopSpot — project structure ready')),
    );
  }
}
