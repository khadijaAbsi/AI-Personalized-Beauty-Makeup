import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glowai/core/routing/app_router.dart';
import 'package:glowai/core/routing/main_shell.dart';
import 'package:glowai/core/routing/main_shell_scope.dart';
import 'package:glowai/features/favorites/services/favorites_service.dart';
import 'package:glowai/features/history/screens/favorite_products_page.dart';
import 'package:glowai/features/products/models/product.dart';
import 'package:glowai/features/products/screens/recommended_products_page.dart';
import 'package:glowai/features/products/services/product_catalog_service.dart';
import 'package:glowai/features/profile/screens/profile_screen.dart';
import 'package:glowai/features/profile/services/mock_user_profile.dart';

import 'helpers/fake_favorites_repository.dart';
import 'helpers/profile_test_helpers.dart';

const _lipstick = Product(
  id: 'lipstick',
  name: 'Soft Matte Lipstick',
  brand: 'Glow Beauty',
  category: 'Lips',
  description: 'A creamy matte lipstick.',
  color: Color(0xFFD9909C),
  shade: 'Rosewood',
  price: 24.99,
);

class _Catalog implements ProductCatalogService {
  const _Catalog();

  @override
  Future<List<Product>> loadProducts() async => const [_lipstick];
}

Finder _barItem(String label) => find.descendant(
  of: find.byType(BottomNavigationBar),
  matching: find.text(label),
);

Future<void> _tapBar(WidgetTester tester, String label) async {
  await tester.tap(_barItem(label));
  await tester.pumpAndSettle();
}

void main() {
  late FakeFavoritesRepository repo;

  setUp(() {
    repo = FakeFavoritesRepository();
    FavoritesService.instance.debugUseRepository(repo);
  });

  tearDown(FavoritesService.instance.debugReset);

  void useScreen(WidgetTester tester) {
    tester.view.devicePixelRatio = 3.0;
    tester.view.physicalSize = const Size(390, 844) * 3.0;
    addTearDown(tester.view.reset);
  }

  Map<MainTab, WidgetBuilder> tabs({FakeProfileService? profile}) => {
    MainTab.home: (_) => const SizedBox(),
    MainTab.explore: (_) =>
        const RecommendedProductsPage(catalogService: _Catalog()),
    MainTab.savedLooks: (_) => const SizedBox(),
    MainTab.favorites: (_) => const FavoriteProductsPage(),
    MainTab.profile: (_) =>
        ProfileScreen(profileService: profile ?? FakeProfileService()),
  };

  testWidgets('a favorite added in Explore shows in Favorites and can be '
      'removed there, and Explore follows', (tester) async {
    useScreen(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: MainShell(initialTab: MainTab.explore, tabBuilders: tabs()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('favorite-button-lipstick')));
    await tester.pumpAndSettle();
    expect(repo.rowsOf('user-1'), hasLength(1));

    await _tapBar(tester, 'Favorites');
    expect(find.text('My Favorites'), findsOneWidget);
    expect(find.text('Soft Matte Lipstick'), findsOneWidget);
    expect(find.text('Rosewood'), findsOneWidget);
    expect(find.text('1 products saved for you'), findsOneWidget);

    await tester.tap(
      find.byKey(
        const ValueKey('remove-favorite-glow beauty::soft matte lipstick'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No favorites yet'), findsOneWidget);
    expect(repo.rowsOf('user-1'), isEmpty);

    await _tapBar(tester, 'Explore');
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('favorite-button-lipstick')),
        matching: find.byIcon(Icons.favorite_border),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Favorites opened from Profile: Back returns to Profile and '
      'Profile refreshes', (tester) async {
    useScreen(tester);
    final profile = FakeProfileService();
    await tester.pumpWidget(
      MaterialApp(
        home: MainShell(
          initialTab: MainTab.profile,
          tabBuilders: tabs(profile: profile),
        ),
      ),
    );
    profile.complete(mockUserProfile);
    await tester.pump();
    await tester.pump();
    expect(find.text('Layla'), findsOneWidget);
    expect(profile.loadCalls, 1);

    final favoritesCard = find.text('Favorite products');
    await tester.ensureVisible(favoritesCard);
    await tester.pump();
    await tester.tap(favoritesCard);
    await tester.pumpAndSettle();

    expect(find.text('My Favorites'), findsOneWidget);
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    expect(navigator.canPop(), isFalse); // a tab switch, not a pushed route

    await tester.tap(find.byTooltip('Back'));
    await tester.pump();
    await tester.pump();

    // Profile is visible again and reloads its counts.
    expect(profile.loadCalls, 2);
    profile.complete(mockUserProfile);
    await tester.pumpAndSettle();
    expect(find.text('Layla'), findsOneWidget);
    expect(find.text('My Favorites'), findsNothing);
  });

  testWidgets('Android Back on Favorites returns to Profile', (tester) async {
    useScreen(tester);
    final profile = FakeProfileService();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => MainShell(
                    initialTab: MainTab.profile,
                    tabBuilders: tabs(profile: profile),
                  ),
                ),
              ),
              child: const Text('start'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('start'));
    await tester.pump();
    profile.complete(mockUserProfile);
    await tester.pumpAndSettle();

    final card = find.text('Favorite products');
    await tester.ensureVisible(card);
    await tester.pump();
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(find.text('My Favorites'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump();

    expect(find.text('My Favorites'), findsNothing);
    expect(find.byType(MainShell), findsOneWidget);
    expect(profile.loadCalls, 2);
  });

  testWidgets('Favorites route pushed over another screen: Back returns '
      'there', (tester) async {
    useScreen(tester);
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) {
          if (settings.name == AppRouter.favoriteProducts) {
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) =>
                  MainShell(initialTab: MainTab.favorites, tabBuilders: tabs()),
            );
          }
          return null;
        },
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRouter.favoriteProducts),
              child: const Text('previous screen'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('previous screen'));
    await tester.pumpAndSettle();
    expect(find.text('My Favorites'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('previous screen'), findsOneWidget);
    expect(find.text('My Favorites'), findsNothing);
  });

  testWidgets('standalone Favorites has a Back button that pops', (
    tester,
  ) async {
    useScreen(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const FavoriteProductsPage(),
                ),
              ),
              child: const Text('previous screen'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('previous screen'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('previous screen'), findsOneWidget);
  });
}
