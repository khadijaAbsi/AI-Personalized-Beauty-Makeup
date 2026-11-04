import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Account-scoped favorites. The in-memory list is only a display cache;
/// Supabase is the source of truth. No test products are inserted automatically.
class FavoritesService extends ChangeNotifier {
  FavoritesService._();

  static final FavoritesService instance = FavoritesService._();

  final List<Map<String, dynamic>> products = [];
  String? _ownerId;
  bool _loaded = false;
  Future<void>? _pendingLoad;

  SupabaseClient get _client => Supabase.instance.client;

  String _key(Map<String, dynamic> product) {
    final brand = (product['brand'] as String? ?? '').trim().toLowerCase();
    final name = (product['name'] as String? ?? '').trim().toLowerCase();
    return '$brand::$name';
  }

  bool isFavorite(String name) {
    _discardOtherUserData();
    return products.any((product) => product['name'] == name);
  }

  void _discardOtherUserData() {
    final currentId = _client.auth.currentUser?.id;
    if (_ownerId == currentId) return;
    _ownerId = currentId;
    _loaded = false;
    _pendingLoad = null;
    products.clear();
    notifyListeners();
  }

  /// Loads current user's favorites once per session; refresh=true forces a
  /// server read. Calling it after switching accounts clears the prior cache.
  Future<void> ensureLoaded({bool refresh = false}) async {
    _discardOtherUserData();
    final ownerId = _ownerId;
    if (ownerId == null) return;
    if (_loaded && !refresh) return;
    if (_pendingLoad != null) return _pendingLoad!;

    final request = _fetch(ownerId);
    _pendingLoad = request;
    try {
      await request;
    } finally {
      if (identical(_pendingLoad, request)) _pendingLoad = null;
    }
  }

  Future<void> _fetch(String ownerId) async {
    final rows = await _client
        .from('favorite_products')
        .select('product_data')
        .eq('user_id', ownerId)
        .order('created_at', ascending: false);

    if (_ownerId != ownerId || _client.auth.currentUser?.id != ownerId) {
      return;
    }
    final items = <Map<String, dynamic>>[];
    for (final row in rows) {
      final data = Map<String, dynamic>.from(row['product_data'] as Map);
      final rawColor = data.remove('color_argb');
      data['color'] = rawColor is num
          ? Color(rawColor.toInt())
          : const Color(0xFFE8C0B8);
      // IconData cannot be serialized reliably across Flutter release builds.
      data['icon'] = Icons.spa_outlined;
      items.add(data);
    }
    products
      ..clear()
      ..addAll(items);
    _loaded = true;
    notifyListeners();
  }

  Map<String, dynamic> _toJson(Map<String, dynamic> product) {
    return {
      'name': product['name'],
      'brand': product['brand'] ?? '',
      'price': product['price'] ?? 0,
      'description': product['description'] ?? '',
      'category': product['category'] ?? '',
      'imageUrl': product['imageUrl'],
      'color_argb': (product['color'] is Color)
          ? (product['color'] as Color).toARGB32()
          : const Color(0xFFE8C0B8).toARGB32(),
    };
  }

  /// Persist first, then change the cache, so failure never looks like success.
  Future<void> toggleFavorite(Map<String, dynamic> product) async {
    await ensureLoaded();
    final ownerId = _client.auth.currentUser?.id;
    if (ownerId == null) throw StateError('Please log in to save products.');
    if (_ownerId != ownerId) throw StateError('Account changed; please retry.');
    final key = _key(product);
    if (key == '::') throw ArgumentError('Product must have a name.');

    final index = products.indexWhere((p) => _key(p) == key);
    if (index >= 0) {
      await _client.from('favorite_products').delete()
          .eq('user_id', ownerId).eq('product_key', key);
      if (_client.auth.currentUser?.id != ownerId) return;
      products.removeWhere((p) => _key(p) == key);
    } else {
      await _client.from('favorite_products').upsert({
        'user_id': ownerId,
        'product_key': key,
        'product_data': _toJson(product),
      }, onConflict: 'user_id,product_key');
      if (_client.auth.currentUser?.id != ownerId) return;
      products.add(Map<String, dynamic>.from(product));
    }
    notifyListeners();
  }

  Future<void> removeAt(int index) async {
    await ensureLoaded();
    if (index < 0 || index >= products.length) return;
    final ownerId = _client.auth.currentUser?.id;
    if (ownerId == null) throw StateError('Please log in first.');
    final key = _key(products[index]);
    await _client.from('favorite_products').delete()
        .eq('user_id', ownerId).eq('product_key', key);
    if (_client.auth.currentUser?.id != ownerId) return;
    products.removeWhere((p) => _key(p) == key);
    notifyListeners();
  }
}
