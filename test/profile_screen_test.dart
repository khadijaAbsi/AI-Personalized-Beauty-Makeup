import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glowai/core/routing/app_router.dart';
import 'package:glowai/features/face_analysis/models/face_analysis_result.dart';
import 'package:glowai/features/face_analysis/screens/face_analysis_guide_screen.dart';
import 'package:glowai/features/face_analysis/widgets/skin_tone_swatch.dart';
import 'package:glowai/features/profile/models/user_profile.dart';
import 'package:glowai/features/profile/screens/profile_screen.dart';
import 'package:glowai/features/profile/screens/settings_privacy_screen.dart';
import 'package:glowai/features/profile/services/mock_user_profile.dart';
import 'package:glowai/features/profile/services/profile_service.dart';

import 'helpers/profile_test_helpers.dart';

Widget _app({
  required Widget home,
  double textScale = 1.0,
  ProfileService? routeProfileService,
  bool stubSavedItemRoutes = false,
}) {
  return MaterialApp(
    onGenerateRoute: (settings) {
      // For the named-route test, inject controlled profile data rather than
      // requiring a live Supabase session.
      if (settings.name == AppRouter.profile && routeProfileService != null) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => ProfileScreen(profileService: routeProfileService),
        );
      }
      // Navigation-only tests should not require live Supabase requests.
      if (stubSavedItemRoutes &&
          (settings.name == AppRouter.savedLooks ||
              settings.name == AppRouter.favoriteProducts)) {
        final label = settings.name == AppRouter.savedLooks
            ? 'Saved Looks test destination'
            : 'Favorite Products test destination';
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => Scaffold(body: Center(child: Text(label))),
        );
      }
      return AppRouter.onGenerateRoute(settings);
    },
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: home,
  );
}

void _useScreen(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 3.0;
  tester.view.physicalSize = size * 3.0;
  addTearDown(tester.view.reset);
}

/// A service's result is delivered in a microtask and the frame it asks for is
/// built by the NEXT pump, so pump twice.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

/// Shows the screen, then finishes the load with [profile].
Future<FakeProfileService> _pumpLoaded(
  WidgetTester tester,
  UserProfile? profile, {
  Size size = const Size(390, 844),
  double textScale = 1.0,
  bool stubSavedItemRoutes = false,
}) async {
  _useScreen(tester, size);
  // Start from an empty tree so each call gets a brand-new screen State
  // (otherwise Flutter reuses the previous screen and its old service).
  await tester.pumpWidget(const SizedBox());
  final service = FakeProfileService();
  await tester.pumpWidget(
    _app(
      textScale: textScale,
      stubSavedItemRoutes: stubSavedItemRoutes,
      home: ProfileScreen(profileService: service),
    ),
  );
  service.complete(profile);
  await _settle(tester);
  return service;
}

Future<void> _tapText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
}

Finder get _retry => find.widgetWithText(FilledButton, 'Retry');

/// Opens a Saved Looks / Favorite Products route from Profile, goes Back, and
/// checks that Profile comes back and refreshes its counts.
///
/// Why this needs a second `service.complete(...)`:
/// `ProfileScreen._open()` deliberately calls `_load()` again after the pushed
/// route is popped, so the counts are fresh when the user returns. That second
/// load goes through [FakeProfileService], whose loads stay pending until the
/// test completes them. If the test never completes it, Profile correctly stays
/// on its loading spinner and the name (and counts) are not on screen.
Future<void> _expectSavedItemRouteRoundTrip(
  WidgetTester tester, {
  required String tapLabel,
  required String destinationText,
  required String oldCount,
  required String newCount,
  required UserProfile refreshedProfile,
}) async {
  // Keep the service: it is the only way to finish the reload after Back.
  final service = await _pumpLoaded(
    tester,
    mockUserProfile,
    stubSavedItemRoutes: true,
  );
  expect(service.loadCalls, 1);
  expect(find.text(oldCount), findsOneWidget);

  // Remember this exact State so we can show Back returns to the SAME Profile
  // screen (kept alive under the pushed route), not a freshly built one.
  final profileStateBefore = tester.state<State<ProfileScreen>>(
    find.byType(ProfileScreen),
  );

  // Open the destination. Profile is loaded and idle here (nothing animates
  // forever), so pumpAndSettle is safe and waits for the whole route
  // transition, however long this Flutter version makes it.
  await _tapText(tester, tapLabel);
  await tester.pumpAndSettle();

  expect(find.text(destinationText), findsOneWidget);
  expect(service.loadCalls, 1); // no reload while the destination is open

  final navigator = tester.state<NavigatorState>(find.byType(Navigator));
  expect(navigator.canPop(), isTrue);

  // Back. Popping completes the pushNamed future inside `_open`; one pump lets
  // that continuation run, which starts the reload.
  navigator.pop();
  await tester.pump();

  // The reload is pending, so Profile is on its loading spinner.
  expect(service.loadCalls, 2);
  expect(
    find.byType(CircularProgressIndicator, skipOffstage: false),
    findsOneWidget,
  );

  // Finish the reload as the real service would, then let the reverse route
  // transition finish. pumpAndSettle is safe only now: while the spinner is
  // showing it would time out, and a fixed pump(400 ms) can stop mid-transition
  // because the default page-transition duration depends on the Flutter
  // version.
  service.complete(refreshedProfile);
  await tester.pumpAndSettle();

  // Destination is gone (even offstage) and Profile is the current route again,
  // as the very same State that was kept alive under the pushed route.
  expect(find.text(destinationText, skipOffstage: false), findsNothing);
  expect(navigator.canPop(), isFalse);
  final profileFinder = find.byType(ProfileScreen, skipOffstage: false);
  expect(profileFinder, findsOneWidget);
  expect(ModalRoute.of(tester.element(profileFinder))?.isCurrent, isTrue);
  expect(
    identical(
      tester.state<State<ProfileScreen>>(profileFinder),
      profileStateBefore,
    ),
    isTrue,
  );

  // The refreshed data is on screen.
  expect(find.byType(CircularProgressIndicator), findsNothing);
  expect(find.text('Layla'), findsOneWidget);
  expect(find.text(newCount), findsOneWidget);
  expect(find.text(oldCount), findsNothing);
  expect(service.loadCalls, 2); // exactly one reload, no extra loads
  expect(tester.takeException(), isNull);
}

void main() {
  group('loading', () {
    testWidgets('shows a spinner (and the back button) until data arrives', (
      tester,
    ) async {
      _useScreen(tester, const Size(390, 844));
      final service = FakeProfileService();
      await tester.pumpWidget(
        _app(home: ProfileScreen(profileService: service)),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading your profile'), findsOneWidget);
      expect(find.byTooltip('Back'), findsOneWidget);
      expect(find.text('Layla'), findsNothing);
      expect(service.loadCalls, 1);

      service.complete(mockUserProfile);
      await _settle(tester);

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Layla'), findsOneWidget);
    });
  });

  group('with the sample profile', () {
    testWidgets('shows the profile header', (tester) async {
      await _pumpLoaded(tester, mockUserProfile);

      expect(find.text('Layla'), findsOneWidget);
      expect(find.text('layla@example.com (sample)'), findsOneWidget);
      expect(find.text('Demo'), findsOneWidget);
      expect(find.text('Edit profile'), findsOneWidget);

      // There is no skin preferences section on the profile.
      expect(find.text('Skin preferences'), findsNothing);

      expect(find.text('Settings & Privacy'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows the face analysis, labelled as sample data', (
      tester,
    ) async {
      await _pumpLoaded(tester, mockUserProfile);

      expect(find.text('My face analysis'), findsOneWidget);
      expect(find.text('Sample data, estimates only'), findsOneWidget);
      expect(find.text('Face shape'), findsOneWidget);
      expect(find.text('Oval'), findsOneWidget);
      expect(find.text('Skin tone'), findsOneWidget);
      expect(find.text('Warm medium'), findsOneWidget);
      expect(find.text('Undertone'), findsOneWidget);
      expect(find.text('Warm'), findsOneWidget);

      final swatch = tester.widget<DecoratedBox>(
        find.byKey(SkinToneSwatch.colorKey),
      );
      expect(
        (swatch.decoration as BoxDecoration).color,
        const Color(0xFFD8A17E),
      );
    });

    testWidgets('shows the saved looks and favorite products counts', (
      tester,
    ) async {
      await _pumpLoaded(tester, mockUserProfile);

      expect(find.text('12'), findsOneWidget);
      expect(find.text('Saved looks'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('Favorite products'), findsOneWidget);
    });
  });

  group('shows whatever data it is given (nothing is hard-coded)', () {
    testWidgets('a different, non-sample profile', (tester) async {
      await _pumpLoaded(tester, realisticProfile);

      expect(find.text('Sara'), findsOneWidget);
      expect(find.text('sara@example.com'), findsOneWidget);
      expect(find.text('Demo'), findsNothing);
      expect(find.textContaining('(sample)'), findsNothing);

      expect(find.text('Round'), findsOneWidget);
      expect(find.text('Cool light'), findsOneWidget);
      expect(find.text('Cool'), findsOneWidget);
      expect(find.text('Latest analysis, estimates only'), findsOneWidget);
      expect(find.text('Sample data, estimates only'), findsNothing);

      expect(find.text('3'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('Oval'), findsNothing);
      expect(find.text('Layla'), findsNothing);
    });
  });

  group('missing optional fields', () {
    testWidgets('a profile with only an id still shows safely', (tester) async {
      await _pumpLoaded(tester, minimalProfile);

      expect(find.text('Your profile'), findsOneWidget); // no name
      expect(find.textContaining('@'), findsNothing); // no email
      expect(find.text('Demo'), findsNothing);

      // No analysis yet: an invitation instead of values.
      expect(find.text("You haven't analyzed your face yet."), findsOneWidget);
      expect(find.text('Analyze my face'), findsOneWidget);
      expect(find.text('Oval'), findsNothing);

      // Unavailable counts show a dash, not a made-up number.
      expect(find.text('\u2013'), findsNWidgets(2));
      expect(find.text('Settings & Privacy'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a partly filled analysis says what is not available', (
      tester,
    ) async {
      await _pumpLoaded(
        tester,
        const UserProfile(
          id: 'u',
          latestFaceAnalysis: FaceAnalysisResult(faceShape: 'Oval'),
        ),
      );

      expect(find.text('Oval'), findsOneWidget);
      expect(
        find.text('Not available'),
        findsNWidgets(2),
      ); // skin tone, undertone
      expect(find.byType(SkinToneSwatch), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an avatar address that cannot load falls back safely', (
      tester,
    ) async {
      await _pumpLoaded(
        tester,
        const UserProfile(
          id: 'u',
          name: 'Noor',
          avatarUrl: 'https://example.invalid/avatar.png',
        ),
      );

      expect(find.text('Noor'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('empty and error states', () {
    testWidgets('no profile yet shows an empty state', (tester) async {
      await _pumpLoaded(tester, null);

      expect(find.text('No profile yet'), findsOneWidget);
      expect(find.textContaining("isn't set up yet"), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byTooltip('Back'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a failed load shows a friendly message and Retry', (
      tester,
    ) async {
      _useScreen(tester, const Size(390, 844));
      final service = FakeProfileService();
      await tester.pumpWidget(
        _app(home: ProfileScreen(profileService: service)),
      );

      service.fail();
      await _settle(tester);

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text(ProfileException.defaultMessage), findsOneWidget);
      expect(_retry, findsOneWidget);
      expect(find.text('Layla'), findsNothing);
    });

    testWidgets("the service's own message is shown", (tester) async {
      _useScreen(tester, const Size(390, 844));
      final service = FakeProfileService();
      await tester.pumpWidget(
        _app(home: ProfileScreen(profileService: service)),
      );

      service.fail(const ProfileException('You appear to be offline.'));
      await _settle(tester);

      expect(find.text('You appear to be offline.'), findsOneWidget);
    });

    testWidgets('an unexpected error still shows the friendly message', (
      tester,
    ) async {
      _useScreen(tester, const Size(390, 844));
      final service = FakeProfileService();
      await tester.pumpWidget(
        _app(home: ProfileScreen(profileService: service)),
      );

      service.fail(StateError('boom'));
      await _settle(tester);

      expect(find.text(ProfileException.defaultMessage), findsOneWidget);
      expect(find.textContaining('boom'), findsNothing);
    });

    testWidgets('Retry loads again once and can succeed', (tester) async {
      _useScreen(tester, const Size(390, 844));
      final service = FakeProfileService();
      await tester.pumpWidget(
        _app(home: ProfileScreen(profileService: service)),
      );
      service.fail();
      await _settle(tester);

      await tester.tap(_retry);
      await tester.pump();

      expect(service.loadCalls, 2);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(_retry, findsNothing);

      service.complete(mockUserProfile);
      await _settle(tester);
      expect(find.text('Layla'), findsOneWidget);
      expect(service.loadCalls, 2);
    });

    testWidgets('Retry can fail again and be retried again', (tester) async {
      _useScreen(tester, const Size(390, 844));
      final service = FakeProfileService();
      await tester.pumpWidget(
        _app(home: ProfileScreen(profileService: service)),
      );
      service.fail();
      await _settle(tester);

      await tester.tap(_retry);
      await tester.pump();
      service.fail();
      await _settle(tester);
      expect(_retry, findsOneWidget);

      await tester.tap(_retry);
      await tester.pump();
      expect(service.loadCalls, 3);
    });
  });

  group('loading happens once', () {
    testWidgets('rebuilding does not reload the profile', (tester) async {
      final service = await _pumpLoaded(tester, mockUserProfile);

      await tester.pumpWidget(
        _app(textScale: 1.3, home: ProfileScreen(profileService: service)),
      );
      await tester.pump();

      expect(service.loadCalls, 1);
      expect(find.text('Layla'), findsOneWidget);
    });

    testWidgets('a result arriving after the screen closed is ignored', (
      tester,
    ) async {
      _useScreen(tester, const Size(390, 844));
      final service = FakeProfileService();
      await tester.pumpWidget(
        _app(home: ProfileScreen(profileService: service)),
      );

      await tester.pumpWidget(const SizedBox());
      service.complete(mockUserProfile);
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  group('profile navigation', () {
    testWidgets('Saved looks route opens and Back returns', (tester) async {
      await _expectSavedItemRouteRoundTrip(
        tester,
        tapLabel: 'Saved looks',
        destinationText: 'Saved Looks test destination',
        oldCount: '12',
        newCount: '13',
        refreshedProfile: UserProfile(
          id: 'mock-user',
          name: 'Layla',
          email: 'layla@example.com',
          latestFaceAnalysis: mockUserProfile.latestFaceAnalysis,
          savedLooksCount: 13,
          favoriteProductsCount: 8,
          isMock: true,
        ),
      );
    });

    testWidgets('Favorite products route opens and Back returns', (
      tester,
    ) async {
      await _expectSavedItemRouteRoundTrip(
        tester,
        tapLabel: 'Favorite products',
        destinationText: 'Favorite Products test destination',
        oldCount: '8',
        newCount: '9',
        refreshedProfile: UserProfile(
          id: 'mock-user',
          name: 'Layla',
          email: 'layla@example.com',
          latestFaceAnalysis: mockUserProfile.latestFaceAnalysis,
          savedLooksCount: 12,
          favoriteProductsCount: 9,
          isMock: true,
        ),
      );
    });

    testWidgets(
      'Settings & Privacy opens the settings screen and Back returns',
      (tester) async {
        await _pumpLoaded(tester, mockUserProfile);

        await _tapText(tester, 'Settings & Privacy');
        await tester.pumpAndSettle();

        expect(find.byType(SettingsPrivacyScreen), findsOneWidget);
        expect(find.text('Account settings'), findsOneWidget);
        expect(find.text('Privacy controls'), findsOneWidget);
        expect(find.text('Log out'), findsOneWidget);
        expect(find.text('Coming soon'), findsNWidgets(3));

        await tester.tap(find.byTooltip('Back'));
        await tester.pumpAndSettle();
        expect(find.byType(SettingsPrivacyScreen), findsNothing);
        expect(find.text('Layla'), findsOneWidget);
      },
    );

    testWidgets('nothing on the settings screen pretends to work', (
      tester,
    ) async {
      await _pumpLoaded(tester, mockUserProfile);
      await _tapText(tester, 'Settings & Privacy');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Log out'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(SettingsPrivacyScreen), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
    });

    testWidgets('Edit profile says it is coming soon', (tester) async {
      await _pumpLoaded(tester, mockUserProfile);

      await _tapText(tester, 'Edit profile');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Profile editing is coming soon.'), findsOneWidget);
    });

    testWidgets('"Analyze my face" opens the Face Analysis Guide', (
      tester,
    ) async {
      await _pumpLoaded(tester, minimalProfile);

      await _tapText(tester, 'Analyze my face');
      await tester.pumpAndSettle();

      expect(find.byType(FaceAnalysisGuideScreen), findsOneWidget);
    });
  });

  group('back navigation and the /profile route', () {
    Widget homeThatOpensProfile(FakeProfileService service) => Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ProfileScreen(profileService: service),
            ),
          ),
          child: const Text('Open profile'),
        ),
      ),
    );

    testWidgets('Back returns to the previous screen', (tester) async {
      _useScreen(tester, const Size(390, 844));
      final service = FakeProfileService();
      await tester.pumpWidget(_app(home: homeThatOpensProfile(service)));

      await tester.tap(find.text('Open profile'));
      // Not pumpAndSettle: the loading spinner animates until data arrives.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      service.complete(mockUserProfile);
      await _settle(tester);
      expect(find.text('Layla'), findsOneWidget);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileScreen), findsNothing);
      expect(find.text('Open profile'), findsOneWidget);
    });

    testWidgets('Back is safe when Profile is the first screen', (
      tester,
    ) async {
      await _pumpLoaded(tester, mockUserProfile);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the /profile route shows the injected sample profile', (
      tester,
    ) async {
      _useScreen(tester, const Size(390, 844));
      final service = FakeProfileService();

      await tester.pumpWidget(
        _app(
          routeProfileService: service,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRouter.profile),
                child: const Text('Open profile'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open profile'));
      await tester.pump();
      // Finish the route transition while the profile is still loading.
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(service.loadCalls, 1);

      service.complete(mockUserProfile);
      await _settle(tester);

      expect(find.text('Layla'), findsOneWidget);
      expect(find.text('Demo'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('responsive layout and text scaling', () {
    for (final size in const [Size(320, 480), Size(360, 640), Size(411, 891)]) {
      for (final scale in const [1.0, 1.5, 2.0]) {
        testWidgets(
          'no overflow at ${size.width.toInt()}x${size.height.toInt()}, ${scale}x text',
          (tester) async {
            await _pumpLoaded(
              tester,
              mockUserProfile,
              size: size,
              textScale: scale,
            );
            expect(tester.takeException(), isNull);

            // The whole page can be scrolled to its last item.
            await tester.ensureVisible(find.text('Settings & Privacy'));
            await tester.pump();
            expect(tester.takeException(), isNull);
          },
        );
      }
    }

    testWidgets('the missing-data, empty and error layouts also fit', (
      tester,
    ) async {
      const size = Size(320, 480);
      await _pumpLoaded(tester, minimalProfile, size: size, textScale: 2.0);
      expect(tester.takeException(), isNull);

      await _pumpLoaded(tester, null, size: size, textScale: 2.0);
      expect(tester.takeException(), isNull);

      _useScreen(tester, size);
      await tester.pumpWidget(const SizedBox());
      final service = FakeProfileService();
      await tester.pumpWidget(
        _app(textScale: 2.0, home: ProfileScreen(profileService: service)),
      );
      service.fail();
      await _settle(tester);
      expect(_retry, findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
