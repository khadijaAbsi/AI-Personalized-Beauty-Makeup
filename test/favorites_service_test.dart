import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glowai/features/favorites/services/favorites_service.dart';

import 'helpers/fake_favorites_repository.dart';

Map<String, dynamic> _product({
  String name = 'Rose Blush',
  String brand = 'Blush Studio',
}) => {
  'id': 'blush-rose-blush',
  'name': name,
  'brand': brand,
  'price': 18.5,
  'description': 'A soft rose blush.',
  'category': 'Cheeks',
  'shade': 'Petal Rose',
  'imageUrl': null,
  'color': const Color(0xFFF0A9A8),
  'icon': Icons.circle,
};

void main() {
  final service = FavoritesService.instance;
  late FakeFavoritesRepository repo;

  setUp(() {
    repo = FakeFavoritesRepository();
    service.debugUseRepository(repo);
  });

  tearDown(service.debugReset);

  test('starts empty and never inserts anything by itself', () async {
    await service.ensureLoaded();

    expect(service.products, isEmpty);
    expect(repo.upsertCalls, 0);
    expect(service.isFavoriteProduct(_product()), isFalse);
  });

  test('toggling adds the product to the database, then removes it', () async {
    await service.toggleFavorite(_product());

    expect(service.isFavoriteProduct(_product()), isTrue);
    expect(repo.rowsOf('user-1').keys, ['blush studio::rose blush']);
    final stored = repo.rowsOf('user-1').values.single;
    expect(stored['shade'], 'Petal Rose');
    expect(stored['color_argb'], const Color(0xFFF0A9A8).toARGB32());

    await service.toggleFavorite(_product());

    expect(service.isFavoriteProduct(_product()), isFalse);
    expect(repo.rowsOf('user-1'), isEmpty);
  });

  test('a product can be a favorite only once per user', () async {
    await service.toggleFavorite(_product());

    // A new session reads the saved favorite back.
    service.debugUseRepository(repo);
    await service.ensureLoaded();
    expect(service.products, hasLength(1));

    // The same product with different casing and spacing has the same key, so
    // toggling it removes the favorite instead of adding a second one.
    await service.toggleFavorite(
      _product(name: '  ROSE blush ', brand: 'blush studio'),
    );
    expect(repo.rowsOf('user-1'), isEmpty);
    expect(service.products, isEmpty);
  });

  test('the same name from another brand is a different product', () async {
    await service.toggleFavorite(_product());
    final other = _product(brand: 'Velvet Touch');

    expect(service.isFavoriteProduct(other), isFalse);
    await service.toggleFavorite(other);

    expect(repo.rowsOf('user-1'), hasLength(2));
    expect(service.isFavoriteProduct(_product()), isTrue);
    expect(service.isFavoriteProduct(other), isTrue);
  });

  test('a second toggle while the first is running is ignored', () async {
    await service.ensureLoaded();
    repo.writeGate = Completer<void>();

    final first = service.toggleFavorite(_product());
    await Future<void>.delayed(Duration.zero);
    expect(service.isPending(_product()), isTrue);

    final second = service.toggleFavorite(_product());
    repo.writeGate!.complete();
    await Future.wait([first, second]);

    expect(repo.upsertCalls, 1);
    expect(repo.deleteCalls, 0);
    expect(repo.rowsOf('user-1'), hasLength(1));
    expect(service.isPending(_product()), isFalse);
  });

  test('a failed save changes nothing and can be retried', () async {
    repo.failWrites = true;

    await expectLater(
      service.toggleFavorite(_product()),
      throwsA(isA<StateError>()),
    );
    expect(service.isFavoriteProduct(_product()), isFalse);
    expect(service.isPending(_product()), isFalse);

    repo.failWrites = false;
    await service.toggleFavorite(_product());
    expect(service.isFavoriteProduct(_product()), isTrue);
  });

  test('saving requires a signed-in user', () async {
    repo.userId = null;

    await expectLater(
      service.toggleFavorite(_product()),
      throwsA(isA<StateError>()),
    );
    expect(repo.upsertCalls, 0);
  });

  test('switching accounts never shows the previous user favorites', () async {
    await service.toggleFavorite(_product());
    expect(service.isFavoriteProduct(_product()), isTrue);

    repo.userId = 'user-2';
    expect(service.isFavoriteProduct(_product()), isFalse);
    expect(service.products, isEmpty);

    await service.ensureLoaded();
    expect(service.products, isEmpty);

    repo.userId = 'user-1';
    await service.ensureLoaded();
    expect(service.products, hasLength(1));
  });

  test('loading restores the saved colour and shade', () async {
    repo.rowsOf('user-1')['blush studio::rose blush'] = {
      'name': 'Rose Blush',
      'brand': 'Blush Studio',
      'price': 18.5,
      'shade': 'Petal Rose',
      'color_argb': 0xFFF0A9A8,
    };

    await service.ensureLoaded();

    expect(service.products.single['color'], const Color(0xFFF0A9A8));
    expect(service.products.single['shade'], 'Petal Rose');
  });

  test('favorites saved before shades existed still load', () async {
    repo.rowsOf('user-1')['glow beauty::setting powder'] = {
      'name': 'Setting Powder',
      'brand': 'Glow Beauty',
      'price': 22.5,
    };

    await service.ensureLoaded();

    expect(service.products.single['shade'], isNull);
    expect(service.products.single['color'], isA<Color>());
  });

  test('listeners are told when favorites change', () async {
    var notifications = 0;
    service.addListener(() => notifications++);

    await service.toggleFavorite(_product());

    expect(notifications, greaterThan(0));
  });
}
