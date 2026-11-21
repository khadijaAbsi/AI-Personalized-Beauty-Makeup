import 'package:flutter/material.dart';

import '../../favorites/services/favorites_service.dart';

/// A makeup product as the UI shows it.
///
/// This is only a *view model*. Where products come from (today a mock
/// catalog, later the recommendations produced after PSGAN applies a look) is
/// decided by a `ProductCatalogService`. Which products a user favorited is
/// stored separately by `FavoritesService` in Supabase, and a favorite keeps a
/// snapshot of the product, so favorites keep working when the catalog changes.
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.description,
    required this.color,
    this.shade,
    this.price,
    this.imageUrl,
    this.icon = Icons.spa_outlined,
  });

  /// Stable catalog identifier (not used as the favorites key, see
  /// [favoriteKey]).
  final String id;
  final String name;
  final String brand;

  /// For example Face, Eyes, Lips or Cheeks.
  final String category;
  final String description;

  /// Tint of the product tile; also the shade swatch when [shade] is set.
  final Color color;

  /// Shade name, when it is relevant for the product.
  final String? shade;

  /// Optional. Null or zero hides the price.
  final double? price;

  /// Optional product photo. Without one a tinted placeholder is shown.
  final String? imageUrl;

  /// Placeholder icon used when there is no photo.
  final IconData icon;

  bool get hasPrice => price != null && price! > 0;

  /// The key `FavoritesService` stores this product under (brand + name).
  String get favoriteKey => FavoritesService.productKey(toFavoriteMap());

  /// The map shape `FavoritesService` persists and reads.
  Map<String, dynamic> toFavoriteMap() => {
    'id': id,
    'name': name,
    'brand': brand,
    'price': price ?? 0,
    'description': description,
    'category': category,
    'shade': shade,
    'imageUrl': imageUrl,
    'color': color,
    'icon': icon,
  };

  /// Rebuilds a product from a favorites entry. Entries saved before shades
  /// existed simply have no shade.
  factory Product.fromFavoriteMap(Map<String, dynamic> map) {
    final name = map['name'] as String? ?? 'Product';
    final brand = map['brand'] as String? ?? '';
    final price = (map['price'] as num?)?.toDouble();
    return Product(
      id: map['id'] as String? ?? FavoritesService.productKey(map),
      name: name,
      brand: brand,
      category: map['category'] as String? ?? 'Beauty',
      description: map['description'] as String? ?? 'No description available.',
      color: map['color'] as Color? ?? const Color(0xFFE8C0B8),
      shade: map['shade'] as String?,
      price: price == null || price <= 0 ? null : price,
      imageUrl: map['imageUrl'] as String?,
      icon: map['icon'] as IconData? ?? Icons.spa_outlined,
    );
  }
}
