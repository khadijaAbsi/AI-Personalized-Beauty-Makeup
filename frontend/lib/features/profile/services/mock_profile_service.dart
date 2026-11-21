import '../models/user_profile.dart';
import 'mock_user_profile.dart';
import 'profile_service.dart';

/// Mock profile implementation used for widget tests.
///
/// Does not communicate with Supabase.
/// Returns sample information after an optional delay.
class MockProfileService implements ProfileService {
  MockProfileService({
    this.profile = mockUserProfile,
    this.delay = const Duration(milliseconds: 600),
    this.failFirstAttempts = 0,
  });

  /// Profile returned by the mock service.
  ///
  /// Set to null to simulate an empty profile.
  final UserProfile? profile;

  /// Simulated loading delay.
  final Duration delay;

  /// Simulate failures during the first N requests.
  final int failFirstAttempts;

  int _loads = 0;

  @override
  Future<UserProfile?> loadProfile() async {
    _loads++;

    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }

    if (_loads <= failFirstAttempts) {
      throw const ProfileException();
    }

    return profile;
  }
}
