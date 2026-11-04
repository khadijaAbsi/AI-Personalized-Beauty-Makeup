import '../../face_analysis/models/face_analysis_result.dart';

/// Represents the profile of the currently signed-in GlowAI user.
///
/// The account information can come from Supabase Auth.
///
/// Other information, such as face analysis and saved looks,
/// will be connected to the database separately.
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

  /// Supabase Auth user ID.
  final String id;

  /// Full name entered during registration.
  final String? name;

  /// Email address of the authenticated user.
  final String? email;

  /// Optional profile avatar URL.
  final String? avatarUrl;

  /// Latest face analysis, if available.
  final FaceAnalysisResult? latestFaceAnalysis;

  /// Number of saved looks, if available.
  final int? savedLooksCount;

  /// Number of favorite products, if available.
  final int? favoriteProductsCount;

  /// Indicates whether this is sample/demo data.
  final bool isMock;
}
