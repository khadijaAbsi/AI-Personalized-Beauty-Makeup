import 'dart:async';

import 'package:glowai/features/favorites/services/favorites_service.dart';

/// In-memory stand-in for the `favorite_products` table.
///
/// Like the real table it holds at most one row per (user, product key), so
/// saving the same product twice never creates a duplicate.
class FakeFavoritesRepository implements FavoritesRepository {
  FakeFavoritesRepository({this.userId = 'user-1'});

  /// The signed-in user. Null means nobody is signed in.
  String? userId;

  /// user id -> product key -> product_data, oldest first.
  final Map<String, Map<String, Map<String, dynamic>>> rows = {};

  int fetchCalls = 0;
  int upsertCalls = 0;
  int deleteCalls = 0;

  /// When set, writes wait until this completes (to test double taps).
  Completer<void>? writeGate;

  /// Makes every write fail, like a network or RLS error.
  bool failWrites = false;

  /// Makes every read fail.
  bool failReads = false;

  Map<String, Map<String, dynamic>> rowsOf(String user) =>
      rows.putIfAbsent(user, () => {});

  @override
  String? get currentUserId => userId;

  @override
  Future<List<Map<String, dynamic>>> fetchProductData(String ownerId) async {
    fetchCalls++;
    if (failReads) throw StateError('read failed');
    return [
      for (final data in rowsOf(ownerId).values.toList().reversed)
        Map<String, dynamic>.from(data),
    ];
  }

  @override
  Future<void> upsert(
    String ownerId,
    String key,
    Map<String, dynamic> data,
  ) async {
    upsertCalls++;
    await writeGate?.future;
    if (failWrites) throw StateError('write failed');
    rowsOf(ownerId)[key] = Map<String, dynamic>.from(data);
  }

  @override
  Future<void> delete(String ownerId, String key) async {
    deleteCalls++;
    await writeGate?.future;
    if (failWrites) throw StateError('write failed');
    rowsOf(ownerId).remove(key);
  }
}
