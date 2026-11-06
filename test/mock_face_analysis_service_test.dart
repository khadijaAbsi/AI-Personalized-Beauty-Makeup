import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
// Replace `glowai` with the `name:` in your pubspec.yaml if it differs.
import 'package:glowai/features/face_analysis/models/face_analysis_progress.dart';
import 'package:glowai/features/face_analysis/services/mock_face_analysis_service.dart';

import 'helpers/analysis_test_helpers.dart';

void main() {
  group('stage ordering and completion', () {
    // Tiny real durations: quick, and the same logic as the real timings.
    final quick = MockFaceAnalysisService(
      stageDurations: {
        for (final stage in FaceAnalysisStage.values)
          stage: const Duration(milliseconds: 4),
      },
      tick: const Duration(milliseconds: 1),
    );

    test('emits every stage in order, then completes exactly once', () async {
      final events = await quick.analyze(testPhoto).toList();

      // Starts at the first stage with 0% progress.
      expect(events.first.stage, FaceAnalysisStage.detectingFace);
      expect(events.first.progress, 0);
      expect(events.first.status, FaceAnalysisStatus.running);

      // Ends with a single completed event at 100%.
      expect(events.last.isComplete, isTrue);
      expect(events.last.progress, 1);
      expect(events.last.percent, 100);
      expect(events.last.result, isNotNull);
      expect(events.last.result!.isMock, isTrue);
      expect(
        events.where((e) => !e.isComplete).every((e) => e.result == null),
        isTrue,
      );
      expect(events.where((e) => e.isComplete), hasLength(1));
      expect(
        events.where((e) => !e.isComplete).every((e) => e.progress < 1),
        isTrue,
      );

      // Stages never go backwards, and all four appear.
      final indexes = events.map((e) => e.stage.index).toList();
      for (var i = 1; i < indexes.length; i++) {
        expect(indexes[i], greaterThanOrEqualTo(indexes[i - 1]));
      }
      expect(
        events.map((e) => e.stage).toSet(),
        FaceAnalysisStage.values.toSet(),
      );

      // Progress never goes backwards.
      for (var i = 1; i < events.length; i++) {
        expect(
          events[i].progress,
          greaterThanOrEqualTo(events[i - 1].progress),
        );
      }
    });

    test('each call is a separate run', () async {
      final first = await quick.analyze(testPhoto).toList();
      final second = await quick.analyze(testPhoto).toList();
      expect(second.last.isComplete, isTrue);
      expect(second.first.progress, 0);
      expect(first.length, second.length);
    });
  });

  group('default timing (fake clock, no real waiting)', () {
    testWidgets('stages change at 1.5s, 3.5s and 5.5s; finishes at 7s', (
      tester,
    ) async {
      final events = <FaceAnalysisProgress>[];
      final subscription = MockFaceAnalysisService()
          .analyze(testPhoto)
          .listen(events.add);
      // Cleanup that can never hang: start the cancel, don't await its future.
      addTearDown(() => unawaited(subscription.cancel()));

      Future<void> advance(int milliseconds) =>
          tester.pump(Duration(milliseconds: milliseconds));

      await tester.pump();
      expect(events, hasLength(1));
      expect(events.single.stage, FaceAnalysisStage.detectingFace);
      expect(events.single.progress, 0);

      await advance(1490);
      expect(events.last.stage, FaceAnalysisStage.detectingFace);
      await advance(10); // 1.5 s
      expect(events.last.stage, FaceAnalysisStage.estimatingFaceShape);
      expect(events.last.progress, closeTo(1.5 / 7, 0.001));

      await advance(1990);
      expect(events.last.stage, FaceAnalysisStage.estimatingFaceShape);
      await advance(10); // 3.5 s
      expect(events.last.stage, FaceAnalysisStage.estimatingSkinTone);
      expect(events.last.progress, closeTo(3.5 / 7, 0.001));

      await advance(1990);
      expect(events.last.stage, FaceAnalysisStage.estimatingSkinTone);
      await advance(10); // 5.5 s
      expect(events.last.stage, FaceAnalysisStage.preparingRecommendations);
      expect(events.last.progress, closeTo(5.5 / 7, 0.001));

      await advance(1490); // 6.99 s
      expect(events.last.isComplete, isFalse);
      await advance(10); // 7 s
      expect(events.last.isComplete, isTrue);
      expect(events.last.progress, 1);
    });
  });

  group('cancellation and restart (fake clock)', () {
    // IMPORTANT: a testWidgets body runs inside a FakeAsync zone, and
    // `StreamSubscription.cancel()` may return a Future from the real (root)
    // zone. Awaiting such a Future directly makes the test body resume outside
    // the fake clock, and the next `await tester.pump()` then never finishes
    // (the test hangs). Use `tester.runAsync` to await real-zone futures.

    testWidgets('cancelling stops all further events and timers', (
      tester,
    ) async {
      final events = <FaceAnalysisProgress>[];
      final subscription = MockFaceAnalysisService()
          .analyze(testPhoto)
          .listen(events.add);

      await tester.pump(const Duration(milliseconds: 500));
      expect(events, isNotEmpty);

      var cancelCompleted = false;
      await tester.runAsync(() async {
        await subscription.cancel();
        cancelCompleted = true;
      });
      expect(cancelCompleted, isTrue);

      final countAtCancel = events.length;
      await tester.pump(const Duration(seconds: 10));

      expect(events.length, countAtCancel);
      expect(events.any((e) => e.isComplete), isFalse);
      // (A timer left running would make this test fail when it finishes.)
    });

    testWidgets('cancellation takes effect immediately, without awaiting it', (
      tester,
    ) async {
      final events = <FaceAnalysisProgress>[];
      final subscription = MockFaceAnalysisService()
          .analyze(testPhoto)
          .listen(events.add);
      await tester.pump(const Duration(milliseconds: 200));
      final countBefore = events.length;
      expect(countBefore, greaterThan(0));

      // The timer is stopped synchronously inside cancel(); the returned
      // future only reports that this is done.
      unawaited(subscription.cancel());
      await tester.pump(const Duration(seconds: 10));

      expect(events.length, countBefore);
    });

    testWidgets(
      'cancelling right after listening emits nothing and leaves no timer',
      (tester) async {
        final events = <FaceAnalysisProgress>[];
        final subscription = MockFaceAnalysisService()
            .analyze(testPhoto)
            .listen(events.add);

        await tester.runAsync(subscription.cancel);
        await tester.pump(const Duration(seconds: 10));

        expect(events.length, lessThanOrEqualTo(1));
        expect(events.any((e) => e.isComplete), isFalse);
      },
    );

    testWidgets('a cancelled run can be restarted and runs cleanly', (
      tester,
    ) async {
      final service = MockFaceAnalysisService();

      final first = <FaceAnalysisProgress>[];
      final firstSubscription = service.analyze(testPhoto).listen(first.add);
      await tester.pump(const Duration(milliseconds: 700));
      await tester.runAsync(firstSubscription.cancel);
      final firstCount = first.length;

      // Start again with the same service object.
      final second = <FaceAnalysisProgress>[];
      service.analyze(testPhoto).listen(second.add);
      await tester.pump();
      expect(second.single.stage, FaceAnalysisStage.detectingFace);
      expect(second.single.progress, 0);

      await tester.pump(const Duration(seconds: 7));
      expect(second.last.isComplete, isTrue);
      expect(second.last.progress, 1);

      // The cancelled run stayed silent the whole time.
      expect(first.length, firstCount);
    });

    testWidgets('cancelling after the run has finished is harmless', (
      tester,
    ) async {
      final events = <FaceAnalysisProgress>[];
      final subscription = MockFaceAnalysisService()
          .analyze(testPhoto)
          .listen(events.add);
      await tester.pump(const Duration(seconds: 8));
      expect(events.last.isComplete, isTrue);

      await tester.runAsync(subscription.cancel);
      await tester.pump(const Duration(seconds: 1));

      expect(events.last.isComplete, isTrue);
    });
  });

  group('failures', () {
    testWidgets(
      'failFirstAttempts makes early runs fail mid-stage, then works',
      (tester) async {
        final service = MockFaceAnalysisService(failFirstAttempts: 1);

        final events = <FaceAnalysisProgress>[];
        final errors = <Object>[];
        var done = false;
        service
            .analyze(testPhoto)
            .listen(events.add, onError: errors.add, onDone: () => done = true);
        await tester.pump(const Duration(seconds: 8));

        expect(errors, hasLength(1));
        expect(errors.single, isA<FaceAnalysisException>());
        expect(done, isTrue);
        expect(events.last.stage, FaceAnalysisStage.estimatingSkinTone);
        expect(events.any((e) => e.isComplete), isFalse);

        // Second attempt succeeds.
        final retryEvents = <FaceAnalysisProgress>[];
        service.analyze(testPhoto).listen(retryEvents.add);
        await tester.pump(const Duration(seconds: 8));
        expect(retryEvents.last.isComplete, isTrue);
      },
    );

    testWidgets('the failing stage is configurable', (tester) async {
      final service = MockFaceAnalysisService(
        failFirstAttempts: 1,
        failAtStage: FaceAnalysisStage.detectingFace,
      );
      final events = <FaceAnalysisProgress>[];
      final errors = <Object>[];
      service.analyze(testPhoto).listen(events.add, onError: errors.add);
      await tester.pump(const Duration(seconds: 8));

      expect(errors, hasLength(1));
      expect(events.last.stage, FaceAnalysisStage.detectingFace);
    });
  });

  group('FaceAnalysisProgress', () {
    test('a completed update must carry a result', () {
      expect(
        () => FaceAnalysisProgress(
          stage: FaceAnalysisStage.preparingRecommendations,
          progress: 1,
          status: FaceAnalysisStatus.completed,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('percent rounds progress to a whole number', () {
      const progress = FaceAnalysisProgress(
        stage: FaceAnalysisStage.estimatingSkinTone,
        progress: 0.614,
        status: FaceAnalysisStatus.running,
      );
      expect(progress.percent, 61);
      expect(progress.isComplete, isFalse);
    });

    test('FaceAnalysisException has a friendly default message', () {
      expect(
        const FaceAnalysisException().message,
        FaceAnalysisException.defaultMessage,
      );
    });
  });
}
