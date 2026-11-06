import 'package:flutter/material.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/routing/main_shell_scope.dart';
import 'home_dashboard.dart';

/// The Home tab: the Dashboard plus the recommendation flow that starts from
/// it (Face Analysis Results, Occasion, Recommended Looks and their details).
///
/// The flow has its own [Navigator], so it is drawn above the Dashboard but
/// below the shell's bottom bar. The bar stays visible, and because the tab
/// is kept alive the user can visit another tab and come back to the same
/// screen. Photo capture and AI processing are opened on the root navigator
/// instead, so they cover the bar.
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  MainShellController? _shell;
  late final _FlowObserver _observer = _FlowObserver(
    () => _shell?.homeStackChanged(),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _shell = MainShellScope.peek(context);
  }

  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    if (settings.name == Navigator.defaultRouteName) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const HomeDashboard(),
      );
    }
    // Flow screens (occasion, looks, results, product list, ...) use the same
    // route table as the rest of the app.
    return AppRouter.onGenerateRoute(settings);
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: _shell?.homeNavigatorKey,
      observers: [_observer],
      onGenerateRoute: _onGenerateRoute,
    );
  }
}

/// Tells the shell when the Home flow changes, so Android Back knows whether
/// the flow or the shell should handle it.
class _FlowObserver extends NavigatorObserver {
  _FlowObserver(this._onChanged);

  final VoidCallback _onChanged;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _onChanged();

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _onChanged();

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _onChanged();

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _onChanged();
}
