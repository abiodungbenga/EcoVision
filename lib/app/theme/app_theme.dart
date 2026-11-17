import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static const Color primaryColor = Color(0xFF234B3D);
  static const Color secondaryColor = Color(0xFF63775B);
  static const Color accentColor = Color(0xFFB88A5A);

  static ThemeData get lightTheme => _buildTheme(
    brightness: Brightness.light,
    palette: AppPalette.light,
  );

  static ThemeData get darkTheme => _buildTheme(
    brightness: Brightness.dark,
    palette: AppPalette.dark,
  );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required AppPalette palette,
  }) {
    final isLight = brightness == Brightness.light;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: isLight ? primaryColor : palette.primary,
      brightness: brightness,
      primary: palette.primary,
      onPrimary: palette.onPrimary,
      secondary: isLight ? secondaryColor : palette.accent,
      surface: palette.surface,
      onSurface: palette.text,
      error: palette.error,
      onError: palette.onPrimary,
      outline: palette.divider,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: AppTypography.fontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: palette.background,
      extensions: [palette],
      textTheme: Typography.material2021()
          .black
          .apply(
            fontFamily: AppTypography.fontFamily,
            bodyColor: palette.text,
            displayColor: palette.text,
          )
          .copyWith(
            displayLarge: AppTypography.display.copyWith(color: palette.text),
            headlineLarge: AppTypography.heading.copyWith(color: palette.text),
            headlineMedium: AppTypography.title.copyWith(color: palette.text),
            titleLarge: AppTypography.title.copyWith(color: palette.text),
            bodyLarge: AppTypography.body.copyWith(color: palette.text),
            bodyMedium: AppTypography.body.copyWith(color: palette.text),
            bodySmall: AppTypography.caption.copyWith(
              color: palette.secondaryText,
            ),
            labelLarge: AppTypography.label.copyWith(
              color: palette.secondaryText,
            ),
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        foregroundColor: palette.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: palette.text),
        titleTextStyle: AppTypography.title.copyWith(
          color: palette.text,
          fontSize: 17,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: AppTypography.title.copyWith(
          color: palette.text,
          fontSize: 20,
        ),
        contentTextStyle: AppTypography.body.copyWith(
          color: palette.secondaryText,
          fontSize: 14,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: palette.surface,
        showDragHandle: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: isLight ? 0.06 : 0.2),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: palette.divider),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: palette.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          textStyle: AppTypography.button.copyWith(color: palette.onPrimary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: palette.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          textStyle: AppTypography.button.copyWith(color: palette.onPrimary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.primary,
          side: BorderSide(color: palette.divider),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          textStyle: AppTypography.button.copyWith(color: palette.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: AppTypography.button.copyWith(color: palette.primary),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        hintStyle: AppTypography.bodySecondary.copyWith(
          color: palette.secondaryText,
        ),
        labelStyle: AppTypography.caption.copyWith(
          color: palette.secondaryText,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.error, width: 2),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: palette.surface,
        textStyle: AppTypography.body.copyWith(color: palette.text),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.surfaceVariant,
        contentTextStyle: AppTypography.body.copyWith(color: palette.text),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: palette.primary,
        linearTrackColor: palette.surfaceVariant,
      ),
    );
  }
}
