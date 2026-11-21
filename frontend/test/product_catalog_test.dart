import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glowai/features/favorites/services/favorites_service.dart';
import 'package:glowai/features/products/data/mock_product_catalog.dart';
import 'package:glowai/features/products/models/product.dart';
import 'package:glowai/features/products/services/product_catalog_service.dart';

void main() {
  group('mock catalog', () {
    test('has realistic, complete products', () {
      expect(mockProductCatalog.length, greaterThanOrEqualTo(12));
      for (final product in mockProductCatalog) {
        expect(product.id, isNotEmpty);
        expect(product.name, isNotEmpty);
        expect(product.brand, isNotEmpty);
        expect(product.category, isNotEmpty);
        expect(product.description, isNotEmpty);
        expect(product.shade, isNotEmpty, reason: product.name);
        if (product.price != null) {
          expect(product.price, greaterThan(0), reason: product.name);
        }
      }
    });

    test('ids and favorite keys are unique', () {
      final ids = mockProductCatalog.map((p) => p.id).toSet();
      final keys = mockProductCatalog.map((p) => p.favoriteKey).toSet();

      expect(ids.length, mockProductCatalog.length);
      // The favorite key is brand + name; two products sharing it would be
      // saved as one favorite.
      expect(keys.length, mockProductCatalog.length);
    });

    test('keeps the products users may already have favorited', () {
      const legacyKeys = {
        'glow beauty::soft matte lipstick',
        'blush studio::rose blush',
        'glow beauty::luminous foundation',
        'lash & co.::volume mascara',
        'blush studio::nude lip gloss',
        'velvet touch::eyeshadow palette',
        'glow beauty::setting powder',
        'lash & co.::brow definer',
      };
      final keys = mockProductCatalog.map((p) => p.favoriteKey).toSet();

      expect(keys.containsAll(legacyKeys), isTrue);
    });

    test('covers face, cheeks, eyes and lips', () {
      final categories = mockProductCatalog.map((p) => p.category).toSet();

      expect(categories, containsAll(['Face', 'Cheeks', 'Eyes', 'Lips']));
    });

    test(
      'the mock service serves the catalog and holds no user data',
      () async {
        final products = await const MockProductCatalogService().loadProducts();

        expect(products, mockProductCatalog);
      },
    );
  });

  group('Product', () {
    const product = Product(
      id: 'p1',
      name: 'Silk Bronzer',
      brand: 'Velvet Touch',
      category: 'Cheeks',
      description: 'Soft warmth.',
      color: Color(0xFFC99566),
      shade: 'Warm Sand',
      price: 26,
    );

    test('its favorite key is brand + name, ignoring case and spacing', () {
      expect(product.favoriteKey, 'velvet touch::silk bronzer');
      expect(
        FavoritesService.productKey({
          'brand': ' VELVET touch ',
          'name': 'silk BRONZER',
        }),
        product.favoriteKey,
      );
    });

    test('survives a trip through the favorites map', () {
      final restored = Product.fromFavoriteMap(product.toFavoriteMap());

      expect(restored.name, product.name);
      expect(restored.brand, product.brand);
      expect(restored.category, product.category);
      expect(restored.shade, 'Warm Sand');
      expect(restored.color, product.color);
      expect(restored.price, 26);
      expect(restored.favoriteKey, product.favoriteKey);
    });

    test('price is optional', () {
      const free = Product(
        id: 'p2',
        name: 'Sample',
        brand: 'Brand',
        category: 'Lips',
        description: 'd',
        color: Color(0xFFFFFFFF),
      );

      expect(free.hasPrice, isFalse);
      expect(free.toFavoriteMap()['price'], 0);
      expect(Product.fromFavoriteMap(free.toFavoriteMap()).price, isNull);
      expect(Product.fromFavoriteMap(free.toFavoriteMap()).hasPrice, isFalse);
    });

    test('an old favorites entry without shade or colour still opens', () {
      final restored = Product.fromFavoriteMap({
        'name': 'Setting Powder',
        'brand': 'Glow Beauty',
        'price': 22.5,
      });

      expect(restored.shade, isNull);
      expect(restored.color, isA<Color>());
      expect(restored.category, isNotEmpty);
    });
  });
}
