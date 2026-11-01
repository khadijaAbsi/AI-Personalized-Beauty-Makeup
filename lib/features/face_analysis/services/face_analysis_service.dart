import '../models/face_analysis_progress.dart';
import '../models/selected_photo.dart';

/// Analyses a validated portrait and reports progress as it goes.
///
/// Contract:
/// - [analyze] returns a single-subscription stream. Work starts when it is
///   listened to.
/// - It emits [FaceAnalysisProgress] events with non-decreasing progress.
/// - The last event has `status == completed` and `progress == 1.0` and
///   carries the [FaceAnalysisResult], then the stream closes. Results are
///   only ever shown after such an event.
/// - A failure is reported as a stream error (preferably a
///   [FaceAnalysisException]) and the stream closes.
/// - Cancelling the subscription must stop all work (timers, HTTP requests).
///
/// To use the FastAPI backend later, write `FastApiFaceAnalysisService
/// implements FaceAnalysisService` and pass it to `FaceAnalysisProcessingScreen`
/// (or make it the default there). The screen does not need to change.
abstract interface class FaceAnalysisService {
  Stream<FaceAnalysisProgress> analyze(SelectedPhoto photo);
}
