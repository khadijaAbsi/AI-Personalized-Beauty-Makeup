import '../models/user_profile.dart';

/// Exception thrown when profile loading fails.
///
/// The message is safe to display to the user.
class ProfileException implements Exception {
  const ProfileException([this.message = defaultMessage]);

  static const String defaultMessage =
      "We couldn't load your profile. Please try again.";

  final String message;

  @override
  String toString() => 'ProfileException: $message';
}

/// Provides the profile of the currently authenticated user.
///
/// Implementations:
/// - SupabaseProfileService: real account information.
/// - MockProfileService: sample data for tests.
///
/// Returns:
/// - UserProfile when account information exists.
/// - null when no profile is available.
/// - ProfileException when loading fails.
abstract interface class ProfileService {
  Future<UserProfile?> loadProfile();
}
