/// Thrown when an auth request fails. The message is safe to show to users.
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => 'AuthException: $message';
}

/// The UI only talks to this interface.
/// Later, add `SupabaseAuthService implements AuthService` and swap it in.
abstract interface class AuthService {
  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  });

  Future<void> signIn({
    required String email,
    required String password,
  });
}

/// Frontend-only stand-in. It never stores or logs passwords.
///
/// Demo behavior:
/// - Sign up always succeeds.
/// - Log in succeeds, unless the password is [demoFailurePassword],
///   which simulates "wrong credentials" so the error state can be tested.
class MockAuthService implements AuthService {
  const MockAuthService({this.delay = const Duration(milliseconds: 1200)});

  static const String demoFailurePassword = 'wrongpass';

  final Duration delay;

  @override
  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(delay);
  }

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(delay);
    if (password == demoFailurePassword) {
      throw const AuthException('Incorrect email or password. Please try again.');
    }
  }
}
