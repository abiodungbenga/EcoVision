import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme/app_colors.dart';

class SnackbarUtils {
  static void showSuccess(String message, {String title = 'Success'}) {
    _show(
      title: title,
      message: message,
      icon: Icons.check_circle_outline_rounded,
      accent: (palette) => palette.success,
    );
  }

  static void showError(String message, {String title = 'Error'}) {
    _show(
      title: title,
      message: message,
      icon: Icons.error_outline_rounded,
      accent: (palette) => palette.error,
    );
  }

  static void showInfo(String message, {String title = 'Info'}) {
    _show(
      title: title,
      message: message,
      icon: Icons.info_outline_rounded,
      accent: (palette) => palette.info,
    );
  }

  static void _show({
    required String title,
    required String message,
    required IconData icon,
    required Color Function(AppPalette) accent,
  }) {
    final context = Get.context;
    if (context == null) {
      throw StateError('Cannot show a snackbar before the app is mounted.');
    }

    final palette = AppPalette.of(context);
    final accentColor = accent(palette);
    Get.snackbar(
      title,
      message,
      titleText: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall
            ?.copyWith(color: palette.text, fontWeight: FontWeight.w700),
      ),
      messageText: Text(
        message,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: palette.secondaryText, height: 1.4),
      ),
      icon: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: accentColor, size: 21),
      ),
      shouldIconPulse: false,
      snackPosition: SnackPosition.BOTTOM,
      snackStyle: SnackStyle.FLOATING,
      backgroundColor: palette.surface,
      colorText: palette.text,
      borderRadius: 16,
      borderColor: palette.divider,
      borderWidth: 0.8,
      leftBarIndicatorColor: accentColor,
      boxShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      maxWidth: 520,
      duration: const Duration(seconds: 4),
      animationDuration: const Duration(milliseconds: 280),
      forwardAnimationCurve: Curves.easeOutCubic,
      reverseAnimationCurve: Curves.easeInCubic,
      barBlur: 0,
      isDismissible: true,
    );
  }
}
