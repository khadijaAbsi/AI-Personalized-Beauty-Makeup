import 'dart:async';

// Replace `glowai` with the `name:` in your pubspec.yaml if it differs.
import 'package:glowai/features/face_analysis/models/face_analysis_progress.dart';
import 'package:glowai/features/face_analysis/models/face_analysis_result.dart';
import 'package:glowai/features/face_analysis/models/selected_photo.dart';
import 'package:glowai/features/face_analysis/services/face_analysis_service.dart';

/// A photo for tests. The processing screen never reads the file.
const testPhoto = SelectedPhoto(
  path: 'does_not_matter.png',
  source: PhotoSource.gallery,
  format: PhotoFormat.png,
  width: 640,
  height: 800,
  sizeInBytes: 1024 * 1024,
);

/// The result the fake service delivers on completion.
const testResult = FaceAnalysisResult(
  faceShape: 'Oval',
  skinTone: 'Warm medium',
  skinUndertone: 'Warm',
  skinDepth: 'Medium',
  skinToneHex: '#D8A17E',
  isMock: true,
);

/// A service the test drives by hand: no timers, fully deterministic.
class FakeFaceAnalysisService implements FaceAnalysisService {
  final List<StreamController<FaceAnalysisProgress>> _controllers = [];

  /// How many times analysis was started.
  int analyzeCalls = 0;

  /// How many analyses were cancelled by the listener.
  int cancelCount = 0;

  SelectedPhoto? lastPhoto;

  StreamController<FaceAnalysisProgress> get _current => _controllers.last;

  @override
  Stream<FaceAnalysisProgress> analyze(SelectedPhoto photo) {
    analyzeCalls++;
    lastPhoto = photo;
    final controller = StreamController<FaceAnalysisProgress>(
      onCancel: () => cancelCount++,
    );
    _controllers.add(controller);
    return controller.stream;
  }

  void emit(
    FaceAnalysisStage stage,
    double progress, {
    FaceAnalysisStatus status = FaceAnalysisStatus.running,
    FaceAnalysisResult? result,
  }) {
    _current.add(
      FaceAnalysisProgress(
        stage: stage,
        progress: progress,
        status: status,
        result: result,
      ),
    );
  }

  /// Successful completion, carrying [result].
  void complete([FaceAnalysisResult result = testResult]) {
    emit(
      FaceAnalysisStage.preparingRecommendations,
      1,
      status: FaceAnalysisStatus.completed,
      result: result,
    );
  }

  void fail([Object error = const FaceAnalysisException()]) {
    _current.addError(error);
  }

  /// The stream ends (without a completed event).
  void close() => _current.close();
}
