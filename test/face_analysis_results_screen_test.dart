import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// Replace `glowai` with the `name:` in your pubspec.yaml if it differs.
import 'package:glowai/core/routing/app_router.dart';
import 'package:glowai/features/face_analysis/models/face_analysis_result.dart';
import 'package:glowai/features/face_analysis/models/face_analysis_results_arguments.dart';
import 'package:glowai/features/face_analysis/screens/face_analysis_results_screen.dart';
import 'package:glowai/features/face_analysis/services/mock_face_analysis_result.dart';
import 'package:glowai/features/face_analysis/widgets/face_shape_illustration.dart';
import 'package:glowai/features/face_analysis/widgets/portrait_message_card.dart';
import 'package:glowai/features/face_analysis/widgets/skin_tone_swatch.dart';
import 'package:glowai/features/occasion/screens/choose_occasion_placeholder_screen.dart';

import 'helpers/analysis_test_helpers.dart';

Object? _occasionArguments;

Widget _app({
  required Widget home,
  double textScale = 1.0,
}) {
  return MaterialApp(
    onGenerateRoute: (settings) {
      if (settings.name == AppRouter.chooseOccasion) {
        _occasionArguments = settings.arguments;
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

Future<void> _pump(
  WidgetTester tester, {
  FaceAnalysisResult? result = mockFaceAnalysisResult,
  Size size = const Size(390, 844),
  double textScale = 1.0,
}) async {
  tester.view.devicePixelRatio = 3.0;
  tester.view.physicalSize = size * 3.0;
  addTearDown(tester.view.reset);
  _occasionArguments = null;

  await tester.pumpWidget(
    _app(
      textScale: textScale,
      home: FaceAnalysisResultsScreen(result: result, photo: testPhoto),
    ),
  );
}

Finder get _continue => find.widgetWithText(FilledButton, 'Continue');

Future<void> _tapContinue(WidgetTester tester) async {
  await tester.ensureVisible(_continue);
  await tester.pump();
  await tester.tap(_continue);
}

Color _swatchColor(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(find.byKey(SkinToneSwatch.colorKey));
  return (box.decoration as BoxDecoration).color!;
}

void main() {
  group('with the sample result', () {
    testWidgets('shows every value, the sample label and the disclaimer',
        (tester) async {
      await _pump(tester);

      expect(find.text('Your results'), findsOneWidget);
      expect(find.text('Sample data, estimates only'), findsOneWidget);

      expect(find.text('Estimated face shape'), findsOneWidget);
      expect(find.text('Oval'), findsOneWidget);
      expect(find.text('Estimated skin tone'), findsOneWidget);
      expect(find.text('Warm medium'), findsOneWidget);

      expect(find.text('Supported attributes'), findsOneWidget);
      expect(find.text('Undertone: Warm'), findsOneWidget);
      expect(find.text('Depth: Medium'), findsOneWidget);
      expect(find.text('Face shape'), findsOneWidget);
      expect(find.text('Skin tone'), findsOneWidget);

      expect(find.text(FaceAnalysisResultsScreen.disclaimer), findsOneWidget);
      expect(
        FaceAnalysisResultsScreen.disclaimer,
        'Results are estimates and may vary with lighting. They guide '
        'suggestions, not diagnoses.',
      );
      expect(_continue, findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('face shape card shows the value and its illustration',
        (tester) async {
      await _pump(tester);

      final card = find.ancestor(
        of: find.text('Estimated face shape'),
        matching: find.byType(Container),
      );
      expect(card, findsWidgets);
      expect(
        find.descendant(
          of: card.first,
          matching: find.text('Oval'),
        ),
        findsOneWidget,
      );
      expect(find.byType(FaceShapeIllustration), findsOneWidget);
      expect(
        tester.widget<FaceShapeIllustration>(find.byType(FaceShapeIllustration))
            .faceShape,
        'Oval',
      );
    });

    testWidgets('skin tone card shows the value and the #D8A17E swatch',
        (tester) async {
      await _pump(tester);

      expect(find.byType(SkinToneSwatch), findsOneWidget);
      expect(_swatchColor(tester), const Color(0xFFD8A17E));
    });

    testWidgets('the sample label is only shown for mock data',
        (tester) async {
      await _pump(
        tester,
        result: const FaceAnalysisResult(
          faceShape: 'Round',
          skinTone: 'Cool light',
          isMock: false,
        ),
      );

      expect(find.text('Sample data, estimates only'), findsNothing);
      expect(find.text('Estimates only'), findsOneWidget);
      expect(find.text('Round'), findsOneWidget);
    });
  });

  group('missing or invalid data', () {
    testWidgets('missing optional attributes do not crash', (tester) async {
      await _pump(
        tester,
        result: const FaceAnalysisResult(faceShape: 'Oval', isMock: true),
      );

      expect(find.text('Oval'), findsOneWidget);
      // Skin tone is unavailable: says so, and has no swatch.
      expect(find.text('Not available'), findsOneWidget);
      expect(find.byType(SkinToneSwatch), findsNothing);
      // Undertone/depth chips are left out; the rest remain.
      expect(find.textContaining('Undertone'), findsNothing);
      expect(find.textContaining('Depth'), findsNothing);
      expect(find.text('Face shape'), findsOneWidget);
      expect(find.text('Skin tone'), findsOneWidget);
      expect(_continue, findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a result with nothing in it still renders', (tester) async {
      await _pump(tester, result: const FaceAnalysisResult());

      expect(find.text('Not available'), findsNWidgets(2));
      expect(find.byType(FaceShapeIllustration), findsNothing);
      expect(find.byType(SkinToneSwatch), findsNothing);
      expect(find.text('Estimates only'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an invalid color shows no swatch but keeps the name',
        (tester) async {
      await _pump(
        tester,
        result: const FaceAnalysisResult(
          skinTone: 'Warm medium',
          skinToneHex: 'zzzzzz',
        ),
      );

      expect(find.text('Warm medium'), findsOneWidget);
      expect(find.byType(SkinToneSwatch), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an unknown face shape still draws something', (tester) async {
      await _pump(
        tester,
        result: const FaceAnalysisResult(faceShape: 'Hexagonal'),
      );

      expect(find.text('Hexagonal'), findsOneWidget);
      expect(find.byType(FaceShapeIllustration), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('no result at all shows a friendly message and no Continue',
        (tester) async {
      await _pump(tester, result: null);

      expect(find.byType(PortraitMessageCard), findsOneWidget);
      expect(find.textContaining("couldn't load your results"), findsOneWidget);
      expect(_continue, findsNothing);
      expect(find.text('Go back'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('navigation', () {
    Widget homeThatOpensResults() => Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => FaceAnalysisResultsScreen(
                    result: mockFaceAnalysisResult,
                    photo: testPhoto,
                  ),
                ),
              ),
              child: const Text('Open results'),
            ),
          ),
        );

    testWidgets('Back returns to the previous screen', (tester) async {
      tester.view.devicePixelRatio = 3.0;
      tester.view.physicalSize = const Size(390, 844) * 3.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app(home: homeThatOpensResults()));

      await tester.tap(find.text('Open results'));
      await tester.pumpAndSettle();
      expect(find.byType(FaceAnalysisResultsScreen), findsOneWidget);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(find.byType(FaceAnalysisResultsScreen), findsNothing);
      expect(find.text('Open results'), findsOneWidget);
    });

    testWidgets('Back is safe when Results is the first screen',
        (tester) async {
      await _pump(tester);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(find.byType(FaceAnalysisResultsScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Continue opens the Choose Your Occasion placeholder',
        (tester) async {
      await _pump(tester);

      await _tapContinue(tester);
      await tester.pumpAndSettle();

      expect(find.byType(ChooseOccasionPlaceholderScreen), findsOneWidget);
      expect(find.text('Choose Your Occasion'), findsOneWidget);
      expect(find.text('Occasion selection is coming soon.'), findsOneWidget);
    });

    testWidgets('the result and portrait are passed on to the next step',
        (tester) async {
      await _pump(tester);

      await _tapContinue(tester);
      await tester.pumpAndSettle();

      expect(_occasionArguments, isA<FaceAnalysisResultsArguments>());
      final arguments = _occasionArguments! as FaceAnalysisResultsArguments;
      expect(arguments.result, same(mockFaceAnalysisResult));
      expect(arguments.photo, same(testPhoto));
    });

    testWidgets('Back from the placeholder returns to Results',
        (tester) async {
      await _pump(tester);
      await _tapContinue(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(find.byType(ChooseOccasionPlaceholderScreen), findsNothing);
      expect(find.byType(FaceAnalysisResultsScreen), findsOneWidget);
      expect(find.text('Oval'), findsOneWidget);
    });

    testWidgets('tapping Continue twice quickly opens one screen',
        (tester) async {
      await _pump(tester);
      await tester.ensureVisible(_continue);
      await tester.pump();

      await tester.tap(_continue);
      await tester.tap(_continue, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byType(ChooseOccasionPlaceholderScreen), findsOneWidget);

      // One Back is enough to get back, so only one screen was pushed.
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.byType(ChooseOccasionPlaceholderScreen), findsNothing);
      expect(find.byType(FaceAnalysisResultsScreen), findsOneWidget);
    });

    testWidgets('Continue works again after coming back', (tester) async {
      await _pump(tester);
      await _tapContinue(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      await _tapContinue(tester);
      await tester.pumpAndSettle();

      expect(find.byType(ChooseOccasionPlaceholderScreen), findsOneWidget);
    });

    testWidgets('rebuilding Results keeps it showing the same result',
        (tester) async {
      await _pump(tester);
      await tester.pumpWidget(
        _app(
          textScale: 1.3,
          home: FaceAnalysisResultsScreen(
            result: mockFaceAnalysisResult,
            photo: testPhoto,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Oval'), findsOneWidget);
      expect(find.text('Warm medium'), findsOneWidget);
    });
  });

  group('responsive layout and text scaling', () {
    for (final size in const [Size(320, 480), Size(360, 640), Size(411, 891)]) {
      for (final scale in const [1.0, 1.5, 2.0]) {
        testWidgets(
          'no overflow at ${size.width.toInt()}x${size.height.toInt()}, ${scale}x text',
          (tester) async {
            await _pump(tester, size: size, textScale: scale);
            expect(tester.takeException(), isNull);

            // Everything, including Continue, can be scrolled into view.
            await tester.ensureVisible(_continue);
            await tester.pump();
            expect(tester.takeException(), isNull);
            expect(_continue, findsOneWidget);
          },
        );
      }
    }

    testWidgets('the missing-data layouts also fit small screens',
        (tester) async {
      await _pump(
        tester,
        result: const FaceAnalysisResult(),
        size: const Size(320, 480),
        textScale: 2.0,
      );
      expect(tester.takeException(), isNull);

      await _pump(
        tester,
        result: null,
        size: const Size(320, 480),
        textScale: 2.0,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
