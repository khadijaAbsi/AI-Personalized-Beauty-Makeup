import 'package:flutter/material.dart';

/// The five top-level destinations of the GlowAI bottom navigation bar.
///
/// The order matches the order of the items in the bar.
enum MainTab { home, explore, savedLooks, favorites, profile }

/// Holds which [MainTab] is visible and remembers where the user came from,
/// so Back is predictable:
///
/// * Selecting a tab never pushes a route; it only changes [current].
/// * Back returns to the tab the user came from (for example
///   Profile -> Favorites -> Back -> Profile).
/// * Home is the root: selecting Home clears the history, and Back on Home is
///   handed to the Navigator (leave the app / pop to the previous route).
class MainShellController extends ChangeNotifier {
  MainShellController({MainTab initial = MainTab.home}) : _current = initial;

  /// The shell that is currently on screen, if any. Screens that live above
  /// the shell (for example the AI processing screen) use it to hand the user
  /// back to the Home flow. Cleared when the shell is disposed.
  static MainShellController? active;

  /// Navigator of the Home tab. The recommendation flow (Face Analysis
  /// Results, Occasion, Recommended Looks and their details) is pushed here,
  /// so the bottom bar stays visible and the flow survives tab switches.
  final GlobalKey<NavigatorState> homeNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'home flow',
  );

  /// The route that hosts the shell, so screens above it can pop back to it.
  Route<dynamic>? shellRoute;

  bool _disposed = false;

  MainTab _current;
  final List<MainTab> _history = <MainTab>[];

  MainTab get current => _current;

  /// Tabs the user can go back to, oldest first. Exposed for tests.
  List<MainTab> get history => List<MainTab>.unmodifiable(_history);

  /// True when Back can be handled inside the shell.
  ///
  /// A shell opened directly on another tab (for example after
  /// `AppRouter.goToTab`) has no history, so Back falls back to Home.
  bool get canGoBack => _history.isNotEmpty || _current != MainTab.home;

  void select(MainTab tab) {
    if (tab == _current) return;
    if (tab == MainTab.home) {
      _history.clear();
    } else {
      _history
        ..remove(tab)
        ..add(_current);
    }
    _current = tab;
    notifyListeners();
  }

  NavigatorState? get homeNavigator => homeNavigatorKey.currentState;

  /// True while the Home tab is showing a screen of the flow rather than the
  /// Dashboard. Back then belongs to that flow.
  bool get homeFlowActive =>
      _current == MainTab.home && (homeNavigator?.canPop() ?? false);

  /// The Home navigator pushed or popped something. Deferred to after the
  /// frame because navigators report their first route while building.
  void homeStackChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_disposed) notifyListeners();
    });
  }

  /// Shows [routeName] in the Home flow with the bottom bar visible.
  ///
  /// Everything above the shell (photo capture, processing, ...) is closed
  /// first. The flow below the new screen is replaced, so the Dashboard is
  /// always its base.
  void openInHomeFlow(
    NavigatorState rootNavigator,
    String routeName, {
    Object? arguments,
  }) {
    final shell = shellRoute;
    rootNavigator.popUntil((route) => route == shell || route.isFirst);
    select(MainTab.home);
    homeNavigator?.pushNamedAndRemoveUntil(
      routeName,
      (route) => route.isFirst,
      arguments: arguments,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Handles Back inside the shell. Returns false when the shell is already at
  /// its root (Home with no history), so the caller can let the Navigator pop.
  bool back() {
    if (_history.isNotEmpty) {
      _current = _history.removeLast();
    } else if (_current != MainTab.home) {
      _current = MainTab.home;
    } else {
      return false;
    }
    notifyListeners();
    return true;
  }
}

/// What a screen should show for its leading Back button.
class ShellBackAction {
  const ShellBackAction({required this.visible, required this.onPressed});

  final bool visible;
  final VoidCallback onPressed;
}

/// Makes the [MainShellController] available to the tab screens.
///
/// Screens that are used both as a tab and as a normal pushed page read this
/// scope: when it is missing they behave exactly like a standalone page.
class MainShellScope extends InheritedNotifier<MainShellController> {
  const MainShellScope({
    super.key,
    required MainShellController controller,
    required super.child,
  }) : super(notifier: controller);

  /// The controller above [context], or null outside the shell.
  /// Rebuilds the caller when the shell changes.
  static MainShellController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<MainShellScope>()
        ?.notifier;
  }

  /// The controller above [context] without subscribing to changes.
  static MainShellController? peek(BuildContext context) {
    return context.getInheritedWidgetOfExactType<MainShellScope>()?.notifier;
  }

  /// Back button behaviour for a screen:
  ///
  /// * Outside the shell: always visible, pops the Navigator.
  /// * Inside the shell, going back through the tab history when there is
  ///   one (for example Profile -> Favorites -> Back -> Profile).
  /// * Inside a shell that was pushed on top of another route and has no tab
  ///   history, Back pops that route.
  /// * Otherwise (the shell is the first route) Back goes to Home, and is
  ///   hidden on Home itself.
  static ShellBackAction backActionOf(BuildContext context) {
    final controller = maybeOf(context);
    if (controller == null) {
      return ShellBackAction(
        visible: true,
        onPressed: () => Navigator.maybePop(context),
      );
    }

    if (controller.history.isNotEmpty) {
      return ShellBackAction(
        visible: true,
        onPressed: () {
          controller.back();
        },
      );
    }

    final canPopRoute = !(ModalRoute.of(context)?.isFirst ?? true);
    if (canPopRoute) {
      return ShellBackAction(
        visible: true,
        onPressed: () => Navigator.maybePop(context),
      );
    }

    return ShellBackAction(
      visible: controller.current != MainTab.home,
      onPressed: () {
        controller.back();
      },
    );
  }
}

/// Calls [onActivated] whenever [tab] becomes the visible tab again.
///
/// Tabs stay alive while hidden, so a screen uses this to refresh data that
/// may have changed elsewhere (for example Profile counts after the user
/// added a favorite). It does nothing outside the shell, and it does not fire
/// for the first time the tab is shown: the screen loads itself then.
class TabActivationListener extends StatefulWidget {
  const TabActivationListener({
    super.key,
    required this.tab,
    required this.onActivated,
    required this.child,
  });

  final MainTab tab;
  final VoidCallback onActivated;
  final Widget child;

  @override
  State<TabActivationListener> createState() => _TabActivationListenerState();
}

class _TabActivationListenerState extends State<TabActivationListener> {
  MainShellController? _controller;
  bool _wasActive = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = MainShellScope.peek(context);
    if (identical(next, _controller)) return;
    _controller?.removeListener(_onShellChanged);
    _controller = next;
    _wasActive = next?.current == widget.tab;
    next?.addListener(_onShellChanged);
  }

  void _onShellChanged() {
    final controller = _controller;
    if (controller == null) return;
    final isActive = controller.current == widget.tab;
    final becameActive = isActive && !_wasActive;
    _wasActive = isActive;
    if (becameActive && mounted) widget.onActivated();
  }

  @override
  void dispose() {
    _controller?.removeListener(_onShellChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
