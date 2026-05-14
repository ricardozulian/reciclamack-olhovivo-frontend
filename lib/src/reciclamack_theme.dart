import 'package:flutter/material.dart';

import 'design_tokens.dart';

ThemeData buildReciclaMackTheme() {
  const fontFamily = 'PlusJakartaSans';
  final colorScheme = ColorScheme.fromSeed(
    seedColor: ReciclaColors.primary,
    brightness: Brightness.dark,
  ).copyWith(
    primary: ReciclaColors.primary,
    onPrimary: ReciclaColors.onPrimary,
    surface: ReciclaColors.bg,
    onSurface: ReciclaColors.fg1,
    onSurfaceVariant: ReciclaColors.fg2,
    error: ReciclaColors.error,
    outline: ReciclaColors.border,
    outlineVariant: ReciclaColors.borderEmphasis,
  );

  const textTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 56,
      fontWeight: FontWeight.w800,
      color: ReciclaColors.fg1,
      letterSpacing: -1.5,
      height: 1.1,
    ),
    displayMedium: TextStyle(
      fontSize: 40,
      fontWeight: FontWeight.w800,
      color: ReciclaColors.fg1,
      letterSpacing: -0.8,
      height: 1.2,
    ),
    headlineLarge: TextStyle(
      fontSize: 30,
      fontWeight: FontWeight.w700,
      color: ReciclaColors.fg1,
      letterSpacing: -0.3,
      height: 1.2,
    ),
    headlineMedium: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: ReciclaColors.fg1,
      height: 1.35,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: ReciclaColors.fg1,
      height: 1.35,
    ),
    titleMedium: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: ReciclaColors.fg1,
      height: 1.35,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: ReciclaColors.fg2,
      height: 1.65,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: ReciclaColors.fg2,
      height: 1.5,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: ReciclaColors.fg3,
      height: 1.5,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: ReciclaColors.fg1,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: ReciclaColors.primary,
      letterSpacing: 0.6,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: ReciclaColors.fg3,
      letterSpacing: 0.5,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: ReciclaColors.bg,
    fontFamily: fontFamily,
    textTheme: textTheme.apply(fontFamily: fontFamily),
    appBarTheme: const AppBarTheme(
      backgroundColor: ReciclaColors.bgElevated,
      foregroundColor: ReciclaColors.fg1,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: ReciclaColors.fg1,
      ),
      shape: Border(
        bottom: BorderSide(color: ReciclaColors.border, width: 1),
      ),
    ),
    cardTheme: CardThemeData(
      color: ReciclaColors.bgCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ReciclaRadii.md),
        side: const BorderSide(color: ReciclaColors.border, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ReciclaColors.primary,
        foregroundColor: ReciclaColors.onPrimary,
        disabledBackgroundColor: ReciclaColors.bgCard,
        disabledForegroundColor: ReciclaColors.fg3,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ReciclaRadii.pill),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ReciclaColors.primary,
        side: const BorderSide(color: ReciclaColors.primary, width: 1.5),
        disabledForegroundColor: ReciclaColors.fg3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ReciclaRadii.pill),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: ReciclaColors.primary,
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: ReciclaColors.primary,
      linearTrackColor: ReciclaColors.bgCard,
    ),
    dividerTheme: const DividerThemeData(
      color: ReciclaColors.divider,
      thickness: 1,
      space: 1,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: ReciclaColors.primarySurface,
      labelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: ReciclaColors.primary,
      ),
      side: const BorderSide(color: ReciclaColors.primaryBorder, width: 1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ReciclaRadii.pill),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: ReciclaColors.bgInput,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ReciclaRadii.sm),
        borderSide: const BorderSide(color: ReciclaColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ReciclaRadii.sm),
        borderSide: const BorderSide(color: ReciclaColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ReciclaRadii.sm),
        borderSide: const BorderSide(color: ReciclaColors.primary, width: 1.5),
      ),
      labelStyle: const TextStyle(color: ReciclaColors.fg2),
      hintStyle: const TextStyle(color: ReciclaColors.fg3),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: ReciclaColors.bgElevated,
      contentTextStyle: const TextStyle(color: ReciclaColors.fg1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ReciclaRadii.sm),
      ),
    ),
  );
}
