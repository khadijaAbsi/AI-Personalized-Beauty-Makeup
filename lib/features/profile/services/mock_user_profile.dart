import '../../face_analysis/services/mock_face_analysis_result.dart';
import '../models/user_profile.dart';

/// Sample profile used until sign-in and the backend exist. It is flagged
/// `isMock: true`, so the Profile screen labels it as a demo. It reuses the
/// existing sample face-analysis result.
///
/// Delete this file together with the mock service when real data is wired up.
const UserProfile mockUserProfile = UserProfile(
  id: 'mock-user',
  name: 'Layla',
  email: 'layla@example.com',
  latestFaceAnalysis: mockFaceAnalysisResult,
  savedLooksCount: 12,
  favoriteProductsCount: 8,
  isMock: true,
);
