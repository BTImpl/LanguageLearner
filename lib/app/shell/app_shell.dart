import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:languagelearner/app/shell/app_bottom_nav.dart';
import 'package:languagelearner/i18n/context_i18n.dart';

/// The frame around the three tabs: the current tab and the bottom navigation.
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomNav(
        items: [
          AppNavItem(icon: Icons.school_outlined, label: i18n.navLearn),
          AppNavItem(icon: Icons.bar_chart, label: i18n.navStats),
          AppNavItem(icon: Icons.settings_outlined, label: i18n.navSettings),
        ],
        currentIndex: navigationShell.currentIndex,
        onSelected: (index) => navigationShell.goBranch(
          index,
          // Tapping the open tab goes back to its first screen.
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
