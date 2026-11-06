import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// Replace `glowai` with the `name:` in your pubspec.yaml if it differs.
import 'package:glowai/core/routing/app_router.dart';
import 'package:glowai/features/auth/screens/login_screen.dart';
import 'package:glowai/features/auth/screens/signup_screen.dart';
import 'package:glowai/features/auth/services/auth_service.dart';

import 'helpers/fake_auth_service.dart';

/// Phone-sized surface (390 x 844 logical px) like the design.
Future<void> _pumpSignup(WidgetTester tester, AuthService service) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(home: SignupScreen(authService: service)),
  );
}

Future<void> _fillValidForm(
  WidgetTester tester, {
  String confirm = 'password123',
}) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), 'Layla Haddad');
  await tester.enterText(fields.at(1), 'layla@example.com');
  await tester.enterText(fields.at(2), 'password123');
  await tester.enterText(fields.at(3), confirm);
}

Finder get _submitButton => find.widgetWithText(FilledButton, 'Create Account');

void main() {
  testWidgets('empty form shows all validation errors and does not submit', (
    tester,
  ) async {
    final service = FakeAuthService();
    await _pumpSignup(tester, service);

    await tester.tap(_submitButton);
    await tester.pump();

    expect(find.text('Please enter your full name'), findsOneWidget);
    expect(find.text('Please enter your email address'), findsOneWidget);
    expect(find.text('Please create a password'), findsOneWidget);
    expect(find.text('Please confirm your password'), findsOneWidget);
    expect(find.textContaining('accept the Terms'), findsOneWidget);
    expect(service.signUpCalls, 0);
  });

  testWidgets('mismatched passwords show an error', (tester) async {
    final service = FakeAuthService();
    await _pumpSignup(tester, service);

    await _fillValidForm(tester, confirm: 'different123');
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(_submitButton);
    await tester.pump();

    expect(find.text('Passwords do not match'), findsOneWidget);
    expect(service.signUpCalls, 0);
  });

  testWidgets('unchecked terms blocks submit', (tester) async {
    final service = FakeAuthService();
    await _pumpSignup(tester, service);

    await _fillValidForm(tester);
    await tester.tap(_submitButton);
    await tester.pump();

    expect(find.textContaining('accept the Terms'), findsOneWidget);
    expect(service.signUpCalls, 0);
  });

  testWidgets('valid form shows loading, then a success message', (
    tester,
  ) async {
    final service = FakeAuthService();
    await _pumpSignup(tester, service);

    await _fillValidForm(tester);
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(_submitButton);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(service.signUpCalls, 1);

    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.textContaining('Account created'), findsOneWidget);
  });

  testWidgets('service errors are shown to the user', (tester) async {
    final service = FakeAuthService(
      error: const AuthException('Email already in use'),
    );
    await _pumpSignup(tester, service);

    await _fillValidForm(tester);
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(_submitButton);
    await tester.pumpAndSettle();

    expect(find.text('Email already in use'), findsOneWidget);
  });

  testWidgets('password visibility toggle works', (tester) async {
    await _pumpSignup(tester, FakeAuthService());

    expect(find.byIcon(Icons.visibility_outlined), findsNWidgets(2));
    await tester.tap(find.byIcon(Icons.visibility_outlined).first);
    await tester.pump();

    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
  });

  testWidgets('Log In link opens the login screen', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        initialRoute: AppRouter.signup,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );

    final logIn = find.text('Log In');
    await tester.ensureVisible(logIn);
    await tester.pump();
    await tester.tap(logIn);
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
