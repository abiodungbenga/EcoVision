import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart' as adaptive_ui;

import 'bindings/initial_binding.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';

class EcoVisionApp extends StatelessWidget {
  const EcoVisionApp({super.key, this.initialThemeMode});

  final AdaptiveThemeMode? initialThemeMode;

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
            initialBinding: InitialBinding(),
            initialRoute: AppRoutes.splash,
            getPages: AppPages.routes,
          );
        },
      ),
    );
  }
}
