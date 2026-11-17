import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/app_logo.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _entrance;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _entrance = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
    _navigationTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) Get.offNamed(AppRoutes.home);
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Scaffold(
      backgroundColor: palette.background,
      body: Stack(
        children: [
          Positioned(
            top: -150,
            right: -120,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.primary.withValues(alpha: 0.035),
              ),
            ),
          ),
          Positioned(
            bottom: -180,
            left: -120,
            child: Container(
              width: 420,
              height: 420,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.accent.withValues(alpha: 0.045),
              ),
            ),
          ),
          Center(
            child: AnimatedBuilder(
              animation: _entrance,
              builder: (context, child) => Opacity(
                opacity: _entrance.value,
                child: Transform.translate(
                  offset: Offset(0, 14 * (1 - _entrance.value)),
                  child: Transform.scale(
                    scale: 0.94 + (0.06 * _entrance.value),
                    child: child,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppLogo(showWordmark: true, width: 228),
                  const SizedBox(height: 17),
                  Text(
                    'FIELD NOTES, FOUND',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: palette.secondaryText,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 48,
            right: 48,
            bottom: MediaQuery.paddingOf(context).bottom + 32,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 1900),
              curve: Curves.easeInOut,
              builder: (context, progress, child) => ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 2,
                  backgroundColor: palette.divider,
                  valueColor: AlwaysStoppedAnimation<Color>(palette.primary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
