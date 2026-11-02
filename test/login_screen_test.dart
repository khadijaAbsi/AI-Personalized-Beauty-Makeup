import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// Replace `glowai` with the `name:` in your pubspec.yaml if it differs.
import 'package:glowai/core/routing/app_router.dart';
import 'package:glowai/features/auth/screens/login_screen.dart';
import 'package:glowai/features/auth/screens/signup_screen.dart';
import 'package:glowai/features/auth/services/auth_service.dart';

import 'helpers/fake_auth_service.dart';

void _usePhoneSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

Future<void> _pumpLogin(WidgetTester tester, AuthService service) async {
  _usePhoneSurface(tester);
  await tester.pumpWidget(MaterialApp(home: LoginScreen(authService: service)));
}

Future<void> _pumpApp(WidgetTester tester) async {
  _usePhoneSurface(tester);
  await tester.pumpWidget(
    const MaterialApp(
      initialRoute: AppRouter.signup,
      onGenerateRoute: AppRouter.onGenerateRoute,
    ),
  );
}

Future<void> _enterCredentials(
  WidgetTester tester, {
  String email = 'layla@example.com',
  String password = 'password123',
}) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), email);
  await tester.enterText(fields.at(1), password);
}

Future<void> _tapText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Finder get _loginButton => find.widgetWithText(FilledButton, 'Log In');

void main() {
  group('validation', () {
    testWidgets('empty form shows required errors and does not submit',
        (tester) async {
      final service = FakeAuthService();
      await _pumpLogin(tester, service);

      await tester.tap(_loginButton);
      await tester.pump();

      expect(find.text('Please enter your email address'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
      expect(service.signInCalls, 0);
    });

    testWidgets('malformed email shows a format error', (tester) async {
      final service = FakeAuthService();
      await _pumpLogin(tester, service);

      await _enterCredentials(tester, email: 'layla@');
      await tester.tap(_loginButton);
      await tester.pump();

      expect(find.textContaining('valid email'), findsOneWidget);
      expect(service.signInCalls, 0);
    });

    testWidgets('a short password is accepted (length is not checked on login)',
        (tester) async {
      final service = FakeAuthService();
      await _pumpLogin(tester, service);

      await _enterCredentials(tester, password: 'abc');
      await tester.tap(_loginButton);
      await tester.pumpAndSettle();

      expect(service.signInCalls, 1);
    });
  });

  group('submission', () {
    testWidgets('shows loading, ignores repeat taps, then shows success',
        (tester) async {
      final service = FakeAuthService();
      await _pumpLogin(tester, service);

      await _enterCredentials(tester);
      await tester.tap(_loginButton);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(service.signInCalls, 1);

      // Button is disabled while loading: a second tap does nothing.
      await tester.tap(find.byType(FilledButton), warnIfMissed: false);
      await tester.pump();
      expect(service.signInCalls, 1);

      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.textContaining('Welcome back!'), findsOneWidget);
    });

    testWidgets('pressing Done on the keyboard submits', (tester) async {
      final service = FakeAuthService();
      await _pumpLogin(tester, service);

      await _enterCredentials(tester);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(service.signInCalls, 1);
    });

    testWidgets('failed login shows the error and re-enables the button',
        (tester) async {
      final service = FakeAuthService(
        error: const AuthException('Incorrect email or password.'),
      );
      await _pumpLogin(tester, service);

      await _enterCredentials(tester);
      await tester.tap(_loginButton);
      await tester.pumpAndSettle();

      expect(find.text('Incorrect email or password.'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.widget<FilledButton>(_loginButton).onPressed, isNotNull);
    });
  });

  group('interactions', () {
    testWidgets('Next on the email field moves focus to the password field',
        (tester) async {
      await _pumpLogin(tester, FakeAuthService());

      await tester.tap(find.byType(TextFormField).at(0));
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();

      final passwordField = tester.widget<EditableText>(
        find.descendant(
          of: find.byType(TextFormField).at(1),
          matching: find.byType(EditableText),
        ),
      );
      expect(passwordField.focusNode.hasFocus, isTrue);
    });

    testWidgets('password is hidden by default and the eye icon toggles it',
        (tester) async {
      await _pumpLogin(tester, FakeAuthService());

      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });
  });

  group('navigation', () {
    testWidgets('Create Account -> Log In -> Sign up returns to Create Account',
        (tester) async {
      await _pumpApp(tester);

      await _tapText(tester, 'Log In');
      expect(find.byType(LoginScreen), findsOneWidget);

      await _tapText(tester, 'Sign up');
      expect(find.byType(SignupScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });

    testWidgets('back arrow on Login returns to Create Account',
        (tester) async {
      await _pumpApp(tester);

      await _tapText(tester, 'Log In');
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(find.byType(SignupScreen), findsOneWidget);
    });
  });
}
