import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart' as adaptive_ui;
import 'package:network_internet_checker/network_internet_checker.dart';

import 'bindings/initial_binding.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import '../core/services/api_key_service.dart';
import '../core/services/vmodal_service.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

class EcoVisionApp extends StatelessWidget {
  const EcoVisionApp({
    super.key,
    this.initialThemeMode,
    this.internetChecker,
    this.apiKeyService,
    this.vmodalService,
  });

  final AdaptiveThemeMode? initialThemeMode;
  final InternetChecker? internetChecker;
  final ApiKeyService? apiKeyService;
  final VModalService? vmodalService;

  @override
  Widget build(BuildContext context) {
    return AdaptiveTheme(
      light: adaptive_ui.ThemeData.light(),
      dark: adaptive_ui.ThemeData.dark(),
      initial: initialThemeMode ?? AdaptiveThemeMode.system,
      builder: (_, _) => Builder(
        builder: (context) {
          // adaptive_theme 3.8 uses material_ui ThemeData; GetX uses Flutter's.
          final mode = AdaptiveTheme.of(context).mode;
          final themeMode = mode.isSystem
              ? ThemeMode.system
              : mode.isLight
              ? ThemeMode.light
              : ThemeMode.dark;
          return GetMaterialApp(
            title: 'EcoVision',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            builder: (context, child) {
              final palette = AppPalette.of(context);
              return _ConnectivityBanner(
                checker: internetChecker ?? InternetChecker.instance,
                offlineColor: palette.error,
                onlineColor: palette.success,
                child: child ?? const SizedBox.shrink(),
              );
            },
            initialBinding: InitialBinding(
              internetChecker: internetChecker,
              apiKeyService: apiKeyService,
              vmodalService: vmodalService,
            ),
            initialRoute: AppRoutes.splash,
            getPages: AppPages.routes,
          );
        },
      ),
    );
  }
}

class _ConnectivityBanner extends StatefulWidget {
  const _ConnectivityBanner({
    required this.checker,
    required this.offlineColor,
    required this.onlineColor,
    required this.child,
  });

  final InternetChecker checker;
  final Color offlineColor;
  final Color onlineColor;
  final Widget child;

  @override
  State<_ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<_ConnectivityBanner> {
  bool _hasBeenOffline = false;

  void _onStatusChanged(InternetStatus status) {
    if (status == InternetStatus.disconnected && !_hasBeenOffline) {
      setState(() => _hasBeenOffline = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OfflineBanner(
      checker: widget.checker,
      offlineColor: widget.offlineColor,
      onlineColor: widget.onlineColor,
      offlineMessage: const Text('No internet connection'),
      onlineMessage: const Text('Connection restored'),
      onlineMessageDuration: _hasBeenOffline
          ? const Duration(seconds: 2)
          : Duration.zero,
      onStatusChanged: _onStatusChanged,
      child: widget.child,
    );
  }
}
