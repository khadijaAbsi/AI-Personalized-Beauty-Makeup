import 'face_analysis_result.dart';

/// The steps shown to the user, in order.
enum FaceAnalysisStage {
  detectingFace,
  estimatingFaceShape,
  estimatingSkinTone,
  preparingRecommendations,
}

enum FaceAnalysisStatus {
  /// Work is still going; more events will follow.
  running,

  /// Everything is finished. This is always the last event.
  completed,
}

/// One progress update from a [FaceAnalysisService].
class FaceAnalysisProgress {
  const FaceAnalysisProgress({
    required this.stage,
    required this.progress,
    required this.status,
    this.result,
  }) : assert(progress >= 0 && progress <= 1, 'progress must be 0.0 to 1.0'),
       assert(
         status != FaceAnalysisStatus.completed || result != null,
         'a completed update must carry the result',
       );

  /// The stage currently being worked on. Earlier stages are finished.
  final FaceAnalysisStage stage;

  /// Overall progress from 0.0 to 1.0.
  final double progress;

  final FaceAnalysisStatus status;

  /// The outcome. Present on the final (completed) update, null before that.
  final FaceAnalysisResult? result;

  /// Overall progress as a whole percentage (0 to 100).
  int get percent => (progress * 100).round();

  bool get isComplete => status == FaceAnalysisStatus.completed;
}

/// Reported (as a stream error) when analysis fails. [message] is safe to
/// show to users.
class FaceAnalysisException implements Exception {
  const FaceAnalysisException([this.message = defaultMessage]);

  static const String defaultMessage =
      "We couldn't finish analyzing your photo. Please try again.";

  final String message;

  @override
  String toString() => 'FaceAnalysisException: $message';
}
