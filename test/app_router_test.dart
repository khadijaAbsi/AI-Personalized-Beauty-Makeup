import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glowai/core/routing/app_router.dart';
import 'package:glowai/core/routing/main_shell.dart';
import 'package:glowai/core/routing/main_shell_scope.dart';
import 'package:glowai/features/home/screens/how_glowai_works_screen.dart';
import 'package:glowai/features/products/screens/recommended_products_page.dart';

void main() {
  late BuildContext context;

  Future<Widget> pageFor(WidgetTester tester, String name) async {
    await tester.pumpWidget(
      Builder(
        builder: (c) {
          context = c;
          return const SizedBox();
        },
      ),
    );
    final route = AppRouter.onGenerateRoute(
      RouteSettings(name: name),
    ) as MaterialPageRoute<void>;
    return route.builder(context);
  }

  const tabRoutes = {
    AppRouter.home: MainTab.home,
    AppRouter.explore: MainTab.explore,
    AppRouter.savedLooks: MainTab.savedLooks,
    AppRouter.favoriteProducts: MainTab.favorites,
    AppRouter.profile: MainTab.profile,
  };

  for (final entry in tabRoutes.entries) {
    testWidgets('${entry.key} opens the shell on ${entry.value.name}', (
      tester,
    ) async {
      final page = await pageFor(tester, entry.key);

      expect(page, isA<MainShell>());
      expect((page as MainShell).initialTab, entry.value);
    });
  }

  testWidgets('an unknown route opens the shell on Home', (tester) async {
    final page = await pageFor(tester, '/does-not-exist');

    expect(page, isA<MainShell>());
    expect((page as MainShell).initialTab, MainTab.home);
  });

  testWidgets('routeForTab and the tab routes agree', (tester) async {
    for (final entry in tabRoutes.entries) {
      expect(AppRouter.routeForTab(entry.value), entry.key);
    }
  });

  testWidgets('How GlowAI works has its own route', (tester) async {
    final page = await pageFor(tester, AppRouter.howItWorks);

    expect(page, isA<HowGlowAiWorksScreen>());
  });

  testWidgets('the standalone product list keeps its route', (tester) async {
    final page = await pageFor(tester, AppRouter.recommendedProducts);

    expect(page, isA<RecommendedProductsPage>());
  });
}
