import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// Replace `glowai` with the `name:` in your pubspec.yaml if it differs.
import 'package:glowai/core/routing/app_router.dart';
import 'package:glowai/features/face_analysis/models/face_analysis_progress.dart';
import 'package:glowai/features/face_analysis/screens/face_analysis_processing_screen.dart';
import 'package:glowai/features/face_analysis/screens/face_analysis_results_screen.dart';
import 'package:glowai/features/face_analysis/services/mock_face_analysis_service.dart';
import 'package:glowai/features/face_analysis/widgets/analysis_avatar.dart';
import 'package:glowai/features/face_analysis/widgets/analysis_progress_bar.dart';
import 'package:glowai/features/face_analysis/widgets/analysis_stage_list.dart';

import 'helpers/analysis_test_helpers.dart';

Widget _app({
  required Widget home,
  double textScale = 1.0,
}) {
  return MaterialApp(
    onGenerateRoute: AppRouter.onGenerateRoute,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: home,
  );
}

Future<FakeFaceAnalysisService> _pump(
  WidgetTester tester, {
  FakeFaceAnalysisService? service,
  Size size = const Size(390, 844),
  double textScale = 1.0,
}) async {
  tester.view.devicePixelRatio = 3.0;
  tester.view.physicalSize = size * 3.0;
  addTearDown(tester.view.reset);

  final fake = service ?? FakeFaceAnalysisService();
  await tester.pumpWidget(
    _app(
      textScale: textScale,
      home: FaceAnalysisProcessingScreen(
        photo: testPhoto,
        analysisService: fake,
      ),
    ),
  );
  return fake;
}

Finder _stage(FaceAnalysisStage stage, AnalysisStageState state) =>
    find.byKey(ValueKey('stage-${stage.name}-${state.name}'));

double _barValue(WidgetTester tester) =>
    tester.widget<AnalysisProgressBar>(find.byType(AnalysisProgressBar)).value;

double _ringValue(WidgetTester tester) =>
    tester.widget<AnalysisAvatar>(find.byType(AnalysisAvatar)).progress;

FontWeight? _weightOf(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.fontWeight;

Finder get _retry => find.widgetWithText(FilledButton, 'Retry');

/// The service's events are delivered in a microtask, and the frame they ask
/// for is built by the NEXT pump. So after emitting an event, pump twice.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

/// Retry sits below the card and can be off screen in the (tall-text) test
/// font, so scroll to it before tapping.
Future<void> _tapRetry(WidgetTester tester) async {
  await tester.ensureVisible(_retry);
  await tester.pump();
  await tester.tap(_retry);
}

void main() {
  group('initial state', () {
    testWidgets('shows 0%, the first stage active and the rest waiting',
        (tester) async {
      final service = await _pump(tester);

      expect(find.text('Analyzing your features'), findsOneWidget);
      for (final label in [
        'Detecting your face',
        'Estimating face shape',
        'Estimating skin tone',
        'Preparing recommendations',
      ]) {
        expect(find.text(label), findsOneWidget);
      }

      expect(_stage(FaceAnalysisStage.detectingFace, AnalysisStageState.active),
          findsOneWidget);
      expect(
          _stage(FaceAnalysisStage.estimatingFaceShape,
              AnalysisStageState.upcoming),
          findsOneWidget);
      expect(_barValue(tester), 0);
      expect(_ringValue(tester), 0);
      expect(_weightOf(tester, 'Detecting your face'), FontWeight.w700);

      // Analysis started exactly once, with the selected photo.
      expect(service.analyzeCalls, 1);
      expect(service.lastPhoto, same(testPhoto));
      expect(find.text('Retry'), findsNothing);
    });
  });

  group('active state', () {
    testWidgets('follows the events: done, active (bold) and waiting',
        (tester) async {
      final service = await _pump(tester);

      service.emit(FaceAnalysisStage.estimatingSkinTone, 0.6);
      await _settle(tester);
      await tester.pump(const Duration(milliseconds: 400));

      expect(_stage(FaceAnalysisStage.detectingFace, AnalysisStageState.done),
          findsOneWidget);
      expect(
          _stage(FaceAnalysisStage.estimatingFaceShape, AnalysisStageState.done),
          findsOneWidget);
      expect(
          _stage(FaceAnalysisStage.estimatingSkinTone, AnalysisStageState.active),
          findsOneWidget);
      expect(
          _stage(FaceAnalysisStage.preparingRecommendations,
              AnalysisStageState.upcoming),
          findsOneWidget);

      expect(find.byIcon(Icons.check), findsNWidgets(2));
      expect(_weightOf(tester, 'Estimating skin tone'), FontWeight.w700);
      expect(_weightOf(tester, 'Preparing recommendations'), isNot(FontWeight.w700));
      expect(_barValue(tester), 0.6);
      expect(_ringValue(tester), 0.6);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('the bar and ring only ever follow the service',
        (tester) async {
      final service = await _pump(tester);

      // Time passing without events changes nothing.
      await tester.pump(const Duration(seconds: 5));
      expect(_barValue(tester), 0);

      service.emit(FaceAnalysisStage.detectingFace, 0.1);
      await _settle(tester);
      expect(_barValue(tester), 0.1);

      service.emit(FaceAnalysisStage.estimatingFaceShape, 0.35);
      await _settle(tester);
      expect(_barValue(tester), 0.35);
      expect(
          _stage(FaceAnalysisStage.estimatingFaceShape, AnalysisStageState.active),
          findsOneWidget);
    });

    testWidgets('the layout does not move as progress changes',
        (tester) async {
      final service = await _pump(tester);
      final heading = find.text('Analyzing your features');
      final bar = find.byType(AnalysisProgressBar);
      final card = find.byType(AnalysisStageList);

      final before = [
        tester.getTopLeft(heading),
        tester.getTopLeft(bar),
        tester.getRect(card),
      ];

      service.emit(FaceAnalysisStage.estimatingSkinTone, 0.6);
      await _settle(tester);
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.getTopLeft(heading), before[0]);
      expect(tester.getTopLeft(bar), before[1]);
      expect(tester.getRect(card), before[2]);
    });

    testWidgets('does not start again when the screen rebuilds',
        (tester) async {
      final service = await _pump(tester);
      service.emit(FaceAnalysisStage.estimatingFaceShape, 0.4);
      await _settle(tester);

      // Rebuild with different text scales (same widget, same State).
      await tester.pumpWidget(
        _app(
          textScale: 1.3,
          home: FaceAnalysisProcessingScreen(
            photo: testPhoto,
            analysisService: service,
          ),
        ),
      );
      await tester.pump();

      expect(service.analyzeCalls, 1);
      expect(_barValue(tester), 0.4);
    });
  });

  group('completed state', () {
    testWidgets('shows 100%, then opens results with the same photo',
        (tester) async {
      final service = await _pump(tester);

      service.emit(FaceAnalysisStage.preparingRecommendations, 0.9);
      await _settle(tester);
      service.complete();
      await _settle(tester);
      await tester.pump(const Duration(milliseconds: 400));

      // 100%, every stage checked, still on this screen for a moment.
      expect(_barValue(tester), 1);
      expect(_ringValue(tester), 1);
      expect(find.byIcon(Icons.check), findsNWidgets(4));
      expect(find.byType(FaceAnalysisResultsScreen), findsNothing);

      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 500));

      final results = tester.widget<FaceAnalysisResultsScreen>(
        find.byType(FaceAnalysisResultsScreen),
      );
      expect(results.photo, same(testPhoto));
      expect(results.result, same(testResult));
      expect(find.byType(FaceAnalysisProcessingScreen), findsNothing);

      // Showing Results never starts another analysis.
      await tester.pump(const Duration(seconds: 3));
      expect(service.analyzeCalls, 1);
    });

    testWidgets('a repeated completed update still navigates only once',
        (tester) async {
      final service = await _pump(tester);
      service.complete();
      await _settle(tester);
      service.complete();
      await _settle(tester);
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(FaceAnalysisResultsScreen), findsOneWidget);
      expect(tester.takeException(), isNull);

      expect(find.byType(FaceAnalysisProcessingScreen), findsNothing);
    });

    testWidgets('a running update (not completed) never opens Results',
        (tester) async {
      final service = await _pump(tester);
      service.emit(FaceAnalysisStage.preparingRecommendations, 0.99);
      await _settle(tester);
      await tester.pump(const Duration(seconds: 5));

      expect(find.byType(FaceAnalysisResultsScreen), findsNothing);
      expect(find.byType(FaceAnalysisProcessingScreen), findsOneWidget);
    });

    testWidgets('only one navigation happens', (tester) async {
      final service = await _pump(tester);
      service.complete();
      await _settle(tester);
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(FaceAnalysisResultsScreen), findsOneWidget);
    });
  });

  group('failed state', () {
    testWidgets('shows a friendly message and Retry, and does not navigate',
        (tester) async {
      final service = await _pump(tester);
      service.emit(FaceAnalysisStage.estimatingSkinTone, 0.55);
      await _settle(tester);

      service.fail();
      await _settle(tester);

      expect(find.text(FaceAnalysisException.defaultMessage), findsOneWidget);
      expect(_retry, findsOneWidget);
      expect(find.text('Choose a different photo'), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
      expect(find.byType(FaceAnalysisResultsScreen), findsNothing);
      // Progress stays where it stopped.
      expect(_barValue(tester), 0.55);
    });

    testWidgets('a custom message from the service is shown', (tester) async {
      final service = await _pump(tester);
      service.fail(const FaceAnalysisException('The server is busy.'));
      await _settle(tester);

      expect(find.text('The server is busy.'), findsOneWidget);
    });

    testWidgets('an unexpected error type still shows the friendly message',
        (tester) async {
      final service = await _pump(tester);
      service.fail(StateError('boom'));
      await _settle(tester);

      expect(find.text(FaceAnalysisException.defaultMessage), findsOneWidget);
      expect(find.textContaining('boom'), findsNothing);
    });

    testWidgets('a stream that ends without completing counts as a failure',
        (tester) async {
      final service = await _pump(tester);
      service.emit(FaceAnalysisStage.detectingFace, 0.2);
      await _settle(tester);
      service.close();
      await _settle(tester);

      expect(_retry, findsOneWidget);
    });

    testWidgets('Retry starts a fresh analysis once and can succeed',
        (tester) async {
      final service = await _pump(tester);
      service.emit(FaceAnalysisStage.estimatingSkinTone, 0.55);
      await _settle(tester);
      service.fail();
      await _settle(tester);

      await _tapRetry(tester);
      await tester.pump();

      expect(service.analyzeCalls, 2);
      expect(find.text(FaceAnalysisException.defaultMessage), findsNothing);
      expect(_retry, findsNothing);
      // Back at the start.
      expect(_barValue(tester), 0);
      expect(_stage(FaceAnalysisStage.detectingFace, AnalysisStageState.active),
          findsOneWidget);

      // Rebuilds don't start a third run.
      await tester.pump(const Duration(seconds: 1));
      expect(service.analyzeCalls, 2);

      service.emit(FaceAnalysisStage.estimatingFaceShape, 0.3);
      await _settle(tester);
      expect(_barValue(tester), 0.3);

      service.complete();
      await _settle(tester);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(FaceAnalysisResultsScreen), findsOneWidget);
    });

    testWidgets('Retry can fail again and be retried again', (tester) async {
      final service = await _pump(tester);
      service.fail();
      await _settle(tester);
      await _tapRetry(tester);
      await tester.pump();
      service.fail();
      await _settle(tester);

      expect(_retry, findsOneWidget);
      await _tapRetry(tester);
      await tester.pump();
      expect(service.analyzeCalls, 3);
    });
  });

  group('cancellation and disposal', () {
    testWidgets('leaving the screen cancels the analysis', (tester) async {
      final service = FakeFaceAnalysisService();
      await tester.pumpWidget(
        _app(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => FaceAnalysisProcessingScreen(
                      photo: testPhoto,
                      analysisService: service,
                    ),
                  ),
                ),
                child: const Text('Start'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();
      expect(service.analyzeCalls, 1);
      expect(service.cancelCount, 0);

      // System back button.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(service.cancelCount, 1);
      expect(find.text('Start'), findsOneWidget);
    });

    testWidgets('disposing cancels the subscription', (tester) async {
      final service = await _pump(tester);
      service.emit(FaceAnalysisStage.detectingFace, 0.3);
      await _settle(tester);

      await tester.pumpWidget(const SizedBox());

      expect(service.cancelCount, 1);
    });

    testWidgets('disposing during the 100% pause cancels the pending move on',
        (tester) async {
      final service = await _pump(tester);
      service.complete();
      await _settle(tester);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));

      // Nothing navigated or threw, and no timer is left (the test would fail).
      expect(tester.takeException(), isNull);
      expect(find.byType(FaceAnalysisResultsScreen), findsNothing);
    });

    testWidgets('disposing the mock service run leaves no timers behind',
        (tester) async {
      tester.view.devicePixelRatio = 3.0;
      tester.view.physicalSize = const Size(390, 844) * 3.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _app(home: FaceAnalysisProcessingScreen(photo: testPhoto)),
      );
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpWidget(const SizedBox());

      expect(tester.takeException(), isNull);
    });
  });

  group('with the mock service (fake clock)', () {
    testWidgets('runs through all four stages in about 7 seconds',
        (tester) async {
      tester.view.devicePixelRatio = 3.0;
      tester.view.physicalSize = const Size(390, 844) * 3.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _app(
          home: FaceAnalysisProcessingScreen(
            photo: testPhoto,
            analysisService: MockFaceAnalysisService(),
          ),
        ),
      );
      expect(_stage(FaceAnalysisStage.detectingFace, AnalysisStageState.active),
          findsOneWidget);

      await tester.pump(const Duration(milliseconds: 1600)); // 1.6 s
      expect(_stage(FaceAnalysisStage.detectingFace, AnalysisStageState.done),
          findsOneWidget);
      expect(
          _stage(FaceAnalysisStage.estimatingFaceShape, AnalysisStageState.active),
          findsOneWidget);

      await tester.pump(const Duration(milliseconds: 2000)); // 3.6 s
      expect(
          _stage(FaceAnalysisStage.estimatingSkinTone, AnalysisStageState.active),
          findsOneWidget);

      await tester.pump(const Duration(milliseconds: 2000)); // 5.6 s
      expect(
          _stage(FaceAnalysisStage.preparingRecommendations,
              AnalysisStageState.active),
          findsOneWidget);
      expect(_barValue(tester), closeTo(5.6 / 7, 0.01));

      await tester.pump(const Duration(milliseconds: 1500)); // 7.1 s
      expect(_barValue(tester), 1);
      expect(find.byIcon(Icons.check), findsNWidgets(4));
      expect(find.byType(FaceAnalysisResultsScreen), findsNothing);

      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(FaceAnalysisResultsScreen), findsOneWidget);

      // The sample result flows through to the screen, labelled as a sample.
      expect(find.text('Your results'), findsOneWidget);
      expect(find.text('Sample data, estimates only'), findsOneWidget);
      expect(find.text('Oval'), findsOneWidget);
      expect(find.text('Warm medium'), findsOneWidget);
    });

    testWidgets('failure injection, Retry, then success', (tester) async {
      tester.view.devicePixelRatio = 3.0;
      tester.view.physicalSize = const Size(390, 844) * 3.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _app(
          home: FaceAnalysisProcessingScreen(
            photo: testPhoto,
            analysisService: MockFaceAnalysisService(failFirstAttempts: 1),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 5)); // fails around 4.5 s
      expect(_retry, findsOneWidget);

      await _tapRetry(tester);
      await tester.pump();
      expect(_retry, findsNothing);

      await tester.pump(const Duration(milliseconds: 7100));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(FaceAnalysisResultsScreen), findsOneWidget);
    });
  });

  group('small screens and large text', () {
    for (final size in const [Size(320, 480), Size(360, 640), Size(411, 891)]) {
      for (final scale in const [1.0, 1.5, 2.0]) {
        testWidgets(
          'no overflow at ${size.width.toInt()}x${size.height.toInt()}, ${scale}x text',
          (tester) async {
            final service =
                await _pump(tester, size: size, textScale: scale);
            expect(tester.takeException(), isNull);

            service.emit(FaceAnalysisStage.estimatingSkinTone, 0.6);
            await _settle(tester);
            expect(tester.takeException(), isNull);

            service.fail();
            await _settle(tester);
            await tester.ensureVisible(_retry);
            await tester.pump();
            expect(_retry, findsOneWidget);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  });
}
