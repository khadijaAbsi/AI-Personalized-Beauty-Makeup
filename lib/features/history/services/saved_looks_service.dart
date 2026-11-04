import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/saved_look.dart';

/// Account-scoped persistence for looks bookmarked in GlowAI.
/// Keeps the existing SavedLook UI model; does not seed demo looks.
class SavedLooksService {
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);
  static final List<SavedLook> _looks = [];
  static String? _ownerId;
  static bool _loaded = false;
  static Future<void>? _pendingLoad;

  static SupabaseClient get _client => Supabase.instance.client;

  static void _notify() => changes.value++;

  static void _checkAccount() {
    final userId = _client.auth.currentUser?.id;
    if (userId == _ownerId) return;
    _ownerId = userId;
    _loaded = false;
    _pendingLoad = null;
    _looks.clear();
    _notify();
  }

  static String _iconKey(IconData icon) {
    if (icon == Icons.wb_sunny_outlined) return 'sun';
    if (icon == Icons.work_outline) return 'office';
    if (icon == Icons.celebration_outlined) return 'party';
    if (icon == Icons.wb_twilight) return 'twilight';
    if (icon == Icons.spa_outlined) return 'spa';
    if (icon == Icons.favorite_border) return 'heart';
    return 'sparkle';
  }

  static IconData _iconFromKey(String? name) {
    switch (name) {
      case 'sun': return Icons.wb_sunny_outlined;
      case 'office': return Icons.work_outline;
      case 'party': return Icons.celebration_outlined;
      case 'twilight': return Icons.wb_twilight;
      case 'spa': return Icons.spa_outlined;
      case 'heart': return Icons.favorite_border;
      default: return Icons.auto_awesome;
    }
  }

  static SavedLook _fromRow(Map<String, dynamic> row) {
    final saved = DateTime.tryParse(row['created_at']?.toString() ?? '');
    final days = saved == null ? 0 : DateTime.now().difference(saved).inDays;
    final label = days <= 0 ? 'Saved just now'
        : days == 1 ? 'Saved 1 day ago' : 'Saved $days days ago';
    return SavedLook(
      id: row['id'].toString(),
      title: row['title'] as String,
      occasion: row['occasion'] as String,
      description: row['description'] as String? ?? '',
      savedLabel: label,
      previewColor: Color((row['preview_color'] as num).toInt()),
      previewIcon: _iconFromKey(row['preview_icon'] as String?),
    );
  }

  static Future<void> ensureLoaded({bool refresh = false}) async {
    _checkAccount();
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

  static Future<void> _fetch(String ownerId) async {
    final rows = await _client.from('saved_looks')
        .select('id,title,occasion,description,preview_color,preview_icon,created_at')
        .eq('user_id', ownerId)
        .order('created_at', ascending: false);
    if (_ownerId != ownerId || _client.auth.currentUser?.id != ownerId) return;
    _looks
      ..clear()
      ..addAll(rows.map((row) => _fromRow(row)));
    _loaded = true;
    _notify();
  }

  static bool isSaved(String title, String occasion) {
    _checkAccount();
    return _looks.any((item) => item.title == title && item.occasion == occasion);
  }

  Future<List<SavedLook>> fetchSavedLooks() async {
    await ensureLoaded(refresh: true);
    return List<SavedLook>.from(_looks);
  }

  static Future<void> saveLook({
    required String title,
    required String occasion,
    required String description,
    required Color previewColor,
    required IconData previewIcon,
  }) async {
    await ensureLoaded();
    final ownerId = _client.auth.currentUser?.id;
    if (ownerId == null) throw StateError('Please log in to save looks.');
    if (isSaved(title, occasion)) return;
    final row = await _client.from('saved_looks').insert({
      'user_id': ownerId,
      'title': title,
      'occasion': occasion,
      'description': description,
      'preview_color': previewColor.toARGB32(),
      'preview_icon': _iconKey(previewIcon),
    }).select('id,title,occasion,description,preview_color,preview_icon,created_at').single();
    if (_client.auth.currentUser?.id != ownerId) return;
    _looks.insert(0, _fromRow(row));
    _notify();
  }

  static Future<void> toggleSaveLook({
    required String title,
    required String occasion,
    required String description,
    required Color previewColor,
    required IconData previewIcon,
  }) async {
    await ensureLoaded();
    final existing = _looks.where((l) => l.title == title && l.occasion == occasion);
    if (existing.isNotEmpty) {
      await removeLook(existing.first);
    } else {
      await saveLook(title: title, occasion: occasion,
          description: description, previewColor: previewColor,
          previewIcon: previewIcon);
    }
  }

  static Future<void> removeLook(SavedLook look) async {
    final ownerId = _client.auth.currentUser?.id;
    if (ownerId == null) throw StateError('Please log in first.');
    await _client.from('saved_looks').delete()
        .eq('user_id', ownerId).eq('id', look.id);
    if (_client.auth.currentUser?.id != ownerId) return;
    _looks.removeWhere((item) => item.id == look.id);
    _notify();
  }

  /// Undo stores the look again. The database allocates a new row ID.
  static Future<void> restoreLook(SavedLook look, int index) async {
    await saveLook(title: look.title, occasion: look.occasion,
        description: look.description, previewColor: look.previewColor,
        previewIcon: look.previewIcon);
  }
}
