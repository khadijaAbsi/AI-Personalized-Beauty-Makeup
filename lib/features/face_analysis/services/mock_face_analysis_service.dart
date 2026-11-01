import 'dart:async';

import '../models/face_analysis_progress.dart';
import '../models/face_analysis_result.dart';
import '../models/selected_photo.dart';
import 'face_analysis_service.dart';
import 'mock_face_analysis_result.dart';

/// Frontend-only stand-in that only SIMULATES the stages with timers. It runs
/// no AI and produces no real analysis: only a clearly flagged sample result.
///
/// Time is counted in ticks (not with a stopwatch), so tests that use fake
/// time (`tester.pump(duration)`) control it exactly.
///
/// Every call to [analyze] is an independent run with its own controller,
/// timer and counters, so a cancelled run can never affect the next one.
class MockFaceAnalysisService implements FaceAnalysisService {
  MockFaceAnalysisService({
    this.stageDurations = defaultStageDurations,
    this.tick = const Duration(milliseconds: 50),
    this.failFirstAttempts = 0,
    this.failAtStage = FaceAnalysisStage.estimatingSkinTone,
    this.result = mockFaceAnalysisResult,
  }) : assert(tick > Duration.zero, 'tick must be positive');

  static const Map<FaceAnalysisStage, Duration> defaultStageDurations = {
    FaceAnalysisStage.detectingFace: Duration(milliseconds: 1500),
    FaceAnalysisStage.estimatingFaceShape: Duration(milliseconds: 2000),
    FaceAnalysisStage.estimatingSkinTone: Duration(milliseconds: 2000),
    FaceAnalysisStage.preparingRecommendations: Duration(milliseconds: 1500),
  };

  final Map<FaceAnalysisStage, Duration> stageDurations;

  /// How often progress is reported.
  final Duration tick;

  /// Makes the first N calls to [analyze] fail halfway through
  /// [failAtStage]. Handy for trying the error state and Retry by hand, e.g.
  /// `MockFaceAnalysisService(failFirstAttempts: 1)`.
  final int failFirstAttempts;
  final FaceAnalysisStage failAtStage;

  /// The sample result delivered with the final update.
  final FaceAnalysisResult result;

  int _attempts = 0;

  @override
  Stream<FaceAnalysisProgress> analyze(SelectedPhoto photo) {
    final shouldFail = ++_attempts <= failFirstAttempts;
    final stages = FaceAnalysisStage.values;
    final durations = [
      for (final stage in stages) stageDurations[stage] ?? Duration.zero,
    ];
    final totalMicros =
        durations.fold<int>(0, (sum, d) => sum + d.inMicroseconds);

    late final StreamController<FaceAnalysisProgress> controller;
    Timer? timer;
    var elapsedMicros = 0;

    void stopTimer() {
      timer?.cancel();
      timer = null;
    }

    void complete() {
      stopTimer();
      controller.add(
        FaceAnalysisProgress(
          stage: stages.last,
          progress: 1,
          status: FaceAnalysisStatus.completed,
          result: result,
        ),
      );
      unawaited(controller.close());
    }

    void onTick(Timer activeTimer) {
      // Safety net: never emit once the listener is gone or the stream closed.
      if (controller.isClosed || !controller.hasListener) {
        stopTimer();
        return;
      }

      elapsedMicros += tick.inMicroseconds;
      if (elapsedMicros >= totalMicros) {
        complete();
        return;
      }

      // Which stage are we in, and how far into it?
      var remaining = elapsedMicros;
      var index = 0;
      while (index < stages.length - 1 &&
          remaining >= durations[index].inMicroseconds) {
        remaining -= durations[index].inMicroseconds;
        index++;
      }

      if (shouldFail &&
          stages[index] == failAtStage &&
          remaining >= durations[index].inMicroseconds ~/ 2) {
        stopTimer();
        controller.addError(const FaceAnalysisException());
        unawaited(controller.close());
        return;
      }

      controller.add(
        FaceAnalysisProgress(
          stage: stages[index],
          progress: elapsedMicros / totalMicros,
          status: FaceAnalysisStatus.running,
        ),
      );
    }

    controller = StreamController<FaceAnalysisProgress>(
      onListen: () {
        controller.add(
          FaceAnalysisProgress(
            stage: stages.first,
            progress: 0,
            status: FaceAnalysisStatus.running,
          ),
        );
        if (totalMicros == 0) {
          complete();
          return;
        }
        timer = Timer.periodic(tick, onTick);
      },
      // Deliberately returns nothing. Then `subscription.cancel()` returns
      // Dart's shared, already-completed future, which is safe to await from
      // a tearDown callback or (via `tester.runAsync`) from a test body.
      // Returning a Future created here would belong to whichever zone calls
      // cancel() (e.g. FakeAsync) and can hang an `await` made from another.
      onCancel: stopTimer,
    );
    return controller.stream;
  }
}
