import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glowai/core/routing/main_shell.dart';
import 'package:glowai/core/routing/main_shell_scope.dart';
import 'package:glowai/core/theme/app_colors.dart';
import 'package:glowai/shared/widgets/glow_bottom_nav_bar.dart';

/// A stand-in tab that records how often it is built.
class _FakeTab extends StatefulWidget {
  const _FakeTab({required this.tab, required this.onInit});

  final MainTab tab;
  final void Function(MainTab tab) onInit;

  @override
  State<_FakeTab> createState() => _FakeTabState();
}

class _FakeTabState extends State<_FakeTab> {
  @override
  void initState() {
    super.initState();
    widget.onInit(widget.tab);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('tab-${widget.tab.name}')));
  }
}

Map<MainTab, WidgetBuilder> _fakeTabs(List<MainTab> built) => {
  for (final tab in MainTab.values)
    tab: (_) => _FakeTab(tab: tab, onInit: built.add),
};

Finder _barItem(String label) => find.descendant(
  of: find.byType(BottomNavigationBar),
  matching: find.text(label),
);

int _selectedIndex(WidgetTester tester) => tester
    .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
    .currentIndex;

Future<void> _tapBar(WidgetTester tester, String label) async {
  await tester.tap(_barItem(label));
  await tester.pumpAndSettle();
}

Future<List<MainTab>> _pumpShell(
  WidgetTester tester, {
  MainTab initialTab = MainTab.home,
}) async {
  final built = <MainTab>[];
  await tester.pumpWidget(
    MaterialApp(
      home: MainShell(initialTab: initialTab, tabBuilders: _fakeTabs(built)),
    ),
  );
  return built;
}

void main() {
  group('MainShellController', () {
    test('starts on the given tab', () {
      expect(MainShellController().current, MainTab.home);
      expect(
        MainShellController(initial: MainTab.profile).current,
        MainTab.profile,
      );
    });

    test('Back returns to the tab the user came from', () {
      final controller = MainShellController()
        ..select(MainTab.profile)
        ..select(MainTab.favorites);

      expect(controller.back(), isTrue);
      expect(controller.current, MainTab.profile);
      expect(controller.back(), isTrue);
      expect(controller.current, MainTab.home);
      expect(controller.back(), isFalse); // Home is the root
      expect(controller.current, MainTab.home);
    });

    test('selecting Home clears the history', () {
      final controller = MainShellController()
        ..select(MainTab.explore)
        ..select(MainTab.favorites)
        ..select(MainTab.home);

      expect(controller.history, isEmpty);
      expect(controller.back(), isFalse);
    });

    test('revisiting a tab does not grow the history with duplicates', () {
      final controller = MainShellController()
        ..select(MainTab.explore)
        ..select(MainTab.favorites)
        ..select(MainTab.explore)
        ..select(MainTab.favorites);

      expect(controller.history.toSet().length, controller.history.length);
      expect(controller.history, isNot(contains(MainTab.favorites)));
    });

    test('selecting the current tab does nothing', () {
      var notifications = 0;
      final controller = MainShellController()
        ..addListener(() => notifications++);

      controller.select(MainTab.home);

      expect(notifications, 0);
      expect(controller.history, isEmpty);
    });

    test('a shell opened on another tab goes Back to Home', () {
      final controller = MainShellController(initial: MainTab.favorites);

      expect(controller.canGoBack, isTrue);
      expect(controller.back(), isTrue);
      expect(controller.current, MainTab.home);
      expect(controller.canGoBack, isFalse);
    });
  });

  group('MainShell', () {
    testWidgets('shows one bar with the five destinations', (tester) async {
      await _pumpShell(tester);

      expect(find.byType(BottomNavigationBar), findsOneWidget);
      for (final label in [
        'Home',
        'Explore',
        'Saved',
        'Favorites',
        'Profile',
      ]) {
        expect(_barItem(label), findsOneWidget, reason: label);
      }
      expect(find.byTooltip('Saved Looks'), findsOneWidget);
    });

    testWidgets('highlights the active destination', (tester) async {
      await _pumpShell(tester);
      expect(_selectedIndex(tester), MainTab.home.index);
      expect(find.byIcon(Icons.home), findsOneWidget);

      await _tapBar(tester, 'Explore');
      expect(_selectedIndex(tester), MainTab.explore.index);
      expect(find.text('tab-explore'), findsOneWidget);
      expect(find.byIcon(Icons.explore), findsOneWidget);
      expect(find.byIcon(Icons.home), findsNothing);
    });

    testWidgets('opens on the requested tab', (tester) async {
      await _pumpShell(tester, initialTab: MainTab.favorites);

      expect(_selectedIndex(tester), MainTab.favorites.index);
      expect(find.text('tab-favorites'), findsOneWidget);
      expect(find.text('tab-home'), findsNothing);
    });

    testWidgets('switching tabs never pushes a route', (tester) async {
      await _pumpShell(tester);
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));

      for (final label in [
        'Explore',
        'Saved',
        'Favorites',
        'Profile',
        'Home',
      ]) {
        await _tapBar(tester, label);
        expect(navigator.canPop(), isFalse, reason: label);
        expect(find.byType(BottomNavigationBar), findsOneWidget);
      }
    });

    testWidgets('builds a tab only when first opened and then keeps it', (
      tester,
    ) async {
      final built = await _pumpShell(tester);
      expect(built, [MainTab.home]);

      await _tapBar(tester, 'Explore');
      expect(built, [MainTab.home, MainTab.explore]);

      await _tapBar(tester, 'Home');
      await _tapBar(tester, 'Explore');
      expect(built, [MainTab.home, MainTab.explore]);
    });

    testWidgets('system Back walks back through tabs, then leaves the shell', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => MainShell(tabBuilders: _fakeTabs([])),
                  ),
                ),
                child: const Text('open shell'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open shell'));
      await tester.pumpAndSettle();

      await _tapBar(tester, 'Profile');
      await _tapBar(tester, 'Favorites');
      expect(_selectedIndex(tester), MainTab.favorites.index);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(_selectedIndex(tester), MainTab.profile.index);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(_selectedIndex(tester), MainTab.home.index);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(MainShell), findsNothing);
      expect(find.text('open shell'), findsOneWidget);
    });

    testWidgets('a shell opened on another tab goes Back to Home first', (
      tester,
    ) async {
      await _pumpShell(tester, initialTab: MainTab.favorites);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(_selectedIndex(tester), MainTab.home.index);
      expect(find.text('tab-home'), findsOneWidget);
    });

    testWidgets(
      'screens above the shell cover the bar; Back returns to the tab',
      (tester) async {
        final tabs = _fakeTabs([])
          ..[MainTab.explore] = (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        const Scaffold(body: Text('product details')),
                  ),
                ),
                child: const Text('open details'),
              ),
            ),
          );
        await tester.pumpWidget(
          MaterialApp(
            home: MainShell(initialTab: MainTab.explore, tabBuilders: tabs),
          ),
        );

        await tester.tap(find.text('open details'));
        await tester.pumpAndSettle();

        expect(find.text('product details'), findsOneWidget);
        expect(find.byType(BottomNavigationBar), findsNothing);

        tester.state<NavigatorState>(find.byType(Navigator)).pop();
        await tester.pumpAndSettle();

        expect(find.byType(BottomNavigationBar), findsOneWidget);
        expect(_selectedIndex(tester), MainTab.explore.index);
        expect(find.text('open details'), findsOneWidget);
      },
    );
  });

  group('shell back button', () {
    Widget backButtonTab(BuildContext context) {
      final back = MainShellScope.backActionOf(context);
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: back.visible
              ? IconButton(
                  tooltip: 'Back',
                  onPressed: back.onPressed,
                  icon: const Icon(Icons.arrow_back),
                )
              : null,
        ),
        body: const SizedBox(),
      );
    }

    Map<MainTab, WidgetBuilder> tabs() => {
      for (final tab in MainTab.values)
        tab: (context) => Builder(builder: backButtonTab),
    };

    testWidgets('is hidden on Home and shown after switching tabs', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: MainShell(tabBuilders: tabs())),
      );
      expect(find.byTooltip('Back'), findsNothing);

      await _tapBar(tester, 'Profile');
      await _tapBar(tester, 'Favorites');
      expect(find.byTooltip('Back'), findsOneWidget);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(_selectedIndex(tester), MainTab.profile.index);
    });

    testWidgets('pops the route when the shell sits on top of another screen', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => MainShell(
                      initialTab: MainTab.favorites,
                      tabBuilders: tabs(),
                    ),
                  ),
                ),
                child: const Text('base screen'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('base screen'));
      await tester.pumpAndSettle();
      expect(_selectedIndex(tester), MainTab.favorites.index);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(find.byType(MainShell), findsNothing);
      expect(find.text('base screen'), findsOneWidget);
    });
  });

  group('TabActivationListener', () {
    testWidgets('fires when a tab is shown again, not the first time', (
      tester,
    ) async {
      var activations = 0;
      final tabs = _fakeTabs([])
        ..[MainTab.profile] = (_) => TabActivationListener(
          tab: MainTab.profile,
          onActivated: () => activations++,
          child: const Scaffold(body: Text('tab-profile')),
        );
      await tester.pumpWidget(MaterialApp(home: MainShell(tabBuilders: tabs)));

      await _tapBar(tester, 'Profile'); // first time: the screen loads itself
      expect(activations, 0);

      await _tapBar(tester, 'Home');
      await _tapBar(tester, 'Profile');
      expect(activations, 1);

      await _tapBar(tester, 'Explore');
      await _tapBar(tester, 'Profile');
      expect(activations, 2);
    });

    testWidgets('does nothing outside the shell', (tester) async {
      var activations = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: TabActivationListener(
            tab: MainTab.profile,
            onActivated: () => activations++,
            child: const Text('standalone'),
          ),
        ),
      );

      expect(find.text('standalone'), findsOneWidget);
      expect(activations, 0);
    });
  });

  group('GlowBottomNavBar', () {
    Future<void> pumpBar(
      WidgetTester tester, {
      required int? index,
      ValueChanged<int>? onTap,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: GlowBottomNavBar(
              currentIndex: index,
              onTap: onTap ?? (_) {},
            ),
          ),
        ),
      );
    }

    testWidgets('reports the tapped destination', (tester) async {
      int? tapped;
      await pumpBar(tester, index: 0, onTap: (i) => tapped = i);

      await tester.tap(find.text('Profile'));

      expect(tapped, MainTab.profile.index);
    });

    testWidgets('highlights nothing when there is no current destination', (
      tester,
    ) async {
      await pumpBar(tester, index: null);

      expect(find.byIcon(Icons.home), findsNothing);
      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
      final bar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bar.selectedItemColor, AppColors.textHint);
    });

    testWidgets('fits the narrowest phones', (tester) async {
      tester.view.devicePixelRatio = 3.0;
      tester.view.physicalSize = const Size(320, 480) * 3.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.0)),
            child: child!,
          ),
          home: Scaffold(
            bottomNavigationBar: GlowBottomNavBar(
              currentIndex: 2,
              onTap: (_) {},
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
