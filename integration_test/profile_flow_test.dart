import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// Replace `glowai` with the `name:` in your pubspec.yaml if it differs.
import 'package:glowai/core/routing/app_router.dart';
import 'package:glowai/core/theme/app_theme.dart';
import 'package:glowai/features/profile/screens/profile_screen.dart';
import 'package:glowai/features/profile/services/mock_profile_service.dart';
import 'package:integration_test/integration_test.dart';

/// Walks through the Profile screen on the emulator or a phone with the real
/// theme, fonts and painters:
///
///   loading -> profile -> Saved looks -> back -> Favorite products -> back
///   -> Settings & Privacy -> back -> Edit profile
///
/// Run:  flutter test integration_test/profile_flow_test.dart -d emulator-5554
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('profile screen: data, placeholders, settings, back',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        onGenerateRoute: AppRouter.onGenerateRoute,
        home: ProfileScreen(profileService: MockProfileService()),
      ),
    );

    // Loading, then the sample profile.
    expect(find.text('Loading your profile'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.text('Layla'), findsOneWidget);
    expect(find.text('Demo'), findsOneWidget);
    expect(find.text('Sample data, estimates only'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);

    Future<void> openAndGoBack(String label, String expectedOnNextScreen) async {
      await tester.ensureVisible(find.text(label));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(find.text(expectedOnNextScreen), findsWidgets);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Layla'), findsOneWidget);
    }

    await openAndGoBack('Saved looks', 'Temporary placeholder');
    await openAndGoBack('Favorite products', 'Temporary placeholder');
    await openAndGoBack('Settings & Privacy', 'Coming soon');

    // Edit profile only gives feedback.
    await tester.ensureVisible(find.text('Edit profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit profile'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Profile editing is coming soon.'), findsOneWidget);
  });
}
