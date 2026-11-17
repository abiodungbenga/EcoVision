import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:features_tour/features_tour.dart';

import 'app/app.dart';
import 'app/theme/app_colors.dart';
import 'app/theme/app_typography.dart';
import 'core/services/api_key_service.dart';
import 'core/services/vmodal_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final vmodalService = VModalService();
  final apiKeyService = ApiKeyService(vmodalService: vmodalService);
  await apiKeyService.initialize();
  FeaturesTour.setGlobalConfig(
    preferencePrefix: 'ecovision',
    preDialogConfig: PreDialogConfig(enabled: false),
    childConfig: ChildConfig(
      borderSizeInflate: 8,
      backgroundColor: Colors.white,
      animationDuration: Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    ),
    introduceConfig: IntroduceConfig(
      padding: const EdgeInsets.all(14),
      barrierColorBuilder: (_) => const Color(0xD91B241E),
      builder: (context, childRect, introduce) {
        final palette = AppPalette.of(context);
        return Material(
          color: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width - 40,
            ),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: palette.divider),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: introduce,
          ),
        );
      },
    ),
    skipConfig: SkipConfig(
      text: 'Skip',
      textStyle: AppTypography.caption.copyWith(
        color: AppColors.secondaryText,
        fontWeight: FontWeight.w600,
      ),
    ),
    nextConfig: NextConfig(
      text: 'Continue',
      color: Colors.white,
      textStyle: AppTypography.button.copyWith(color: Colors.white),
      buttonStyle: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    doneConfig: DoneConfig(
      text: 'Get started',
      color: Colors.white,
      textStyle: AppTypography.button.copyWith(color: Colors.white),
      buttonStyle: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
  final savedThemeMode = await AdaptiveTheme.getThemeMode();
  runApp(
    EcoVisionApp(
      initialThemeMode: savedThemeMode,
      apiKeyService: apiKeyService,
      vmodalService: vmodalService,
    ),
  );
}
