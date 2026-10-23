import 'package:flutter/material.dart';

import 'game_ui.dart';

/// One game theme for the whole app: parchment, wood and gold, with a chunky
/// display font for titles. It deliberately ignores the system dark mode so
/// the world always looks like itself.
class AppTheme {
  const AppTheme._();

  static ThemeData game() {
    final scheme = ColorScheme.fromSeed(
      seedColor: GameColors.woodLight,
      brightness: Brightness.light,
    ).copyWith(
      primary: GameColors.wood,
      onPrimary: GameColors.cream,
      primaryContainer: const Color(0xFFFFD9A8),
      onPrimaryContainer: GameColors.woodDark,
      secondary: GameColors.goldDark,
      tertiaryContainer: const Color(0xFFE2E6B0),
      onTertiaryContainer: const Color(0xFF3F4A14),
      surface: GameColors.parchment,
      onSurface: GameColors.ink,
      onSurfaceVariant: GameColors.inkSoft,
      surfaceContainerHighest: GameColors.parchmentDark,
      surfaceContainerHigh: GameColors.parchmentDark,
      outline: GameColors.woodLight,
      outlineVariant: const Color(0xFFCDB68A),
      error: GameColors.red,
    );

    final base = Typography.material2021(platform: TargetPlatform.android).black.apply(
          bodyColor: GameColors.ink,
          displayColor: GameColors.ink,
        );

    TextStyle display(TextStyle? s, double size) =>
        (s ?? const TextStyle()).copyWith(fontFamily: gameFont, fontSize: size, fontWeight: FontWeight.w400, height: 1.1);

    final text = base.copyWith(
      displayLarge: display(base.displayLarge, 48),
      displayMedium: display(base.displayMedium, 42),
      displaySmall: display(base.displaySmall, 36),
      headlineLarge: display(base.headlineLarge, 32),
      headlineMedium: display(base.headlineMedium, 28),
      headlineSmall: display(base.headlineSmall, 26),
      titleLarge: display(base.titleLarge, 22),
      titleMedium: display(base.titleMedium, 18),
      titleSmall: display(base.titleSmall, 16),
    );

    final wood = BorderSide(color: GameColors.wood, width: 2.5);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: GameColors.parchment,
      textTheme: text,
      cardTheme: CardThemeData(
        elevation: 0,
        color: GameColors.parchment,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: wood),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: GameColors.parchment,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: wood),
        titleTextStyle: gameTitle(24),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: GameColors.woodDark,
        contentTextStyle: const TextStyle(color: GameColors.cream, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: GameColors.gold,
          foregroundColor: GameColors.ink,
          minimumSize: const Size(48, 52),
          textStyle: gameTitle(19),
          elevation: 3,
          shadowColor: GameColors.goldDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: GameColors.goldDark, width: 2)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: GameColors.wood,
          minimumSize: const Size(48, 52),
          textStyle: gameTitle(18),
          side: wood,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: GameColors.wood,
          textStyle: gameTitle(17),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFFF8E6),
        labelStyle: const TextStyle(color: GameColors.inkSoft, fontWeight: FontWeight.w600),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: wood),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: wood),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: GameColors.goldDark, width: 3),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFFFF8E6),
        selectedColor: const Color(0xFFFFD95E),
        side: BorderSide(color: GameColors.woodLight, width: 1.8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        labelStyle: const TextStyle(color: GameColors.ink, fontWeight: FontWeight.w800),
        checkmarkColor: GameColors.ink,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? GameColors.cream : GameColors.inkSoft,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? GameColors.green : GameColors.parchmentDark,
        ),
        trackOutlineColor: WidgetStateProperty.all(GameColors.wood),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: const Color(0xFFFFF8E6),
          foregroundColor: GameColors.ink,
          selectedBackgroundColor: GameColors.gold,
          selectedForegroundColor: GameColors.ink,
          side: wood,
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: GameColors.gold,
        linearTrackColor: GameColors.woodDark,
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFCDB68A), thickness: 2),
      listTileTheme: const ListTileThemeData(iconColor: GameColors.wood, textColor: GameColors.ink),
      iconTheme: const IconThemeData(color: GameColors.wood),
    );
  }
}
