import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';

class AppBottomNavigationBar extends StatelessWidget {
  const AppBottomNavigationBar({super.key, required this.selectedIndex});

  final int selectedIndex;

  static const _routes = [
    AppRoutes.home,
    AppRoutes.upload,
    AppRoutes.search,
    AppRoutes.dashboard,
  ];

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).colorScheme;
    return NavigationBar(
      selectedIndex: selectedIndex,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      indicatorColor: palette.primary.withValues(alpha: 0.14),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      onDestinationSelected: (index) {
        if (index == selectedIndex) return;
        Get.offNamed(_routes[index]);
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.video_library_outlined),
          selectedIcon: Icon(Icons.video_library_rounded),
          label: 'Upload',
        ),
        NavigationDestination(
          icon: Icon(Icons.search_rounded),
          label: 'Search',
        ),
        NavigationDestination(
          icon: Icon(Icons.insights_outlined),
          selectedIcon: Icon(Icons.insights_rounded),
          label: 'Research',
        ),
      ],
    );
  }
}
