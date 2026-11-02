import 'package:flutter_test/flutter_test.dart';
// Replace `glowai` with the `name:` in your pubspec.yaml if it differs.
import 'package:glowai/features/auth/services/auth_service.dart';

void main() {
  const service = MockAuthService(delay: Duration.zero);

  test('mock sign in succeeds for normal credentials', () async {
    await service.signIn(email: 'layla@example.com', password: 'password123');
  });

  test('mock sign in fails for the demo failure password', () async {
    expect(
      service.signIn(
        email: 'layla@example.com',
        password: MockAuthService.demoFailurePassword,
      ),
      throwsA(isA<AuthException>()),
    );
  });

  test('mock sign up succeeds', () async {
    await service.signUp(
      fullName: 'Layla Haddad',
      email: 'layla@example.com',
      password: 'password123',
    );
  });
}
