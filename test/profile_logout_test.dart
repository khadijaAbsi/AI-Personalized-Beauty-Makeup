import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glowai/core/routing/app_router.dart';
import 'package:glowai/features/auth/services/auth_service.dart';
import 'package:glowai/features/profile/screens/profile_screen.dart';
import 'package:glowai/features/profile/services/mock_user_profile.dart';

import 'helpers/profile_test_helpers.dart';

class _FakeSignOut implements SignOutService {
  _FakeSignOut({this.error});

  final Object? error;
  final Completer<void> gate = Completer<void>()..complete();
  int calls = 0;

  @override
  Future<void> signOut() async {
    calls++;
    await gate.future;
    if (error != null) throw error!;
  }
}

Future<void> _pumpProfile(WidgetTester tester, SignOutService auth) async {
  tester.view.devicePixelRatio = 3.0;
  tester.view.physicalSize = const Size(390, 844) * 3.0;
  addTearDown(tester.view.reset);

  final profile = FakeProfileService();
  await tester.pumpWidget(
    MaterialApp(
      onGenerateRoute: (settings) {
        if (settings.name == AppRouter.login) {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const Scaffold(body: Text('login screen')),
          );
        }
        return null;
      },
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    ProfileScreen(profileService: profile, authService: auth),
              ),
            ),
            child: const Text('protected screen'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('protected screen'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  profile.complete(mockUserProfile);
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('Log Out signs out once and returns to the login screen', (
    tester,
  ) async {
    final auth = _FakeSignOut();
    await _pumpProfile(tester, auth);

    await tester.ensureVisible(find.text('Log Out'));
    await tester.pump();
    await tester.tap(find.text('Log Out'));
    await tester.pumpAndSettle();

    expect(auth.calls, 1);
    expect(find.text('login screen'), findsOneWidget);
    // Everything that was open is gone, so Back cannot return to it.
    expect(find.byType(ProfileScreen, skipOffstage: false), findsNothing);
    expect(find.text('protected screen', skipOffstage: false), findsNothing);
    expect(
      tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
      isFalse,
    );
  });

  testWidgets('a second tap while logging out is ignored', (tester) async {
    final gate = Completer<void>();
    final slow = _SlowSignOut(gate);
    await _pumpProfile(tester, slow);

    await tester.ensureVisible(find.text('Log Out'));
    await tester.pump();
    await tester.tap(find.text('Log Out'));
    await tester.pump();
    expect(find.text('Logging out...'), findsOneWidget);

    await tester.tap(find.text('Logging out...'), warnIfMissed: false);
    gate.complete();
    await tester.pumpAndSettle();

    expect(slow.calls, 1);
  });

  testWidgets('a failed logout stays on Profile and shows the message', (
    tester,
  ) async {
    final auth = _FakeSignOut(error: const AuthException('Network error.'));
    await _pumpProfile(tester, auth);

    await tester.ensureVisible(find.text('Log Out'));
    await tester.pump();
    await tester.tap(find.text('Log Out'));
    await tester.pump();
    await tester.pump();

    // The snackbar can be drawn by more than one Scaffold in this test app.
    expect(find.text('Network error.'), findsWidgets);
    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.text('login screen'), findsNothing);
    // The button is usable again.
    expect(find.text('Log Out'), findsOneWidget);
  });
}

class _SlowSignOut implements SignOutService {
  _SlowSignOut(this._gate);

  final Completer<void> _gate;
  int calls = 0;

  @override
  Future<void> signOut() async {
    calls++;
    await _gate.future;
  }
}
