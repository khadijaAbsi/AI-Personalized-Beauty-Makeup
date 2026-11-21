import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// Replace `glowai` with the `name:` in your pubspec.yaml if it differs.
import 'package:glowai/core/routing/app_router.dart';
import 'package:glowai/core/theme/app_theme.dart';
import 'package:glowai/features/face_analysis/screens/add_portrait_screen.dart';
import 'package:glowai/features/face_analysis/services/camera_service.dart';
import 'package:integration_test/integration_test.dart';

import '../test/helpers/face_test_helpers.dart';

/// Runs the real flow on the emulator or a phone, with the real theme,
/// fonts, painters and timers (the mock analysis takes about 7 real seconds):
///
///   Add Your Portrait -> Processing -> Results -> Choose Your Occasion
///
/// Only the gallery and camera are faked (so no one has to pick a photo by
/// hand); the photo is a real image file created on the device.
///
/// Run:  flutter test integration_test/face_analysis_flow_test.dart -d emulator-5554
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('portrait -> processing -> results -> occasion -> back', (
    tester,
  ) async {
    final images = TestImages();
    addTearDown(images.dispose);
    final photoPath = images.png('portrait.png', width: 800, height: 1000);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        onGenerateRoute: AppRouter.onGenerateRoute,
        home: AddPortraitScreen(
          galleryPicker: FakeGalleryPicker([photoPath]),
          cameraPermissionService: FakeCameraPermissionService(
            CameraPermissionStatus.granted,
          ),
          cameraService: FakeCameraService(capturePath: photoPath),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Choose a photo; the real validation runs on the device.
    await tester.tap(find.text('Choose from Gallery'));
    await tester.pumpAndSettle();
    expect(find.text('Continue'), findsOneWidget);

    // 2. Continue -> processing runs by itself, then Results appears.
    await tester.tap(find.text('Continue'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Analyzing your features'), findsOneWidget);

    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 40),
    );

    // 3. Results, clearly marked as sample data.
    expect(find.text('Your results'), findsOneWidget);
    expect(find.text('Sample data, estimates only'), findsOneWidget);
    expect(find.text('Oval'), findsOneWidget);
    expect(find.text('Warm medium'), findsOneWidget);

    // 4. Continue -> the temporary occasion screen, and back again.
    await tester.ensureVisible(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Choose Your Occasion'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Your results'), findsOneWidget);
  });
}
