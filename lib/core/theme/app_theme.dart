import 'package:flutter/material.dart';

/// Centralized Material 3 theme (light + dark). Screen tasks refine the
/// seed color and typography to match the Claude Design tokens once the
/// UI screens are built — no colors should be hard-coded outside this file.
class AppTheme {
  const AppTheme._();

  static const Color _seedColor = Color(0xFFE65100);

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    ),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    ),
  );
}
