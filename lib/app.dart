import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/pages/register_page.dart';

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
      // TODO(TASK-008): replace with Splash -> Login/Home routing.
      home: const RegisterPage(),
    );
  }
}
