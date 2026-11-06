import 'package:flutter/material.dart';

import '../../features/history/screens/favorite_products_page.dart';
import '../../features/history/screens/saved_looks_screen.dart';
import '../../features/home/screens/home_tab.dart';
import '../../features/products/screens/recommended_products_page.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../shared/widgets/glow_bottom_nav_bar.dart';
import '../theme/app_colors.dart';
import 'main_shell_scope.dart';

/// Persistent shell for GlowAI's five main sections.
///
/// One bottom navigation bar, one [MainShellController]. Tabs are built the
/// first time they are opened and then kept alive, so switching tabs never
/// pushes routes and never reloads a screen the user already visited.
///
/// Detail and flow screens (product details, look details, settings, photo
/// capture and the AI processing flow) are pushed on the root Navigator on top
/// of the shell. They cover the bar on purpose: Back there is a normal
/// Navigator pop and always lands on the tab the user left.
class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    this.initialTab = MainTab.home,
    this.tabBuilders,
  });

  final MainTab initialTab;

  /// Replaces individual tab screens. Used by tests so they do not need a
  /// live Supabase session; production code leaves this null.
  final Map<MainTab, WidgetBuilder>? tabBuilders;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late final MainShellController _controller = MainShellController(
    initial: widget.initialTab,
  );
  late final Set<MainTab> _visited = {widget.initialTab};

  @override
  void initState() {
    super.initState();
    MainShellController.active = _controller;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.shellRoute = ModalRoute.of(context);
  }

  @override
  void dispose() {
    if (identical(MainShellController.active, _controller)) {
      MainShellController.active = null;
    }
    _controller.dispose();
    super.dispose();
  }

  Widget _buildTab(BuildContext context, MainTab tab) {
    final override = widget.tabBuilders?[tab];
    if (override != null) return override(context);

    switch (tab) {
      case MainTab.home:
        return const HomeTab();
      case MainTab.explore:
        return const RecommendedProductsPage();
      case MainTab.savedLooks:
        return const SavedLooksScreen();
      case MainTab.favorites:
        return const FavoriteProductsPage();
      case MainTab.profile:
        return const ProfileScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainShellScope(
      controller: _controller,
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          _visited.add(_controller.current);

          // The shell may be the first route (normal) or pushed on top of
          // another one. Back is ours while there is a tab to return to; it
          // is the Navigator's when the shell is at its root (Home) or has no
          // tab history and sits on top of another route.
          final isFirstRoute = ModalRoute.of(context)?.isFirst ?? true;
          final canLeaveShell =
              !_controller.homeFlowActive &&
              _controller.history.isEmpty &&
              (!isFirstRoute || _controller.current == MainTab.home);

          return PopScope(
            canPop: canLeaveShell,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;
              // A screen of the Home flow (results, looks, ...) goes first.
              if (_controller.homeFlowActive) {
                _controller.homeNavigator?.pop();
                return;
              }
              _controller.back();
            },
            child: Material(
              color: AppColors.background,
              child: Column(
                children: [
                  Expanded(
                    // The bar below already accounts for the bottom system
                    // inset; do not let each tab's SafeArea add it again.
                    child: MediaQuery.removePadding(
                      context: context,
                      removeBottom: true,
                      child: IndexedStack(
                        index: _controller.current.index,
                        children: [
                          for (final tab in MainTab.values)
                            _visited.contains(tab)
                                ? KeyedSubtree(
                                    key: ValueKey<MainTab>(tab),
                                    child: _buildTab(context, tab),
                                  )
                                : const SizedBox.shrink(),
                        ],
                      ),
                    ),
                  ),
                  GlowBottomNavBar(
                    currentIndex: _controller.current.index,
                    onTap: (index) {
                      final tab = MainTab.values[index];
                      if (tab == MainTab.home && _controller.homeFlowActive) {
                        // Tapping Home on a flow screen returns to the
                        // Dashboard.
                        _controller.homeNavigator?.popUntil(
                          (route) => route.isFirst,
                        );
                        return;
                      }
                      _controller.select(tab);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
