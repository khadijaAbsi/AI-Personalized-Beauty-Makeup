import 'package:glowai/features/auth/services/auth_service.dart';

/// Test double: counts calls, waits 100 ms, optionally fails.
class FakeAuthService implements AuthService {
  FakeAuthService({this.error});

  final AuthException? error;
  int signUpCalls = 0;
  int signInCalls = 0;

  @override
  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    signUpCalls++;
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (error != null) throw error!;
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    signInCalls++;
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (error != null) throw error!;
  }
}
