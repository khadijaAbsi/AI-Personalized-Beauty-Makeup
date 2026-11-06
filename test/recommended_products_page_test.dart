import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glowai/features/favorites/services/favorites_service.dart';
import 'package:glowai/features/products/models/product.dart';
import 'package:glowai/features/products/screens/product_details_page.dart';
import 'package:glowai/features/products/screens/recommended_products_page.dart';
import 'package:glowai/features/products/services/product_catalog_service.dart';

import 'helpers/fake_favorites_repository.dart';

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
const _blush = Product(
  id: 'blush',
  name: 'Rose Blush',
  brand: 'Blush Studio',
  category: 'Cheeks',
  description: 'A soft rose blush.',
  color: Color(0xFFF0A9A8),
  shade: 'Petal Rose',
  price: 18.5,
);
const _liner = Product(
  id: 'liner',
  name: 'Gel Eyeliner',
  brand: 'Lash & Co.',
  category: 'Eyes',
  description: 'A smooth gel liner.',
  color: Color(0xFF6E3F5A),
);

class _FakeCatalog implements ProductCatalogService {
  _FakeCatalog(this._load);

  final Future<List<Product>> Function() _load;
  int calls = 0;

  @override
  Future<List<Product>> loadProducts() {
    calls++;
    return _load();
  }
}

_FakeCatalog _catalogOf(List<Product> products) =>
    _FakeCatalog(() async => products);

Finder _heart(Product p) => find.byKey(ValueKey('favorite-button-${p.id}'));
Finder _card(Product p) => find.byKey(ValueKey('product-card-${p.id}'));

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

Future<void> _pumpPage(
  WidgetTester tester,
  ProductCatalogService catalog,
) async {
  tester.view.devicePixelRatio = 3.0;
  tester.view.physicalSize = const Size(390, 844) * 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(home: RecommendedProductsPage(catalogService: catalog)),
  );
  await _settle(tester);
}

void main() {
  late FakeFavoritesRepository repo;

  setUp(() {
    repo = FakeFavoritesRepository();
    FavoritesService.instance.debugUseRepository(repo);
  });

  tearDown(FavoritesService.instance.debugReset);

  testWidgets('shows a spinner while loading, then the products', (
    tester,
  ) async {
    final completer = Completer<List<Product>>();
    tester.view.devicePixelRatio = 3.0;
    tester.view.physicalSize = const Size(390, 844) * 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: RecommendedProductsPage(
          catalogService: _FakeCatalog(() => completer.future),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(_card(_lipstick), findsNothing);

    completer.complete([_lipstick, _blush]);
    await _settle(tester);

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(_card(_lipstick), findsOneWidget);
    expect(_card(_blush), findsOneWidget);
  });

  testWidgets('shows name, brand, category, shade and price', (tester) async {
    await _pumpPage(tester, _catalogOf([_lipstick]));

    expect(find.text('Soft Matte Lipstick'), findsOneWidget);
    expect(find.text('Glow Beauty'), findsOneWidget);
    expect(find.text('Rosewood'), findsOneWidget);
    expect(find.text('\$24.99'), findsOneWidget);
    // "Lips" is on the filter chip and on the card.
    expect(find.text('Lips'), findsNWidgets(2));
  });

  testWidgets('a product without a price shows none', (tester) async {
    await _pumpPage(tester, _catalogOf([_liner]));

    expect(find.text('Gel Eyeliner'), findsOneWidget);
    expect(find.textContaining('\$'), findsNothing);
  });

  testWidgets('category chips filter the list', (tester) async {
    await _pumpPage(tester, _catalogOf([_lipstick, _blush, _liner]));
    expect(find.text('3 products'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Lips'));
    await tester.pump();

    expect(find.text('1 product'), findsOneWidget);
    expect(_card(_lipstick), findsOneWidget);
    expect(_card(_blush), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
    await tester.pump();
    expect(find.text('3 products'), findsOneWidget);
  });

  testWidgets('an empty catalog shows an empty state', (tester) async {
    await _pumpPage(tester, _catalogOf(const []));

    expect(find.text('No products yet'), findsOneWidget);
    expect(find.byType(GridView), findsNothing);
  });

  testWidgets('a failed load shows an error and Try again recovers', (
    tester,
  ) async {
    var attempts = 0;
    final catalog = _FakeCatalog(() async {
      attempts++;
      if (attempts == 1) throw StateError('offline');
      return [_lipstick];
    });
    await _pumpPage(tester, catalog);

    expect(find.text('Could not load products'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await _settle(tester);

    expect(find.text('Could not load products'), findsNothing);
    expect(_card(_lipstick), findsOneWidget);
    expect(catalog.calls, 2);
  });

  testWidgets('nothing is added to favorites by opening the page', (
    tester,
  ) async {
    await _pumpPage(tester, _catalogOf([_lipstick, _blush]));

    expect(repo.upsertCalls, 0);
    expect(repo.rowsOf('user-1'), isEmpty);
    expect(
      find.descendant(
        of: _heart(_lipstick),
        matching: find.byIcon(Icons.favorite_border),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the heart saves to the database and removes again', (
    tester,
  ) async {
    await _pumpPage(tester, _catalogOf([_lipstick]));

    await tester.tap(_heart(_lipstick));
    await _settle(tester);

    expect(repo.rowsOf('user-1').keys, ['glow beauty::soft matte lipstick']);
    expect(
      find.descendant(
        of: _heart(_lipstick),
        matching: find.byIcon(Icons.favorite),
      ),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 2));
    await tester.tap(_heart(_lipstick));
    await _settle(tester);

    expect(repo.rowsOf('user-1'), isEmpty);
    expect(
      find.descendant(
        of: _heart(_lipstick),
        matching: find.byIcon(Icons.favorite_border),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a favorite saved earlier is shown as favorited', (tester) async {
    repo.rowsOf('user-1')['glow beauty::soft matte lipstick'] = {
      'name': 'Soft Matte Lipstick',
      'brand': 'Glow Beauty',
      'price': 24.99,
    };
    await _pumpPage(tester, _catalogOf([_lipstick, _blush]));

    expect(
      find.descendant(
        of: _heart(_lipstick),
        matching: find.byIcon(Icons.favorite),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: _heart(_blush),
        matching: find.byIcon(Icons.favorite_border),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a failed save keeps the heart empty and tells the user', (
    tester,
  ) async {
    await _pumpPage(tester, _catalogOf([_lipstick]));
    repo.failWrites = true;

    await tester.tap(_heart(_lipstick));
    await _settle(tester);

    expect(
      find.text('Could not update favorites. Please retry.'),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: _heart(_lipstick),
        matching: find.byIcon(Icons.favorite_border),
      ),
      findsOneWidget,
    );
  });

  testWidgets('details stay in sync with the catalog heart', (tester) async {
    await _pumpPage(tester, _catalogOf([_lipstick]));

    await tester.tap(_card(_lipstick));
    await tester.pumpAndSettle();
    expect(find.byType(ProductDetailsPage), findsOneWidget);
    expect(find.text('Shade: Rosewood'), findsOneWidget);
    expect(find.text('Save to Favorites'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('product-favorite-button')));
    await tester.pumpAndSettle();
    expect(find.text('Remove from Favorites'), findsOneWidget);
    expect(repo.rowsOf('user-1'), hasLength(1));

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();

    expect(find.byType(ProductDetailsPage), findsNothing);
    expect(
      find.descendant(
        of: _heart(_lipstick),
        matching: find.byIcon(Icons.favorite),
      ),
      findsOneWidget,
    );
  });

  testWidgets('standalone, the page has a working Back button', (tester) async {
    tester.view.devicePixelRatio = 3.0;
    tester.view.physicalSize = const Size(390, 844) * 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => RecommendedProductsPage(
                    catalogService: _catalogOf([_lipstick]),
                  ),
                ),
              ),
              child: const Text('open products'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open products'));
    await tester.pumpAndSettle();
    expect(find.text('Recommended for You'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('open products'), findsOneWidget);
  });

  for (final size in const [Size(320, 568), Size(411, 891), Size(800, 1000)]) {
    testWidgets('no overflow at ${size.width.toInt()}x${size.height.toInt()}', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 3.0;
      tester.view.physicalSize = size * 3.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: RecommendedProductsPage(
            catalogService: _catalogOf([_lipstick, _blush, _liner]),
          ),
        ),
      );
      await _settle(tester);

      expect(tester.takeException(), isNull);
    });
  }
}
