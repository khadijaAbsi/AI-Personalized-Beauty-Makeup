import '../models/user_profile.dart';
import 'mock_user_profile.dart';
import 'profile_service.dart';

/// Frontend-only stand-in: returns sample data after a short delay (so the
/// loading state is visible). It does not know who is signed in.
class MockProfileService implements ProfileService {
  MockProfileService({
    this.profile = mockUserProfile,
    this.delay = const Duration(milliseconds: 600),
    this.failFirstAttempts = 0,
  });

  /// What to return. Pass `profile: null` to simulate "no profile yet".
  final UserProfile? profile;

  /// Simulated loading time. Use [Duration.zero] in tests (no timer is made).
  final Duration delay;

  /// Makes the first N loads throw, for trying the error state and Retry by
  /// hand, e.g. `MockProfileService(failFirstAttempts: 1)`.
  final int failFirstAttempts;

  int _loads = 0;

  @override
  Future<UserProfile?> loadProfile() async {
    _loads++;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (_loads <= failFirstAttempts) throw const ProfileException();
    return profile;
  }
}
