import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Exception used by the authentication layer.
///
/// Authentication screens can catch this exception and display
/// its message using the existing Snackbar.
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => 'AuthException: $message';
}

/// Authentication interface.
///
/// Login and Signup screens depend on this interface,
/// allowing real Supabase authentication or mock services
/// to be injected without changing the UI.
abstract interface class AuthService {
  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  });

  Future<void> signIn({required String email, required String password});
}

/// Real Supabase Authentication implementation.
///
/// Handles:
/// - User registration
/// - Email/password login
/// - Supabase authentication errors
/// - Session access
/// - Logout
class SupabaseAuthService implements AuthService {
  SupabaseAuthService({supabase.SupabaseClient? client})
    : _client = client ?? supabase.Supabase.instance.client;

  final supabase.SupabaseClient _client;

  /// Currently authenticated user.
  supabase.User? get currentUser => _client.auth.currentUser;

  /// Current authentication session.
  supabase.Session? get currentSession => _client.auth.currentSession;

  /// Listen for authentication changes.
  Stream<supabase.AuthState> get authStateChanges =>
      _client.auth.onAuthStateChange;

  /// Register a new user in Supabase.
  ///
  /// The user's full name is saved in authentication metadata.
  ///
  /// When email confirmation is enabled, Supabase normally
  /// creates the account without returning an active session.
  @override
  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'full_name': fullName.trim()},
      );

      if (response.user == null) {
        throw const AuthException(
          'Unable to process your registration. Please try again.',
        );
      }
    } on supabase.AuthException catch (e) {
      throw AuthException(e.message);
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException(
        'Unable to create your account. Please try again.',
      );
    }
  }

  /// Sign in an existing user using email and password.
  ///
  /// Supabase automatically manages the authentication session.
  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.session == null) {
        throw const AuthException(
          'Unable to establish a login session. Please try again.',
        );
      }
    } on supabase.AuthException catch (e) {
      throw AuthException(e.message);
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException('Unable to log in. Please try again.');
    }
  }

  /// Sign out the currently authenticated user.
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on supabase.AuthException catch (e) {
      throw AuthException(e.message);
    } catch (_) {
      throw const AuthException('Unable to log out. Please try again.');
    }
  }

  /// Send an email containing password recovery instructions.
  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email.trim());
    } on supabase.AuthException catch (e) {
      throw AuthException(e.message);
    } catch (_) {
      throw const AuthException('Unable to send password reset instructions.');
    }
  }
}

/// Mock authentication service for widget tests.
///
/// Does not communicate with Supabase.
/// Does not store or log passwords.
///
/// Existing tests can continue using this service.
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
  Future<void> signIn({required String email, required String password}) async {
    await Future<void>.delayed(delay);

    if (password == demoFailurePassword) {
      throw const AuthException(
        'Incorrect email or password. Please try again.',
      );
    }
  }
}
