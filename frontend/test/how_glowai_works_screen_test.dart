import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glowai/core/routing/app_router.dart';
import 'package:glowai/core/theme/app_colors.dart';
import 'package:glowai/features/home/screens/home_dashboard.dart';
import 'package:glowai/features/home/screens/how_glowai_works_screen.dart';

const _stages = [
  ('Upload', 'Your portrait is received.'),
  ('Face Detection', 'Finds face and landmarks.'),
  ('Attribute Estimation', 'Estimates face shape and skin tone.'),
  ('Look Matching', 'Ranks reference looks.'),
  ('Virtual Try-On', 'Renders the look on your photo.'),
];

Future<void> _pumpScreen(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double textScale = 1.0,
}) async {
  tester.view.devicePixelRatio = 3.0;
  tester.view.physicalSize = size * 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: const HowGlowAiWorksScreen(),
    ),
  );
}

void main() {
  testWidgets('shows the exact heading and subheading', (tester) async {
    await _pumpScreen(tester);

    expect(find.text('How GlowAI works'), findsOneWidget);
    expect(
      find.text('Five AI stages turn your photo into a try-on.'),
      findsOneWidget,
    );
  });

  testWidgets('shows the five stages in order with the exact copy', (
    tester,
  ) async {
    await _pumpScreen(tester);

    var previousTop = -1.0;
    for (var i = 0; i < _stages.length; i++) {
      final (title, description) = _stages[i];
      final card = find.byKey(ValueKey('how-it-works-stage-${i + 1}'));

      expect(card, findsOneWidget);
      expect(
        find.descendant(of: card, matching: find.text('${i + 1}')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.text(title)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.text(description)),
        findsOneWidget,
      );

      final top = tester.getTopLeft(card).dy;
      expect(top, greaterThan(previousTop));
      previousTop = top;
    }
    expect(find.byKey(const ValueKey('how-it-works-stage-6')), findsNothing);
  });

  testWidgets('uses cream background, light-pink cards, plum number badges', (
    tester,
  ) async {
    await _pumpScreen(tester);

    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      AppColors.background,
    );

    final card = find.byKey(const ValueKey('how-it-works-stage-1'));
    final cardDecoration =
        tester.widget<Container>(card).decoration! as BoxDecoration;
    expect(cardDecoration.color, AppColors.blush);

    final badge = find.descendant(
      of: card,
      matching: find.byWidgetPredicate((w) {
        if (w is! Container) return false;
        final d = w.decoration;
        return d is BoxDecoration &&
            d.shape == BoxShape.circle &&
            d.color == AppColors.primary;
      }),
    );
    expect(badge, findsOneWidget);
  });

  testWidgets('Back returns to the previous screen', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const HowGlowAiWorksScreen(),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.byType(HowGlowAiWorksScreen), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('scrolls to the last stage on a small screen with large text', (
    tester,
  ) async {
    await _pumpScreen(tester, size: const Size(320, 480), textScale: 2.0);

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const ValueKey('how-it-works-stage-5')),
    );
    await tester.pump();

    expect(find.text('Virtual Try-On'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('has no overflow on wide screens', (tester) async {
    await _pumpScreen(tester, size: const Size(900, 700));

    expect(tester.takeException(), isNull);
    final card = tester.getSize(
      find.byKey(const ValueKey('how-it-works-stage-1')),
    );
    expect(card.width, lessThanOrEqualTo(640));
  });

  group('from the Dashboard', () {
    Future<void> pumpDashboard(WidgetTester tester) async {
      tester.view.devicePixelRatio = 3.0;
      tester.view.physicalSize = const Size(390, 844) * 3.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: const HomeDashboard(),
        ),
      );
      await tester.pump();
    }

    testWidgets('a clear card opens the screen and Back returns', (
      tester,
    ) async {
      await pumpDashboard(tester);

      final card = find.byKey(const ValueKey('how-it-works-card'));
      expect(card, findsOneWidget);
      expect(find.text('How GlowAI works'), findsOneWidget);

      await tester.tap(card);
      await tester.pumpAndSettle();
      expect(find.byType(HowGlowAiWorksScreen), findsOneWidget);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.byType(HowGlowAiWorksScreen), findsNothing);
      expect(find.byType(HomeDashboard), findsOneWidget);
    });

    testWidgets('the Dashboard no longer draws its own bottom bar', (
      tester,
    ) async {
      await pumpDashboard(tester);

      expect(find.byType(BottomNavigationBar), findsNothing);
    });
  });
}
