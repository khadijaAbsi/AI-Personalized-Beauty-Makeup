import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads and writes one user's favorite products.
///
/// The Supabase implementation is the real one. The interface exists so the
/// service logic (duplicate prevention, account switching, state sync) can be
/// tested without a live Supabase project.
abstract class FavoritesRepository {
  /// Id of the signed-in user, or null when nobody is signed in.
  String? get currentUserId;

  /// The `product_data` of every favorite of [ownerId], newest first.
  Future<List<Map<String, dynamic>>> fetchProductData(String ownerId);

  /// Inserts the favorite, or updates it if the user already has [key].
  Future<void> upsert(String ownerId, String key, Map<String, dynamic> data);

  Future<void> delete(String ownerId, String key);
}

/// `public.favorite_products` through the signed-in Supabase session.
/// Row Level Security restricts every query to the user's own rows.
class SupabaseFavoritesRepository implements FavoritesRepository {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Future<List<Map<String, dynamic>>> fetchProductData(String ownerId) async {
    final rows = await _client
        .from('favorite_products')
        .select('product_data')
        .eq('user_id', ownerId)
        .order('created_at', ascending: false);
    return [
      for (final row in rows)
        Map<String, dynamic>.from(row['product_data'] as Map),
    ];
  }

  @override
  Future<void> upsert(
    String ownerId,
    String key,
    Map<String, dynamic> data,
  ) async {
    await _client.from('favorite_products').upsert({
      'user_id': ownerId,
      'product_key': key,
      'product_data': data,
    }, onConflict: 'user_id,product_key');
  }

  @override
  Future<void> delete(String ownerId, String key) async {
    await _client
        .from('favorite_products')
        .delete()
        .eq('user_id', ownerId)
        .eq('product_key', key);
  }
}

/// Account-scoped favorites. The in-memory list is only a display cache;
/// Supabase is the source of truth. No test products are inserted automatically.
class FavoritesService extends ChangeNotifier {
  FavoritesService._();

  static final FavoritesService instance = FavoritesService._();

  FavoritesRepository _repo = SupabaseFavoritesRepository();

  final List<Map<String, dynamic>> products = [];
  final Set<String> _pendingKeys = {};
  String? _ownerId;
  bool _loaded = false;
  Future<void>? _pendingLoad;

  /// Uses [repository] instead of Supabase and clears the cache.
  /// Tests only.
  @visibleForTesting
  void debugUseRepository(FavoritesRepository repository) {
    _repo = repository;
    _resetState();
  }

  /// Restores the Supabase repository and clears the cache. Tests only.
  @visibleForTesting
  void debugReset() {
    _repo = SupabaseFavoritesRepository();
    _resetState();
  }

  void _resetState() {
    _ownerId = null;
    _loaded = false;
    _pendingLoad = null;
    _pendingKeys.clear();
    products.clear();
    notifyListeners();
  }

  /// The identity of a product in Favorites: brand + name, case-insensitive.
  /// It is the `product_key` column, so one user can have a product only once.
  static String productKey(Map<String, dynamic> product) {
    final brand = (product['brand'] as String? ?? '').trim().toLowerCase();
    final name = (product['name'] as String? ?? '').trim().toLowerCase();
    return '$brand::$name';
  }

  bool isFavorite(String name) {
    _discardOtherUserData();
    return products.any((product) => product['name'] == name);
  }

  /// Exact check (brand + name), used by the catalog and details screens so a
  /// product with the same name from another brand is not shown as favorite.
  bool isFavoriteProduct(Map<String, dynamic> product) {
    _discardOtherUserData();
    final key = productKey(product);
    return products.any((p) => productKey(p) == key);
  }

  /// True while this product's add/remove request is running. Screens disable
  /// its heart so a double tap cannot send two requests.
  bool isPending(Map<String, dynamic> product) =>
      _pendingKeys.contains(productKey(product));

  void _discardOtherUserData() {
    final currentId = _repo.currentUserId;
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
    final rows = await _repo.fetchProductData(ownerId);

    if (_ownerId != ownerId || _repo.currentUserId != ownerId) {
      return;
    }
    final items = <Map<String, dynamic>>[];
    for (final row in rows) {
      final data = Map<String, dynamic>.from(row);
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
      'id': product['id'],
      'name': product['name'],
      'brand': product['brand'] ?? '',
      'price': product['price'] ?? 0,
      'description': product['description'] ?? '',
      'category': product['category'] ?? '',
      'shade': product['shade'],
      'imageUrl': product['imageUrl'],
      'color_argb': (product['color'] is Color)
          ? (product['color'] as Color).toARGB32()
          : const Color(0xFFE8C0B8).toARGB32(),
    };
  }

  /// Persist first, then change the cache, so failure never looks like success.
  ///
  /// A second call for the same product while the first is still running is
  /// ignored. Adding is an upsert on (user, product key), so even a retry can
  /// never create a duplicate row.
  Future<void> toggleFavorite(Map<String, dynamic> product) async {
    await ensureLoaded();
    final ownerId = _repo.currentUserId;
    if (ownerId == null) throw StateError('Please log in to save products.');
    if (_ownerId != ownerId) throw StateError('Account changed; please retry.');
    final key = productKey(product);
    if (key == '::') throw ArgumentError('Product must have a name.');
    if (!_pendingKeys.add(key)) return;
    notifyListeners();

    try {
      final index = products.indexWhere((p) => productKey(p) == key);
      if (index >= 0) {
        await _repo.delete(ownerId, key);
        if (_repo.currentUserId != ownerId) return;
        products.removeWhere((p) => productKey(p) == key);
      } else {
        await _repo.upsert(ownerId, key, _toJson(product));
        if (_repo.currentUserId != ownerId) return;
        products.add(Map<String, dynamic>.from(product));
      }
    } finally {
      _pendingKeys.remove(key);
      notifyListeners();
    }
  }

  Future<void> removeAt(int index) async {
    await ensureLoaded();
    if (index < 0 || index >= products.length) return;
    final ownerId = _repo.currentUserId;
    if (ownerId == null) throw StateError('Please log in first.');
    final key = productKey(products[index]);
    if (!_pendingKeys.add(key)) return;
    notifyListeners();
    try {
      await _repo.delete(ownerId, key);
      if (_repo.currentUserId != ownerId) return;
      products.removeWhere((p) => productKey(p) == key);
    } finally {
      _pendingKeys.remove(key);
      notifyListeners();
    }
  }
}
