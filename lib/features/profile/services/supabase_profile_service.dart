import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../models/user_profile.dart';
import 'profile_service.dart';

/// Loads real GlowAI account information from Supabase Auth.
///
/// Currently provides:
/// - User ID
/// - Full name
/// - Email
/// - Avatar URL, if available
///
/// Face analysis, saved looks, and favorite product counts
/// remain unavailable until their database integration.
class SupabaseProfileService implements ProfileService {
  SupabaseProfileService({supabase.SupabaseClient? client})
    : _client = client ?? supabase.Supabase.instance.client;

  final supabase.SupabaseClient _client;

  @override
  Future<UserProfile?> loadProfile() async {
    try {
      // Get the currently authenticated user.
      final user = _client.auth.currentUser;

      // No authenticated user.
      if (user == null) {
        return null;
      }

      // Metadata saved during signup.
      final metadata = user.userMetadata ?? <String, dynamic>{};

      final fullName = _optionalString(metadata['full_name']);
      final avatarUrl = _optionalString(metadata['avatar_url']);

      // Counts are read from the same account-owned tables as the UI.
      // If an RLS permission or network request fails, show an error rather
      // than silently reporting 0 or stale local counts.
      final counts = await Future.wait<int>([
        _client.from('saved_looks').count(),
        _client.from('favorite_products').count(),
      ]);

      return UserProfile(
        id: user.id,
        name: fullName,
        email: user.email,
        avatarUrl: avatarUrl,

        // Face analysis history is still a separate integration.
        latestFaceAnalysis: null,
        savedLooksCount: counts[0],
        favoriteProductsCount: counts[1],

        // This represents a real user, not demo data.
        isMock: false,
      );
    } on supabase.AuthException catch (_) {
      throw const ProfileException(
        'Unable to access your account information.',
      );
    } on ProfileException {
      rethrow;
    } catch (_) {
      throw const ProfileException();
    }
  }

  /// Converts optional metadata into a nonempty string.
  String? _optionalString(dynamic value) {
    if (value is! String) return null;

    final result = value.trim();

    return result.isEmpty ? null : result;
  }
}
