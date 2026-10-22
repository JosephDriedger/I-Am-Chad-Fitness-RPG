import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const _seed = Color(0xFFB5651D); // warm guild-hall amber

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: b);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      visualDensity: VisualDensity.standard,
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      // Comfortable touch targets for one-handed use.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size(48, 52)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(minimumSize: const Size(48, 52)),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }
}

/// Appearance options for the placeholder hero avatar.
class HeroLook {
  const HeroLook._();

  static const colors = <Color>[
    Color(0xFF00796B),
    Color(0xFF3949AB),
    Color(0xFFD84315),
    Color(0xFF7B1FA2),
    Color(0xFF558B2F),
    Color(0xFFC2185B),
  ];
  static const colorNames = [
    'Teal',
    'Indigo',
    'Ember',
    'Violet',
    'Moss',
    'Rose',
  ];
  static const icons = <IconData>[
    Icons.face,
    Icons.face_2,
    Icons.face_3,
    Icons.face_4,
    Icons.face_5,
    Icons.face_6,
  ];
}
