import 'package:flutter/material.dart';

class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.text,
    required this.secondaryText,
    required this.divider,
    required this.primary,
    required this.onPrimary,
    required this.accent,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
  });

  static const light = AppPalette(
    background: Color(0xFFF6F6F1),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF0F1EB),
    text: Color(0xFF202A24),
    secondaryText: Color(0xFF727A72),
    divider: Color(0xFFE2E4DC),
    primary: Color(0xFF234B3D),
    onPrimary: Colors.white,
    accent: Color(0xFFB88A5A),
    success: Color(0xFF63856C),
    warning: Color(0xFFB88A5A),
    error: Color(0xFFB54742),
    info: Color(0xFF55758A),
  );

  static const dark = AppPalette(
    background: Color(0xFF111713),
    surface: Color(0xFF19211B),
    surfaceVariant: Color(0xFF222C24),
    text: Color(0xFFEEF2EC),
    secondaryText: Color(0xFFA6B0A6),
    divider: Color(0xFF344036),
    primary: Color(0xFFA9C5AE),
    onPrimary: Color(0xFF14251A),
    accent: Color(0xFFD6AF7C),
    success: Color(0xFF9CC5A1),
    warning: Color(0xFFE2BD7D),
    error: Color(0xFFE2958B),
    info: Color(0xFF9BBBD0),
  );

  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color text;
  final Color secondaryText;
  final Color divider;
  final Color primary;
  final Color onPrimary;
  final Color accent;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;

  static AppPalette of(BuildContext context) =>
      Theme.of(context).extension<AppPalette>() ?? light;

  @override
  AppPalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? text,
    Color? secondaryText,
    Color? divider,
    Color? primary,
    Color? onPrimary,
    Color? accent,
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
  }) {
    return AppPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      text: text ?? this.text,
      secondaryText: secondaryText ?? this.secondaryText,
      divider: divider ?? this.divider,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      accent: accent ?? this.accent,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      text: Color.lerp(text, other.text, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      info: Color.lerp(info, other.info, t)!,
    );
  }
}

class AppColors {
  AppColors._();

  static const Color background = Color(0xFFF6F6F1);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color elevatedSurface = Color(0xFFF0F1EB);
  static const Color primary = Color(0xFF234B3D);
  static const Color text = Color(0xFF202A24);
  static const Color secondaryText = Color(0xFF727A72);
  static const Color divider = Color(0xFFE2E4DC);
  static const Color error = Color(0xFFB54742);
  static const Color success = Color(0xFF63856C);
  static const Color warning = Color(0xFFB88A5A);
}
