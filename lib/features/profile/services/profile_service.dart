import '../models/user_profile.dart';

/// Thrown when the profile can't be loaded. [message] is safe to show.
class ProfileException implements Exception {
  const ProfileException([this.message = defaultMessage]);

  static const String defaultMessage =
      "We couldn't load your profile. Please try again.";

  final String message;

  @override
  String toString() => 'ProfileException: $message';
}

/// Loads the profile of the CURRENTLY SIGNED-IN user.
///
/// There is deliberately no user-id parameter: an implementation decides whose
/// profile to load from the authenticated session, so the UI has no way to ask
/// for someone else's data.
///
/// - Returns the profile when there is one.
/// - Returns null when nothing exists yet (the screen shows an empty state).
/// - Throws [ProfileException] on failure (the screen shows an error + Retry).
///
/// A Supabase implementation would, for example, read
/// `Supabase.instance.client.auth.currentUser` for the id, then load that
/// user's profile row, latest face analysis and saved-looks / favorites
/// counts (with row-level security so only their own rows are readable), and
/// map them to a [UserProfile].
abstract interface class ProfileService {
  Future<UserProfile?> loadProfile();
}
