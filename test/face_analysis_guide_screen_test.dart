import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// Replace `glowai` with the `name:` in your pubspec.yaml if it differs.
import 'package:glowai/core/routing/app_router.dart';
import 'package:glowai/features/face_analysis/screens/add_portrait_screen.dart';
import 'package:glowai/features/face_analysis/screens/face_analysis_guide_screen.dart';

void _setScreen(WidgetTester tester, Size logicalSize) {
  tester.view.devicePixelRatio = 3.0;
  tester.view.physicalSize = logicalSize * 3.0;
  addTearDown(tester.view.reset);
}

Widget _app({Widget? home, double textScale = 1.0}) {
  return MaterialApp(
    onGenerateRoute: AppRouter.onGenerateRoute,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: home ?? const FaceAnalysisGuideScreen(),
  );
}

Finder get _continueButton => find.widgetWithText(FilledButton, 'Continue');

void main() {
  testWidgets('shows heading, instructions and privacy info', (tester) async {
    _setScreen(tester, const Size(390, 844));
    await tester.pumpWidget(_app());

    expect(find.text("Let's analyze your face"), findsOneWidget);
    expect(
      find.text('A good photo gives the most accurate estimates.'),
      findsOneWidget,
    );

    expect(find.text('Face the camera straight on'), findsOneWidget);
    expect(find.text('Soft, even natural light'), findsOneWidget);
    expect(find.text('No filters, sunglasses or heavy makeup'), findsOneWidget);
    expect(
      find.text('Keep your facial features clearly visible'),
      findsOneWidget,
    );
    expect(
      find.text('Make sure your full face is visible and in focus'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.check), findsNWidgets(5));

    // The old hair instruction and the demo illustration are gone.
    expect(find.text('Hair pulled back from your face'), findsNothing);
    expect(find.text('Demo guide'), findsNothing);

    expect(find.text('Your privacy'), findsOneWidget);
    expect(
      find.text(
        'Your photo is used only for this analysis. You can delete it anytime in Settings and Privacy.',
      ),
      findsOneWidget,
    );
    expect(_continueButton, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Continue opens the Add Your Portrait destination', (
    tester,
  ) async {
    _setScreen(tester, const Size(390, 844));
    await tester.pumpWidget(_app());

    expect(tester.widget<FilledButton>(_continueButton).onPressed, isNotNull);
    await tester.ensureVisible(_continueButton);
    await tester.pump();
    await tester.tap(_continueButton);
    await tester.pumpAndSettle();

    expect(find.byType(AddPortraitScreen), findsOneWidget);
  });

  testWidgets('Back returns to the previous screen', (tester) async {
    _setScreen(tester, const Size(390, 844));
    await tester.pumpWidget(
      _app(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () =>
                    Navigator.of(context)
                        .pushNamed(AppRouter.faceAnalysisGuide),
                child: const Text('Open guide'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open guide'));
    await tester.pumpAndSettle();
    expect(find.byType(FaceAnalysisGuideScreen), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.byType(FaceAnalysisGuideScreen), findsNothing);
    expect(find.text('Open guide'), findsOneWidget);
  });

  testWidgets('Back is safe when the screen is opened directly', (
    tester,
  ) async {
    _setScreen(tester, const Size(390, 844));
    await tester.pumpWidget(_app());

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.byType(FaceAnalysisGuideScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('small screens and large text do not overflow', () {
    const sizes = [Size(320, 480), Size(360, 640), Size(411, 891)];
    const scales = [1.0, 1.5];

    for (final size in sizes) {
      for (final scale in scales) {
        testWidgets(
          '${size.width.toInt()}x${size.height.toInt()} at ${scale}x text',
          (tester) async {
            _setScreen(tester, size);
            await tester.pumpWidget(_app(textScale: scale));

            // Everything, including Continue, can be scrolled into view.
            await tester.ensureVisible(_continueButton);
            await tester.pump();

            expect(_continueButton, findsOneWidget);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  });
}
