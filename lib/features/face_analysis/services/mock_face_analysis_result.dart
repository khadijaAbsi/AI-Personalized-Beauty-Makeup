import '../models/face_analysis_result.dart';

/// Sample result used while the backend is not ready. It is flagged
/// `isMock: true`, so the Results screen labels it as sample data.
///
/// Used by `MockFaceAnalysisService`. Delete this file together with the mock
/// service once the FastAPI backend returns real results.
const FaceAnalysisResult mockFaceAnalysisResult = FaceAnalysisResult(
  faceShape: 'Oval',
  skinTone: 'Warm medium',
  skinUndertone: 'Warm',
  skinDepth: 'Medium',
  skinToneHex: '#D8A17E',
  isMock: true,
);
