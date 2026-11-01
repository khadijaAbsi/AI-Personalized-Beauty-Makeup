import 'face_analysis_result.dart';
import 'selected_photo.dart';

/// Route arguments for the Results screen (and passed on to later steps).
/// Keeps the validated portrait alongside the result so later screens can use
/// both without another lookup.
class FaceAnalysisResultsArguments {
  const FaceAnalysisResultsArguments({required this.result, this.photo});

  final FaceAnalysisResult result;
  final SelectedPhoto? photo;
}
