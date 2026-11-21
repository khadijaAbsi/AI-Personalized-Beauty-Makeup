import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// One destination of [GlowBottomNavBar].
class GlowNavDestination {
  const GlowNavDestination({
    required this.label,
    required this.tooltip,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final String tooltip;
  final IconData icon;
  final IconData activeIcon;
}

/// GlowAI's single bottom navigation bar.
///
/// It is purely presentational: the owner decides what a tap does. Pass a
/// null [currentIndex] on screens that belong to the bar's flow but are not
/// one of its destinations; no item is then highlighted.
class GlowBottomNavBar extends StatelessWidget {
  const GlowBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int? currentIndex;
  final ValueChanged<int> onTap;

  /// Order must match `MainTab`.
  static const List<GlowNavDestination> destinations = [
    GlowNavDestination(
      label: 'Home',
      tooltip: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
    ),
    GlowNavDestination(
      label: 'Explore',
      tooltip: 'Explore products',
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore,
    ),
    GlowNavDestination(
      label: 'Saved',
      tooltip: 'Saved Looks',
      icon: Icons.bookmark_border,
      activeIcon: Icons.bookmark,
    ),
    GlowNavDestination(
      label: 'Favorites',
      tooltip: 'Favorite products',
      icon: Icons.favorite_border,
      activeIcon: Icons.favorite,
    ),
    GlowNavDestination(
      label: 'Profile',
      tooltip: 'Profile',
      icon: Icons.person_outline,
      activeIcon: Icons.person,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final hasSelection = currentIndex != null;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex ?? 0,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.surface,
        elevation: 0,
        selectedItemColor: hasSelection
            ? AppColors.primary
            : AppColors.textHint,
        unselectedItemColor: AppColors.textHint,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        showUnselectedLabels: true,
        items: [
          for (final destination in destinations)
            BottomNavigationBarItem(
              icon: Icon(destination.icon),
              activeIcon: Icon(
                hasSelection ? destination.activeIcon : destination.icon,
              ),
              label: destination.label,
              tooltip: destination.tooltip,
            ),
        ],
      ),
    );
  }
}
