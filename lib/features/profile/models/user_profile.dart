import '../../face_analysis/models/face_analysis_result.dart';

/// Everything the Profile screen shows about the signed-in user.
///
/// Every field except [id] is optional, so a partly filled profile (or one
/// where some data failed to load) still displays safely.
///
/// A Supabase-backed `ProfileService` would build this from the current
/// user's rows only (profile row, latest analysis row, counts), all keyed by
/// `auth.uid()`.
class UserProfile {
  const UserProfile({
    required this.id,
    this.name,
    this.email,
    this.avatarUrl,
    this.latestFaceAnalysis,
    this.savedLooksCount,
    this.favoriteProductsCount,
    this.isMock = false,
  });

  final String id;
  final String? name;
  final String? email;
  final String? avatarUrl;

  /// The user's most recent saved analysis (the existing result model), or
  /// null if they have not analysed their face yet.
  final FaceAnalysisResult? latestFaceAnalysis;

  /// Null when the count is unavailable.
  final int? savedLooksCount;
  final int? favoriteProductsCount;

  /// True for sample data. The UI labels such profiles as a demo.
  final bool isMock;
}
