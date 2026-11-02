import 'dart:async';

// Replace `glowai` with the `name:` in your pubspec.yaml if it differs.
import 'package:glowai/features/face_analysis/models/face_analysis_result.dart';
import 'package:glowai/features/profile/models/user_profile.dart';
import 'package:glowai/features/profile/services/profile_service.dart';

/// A profile with only the required id: every optional field is missing.
const minimalProfile = UserProfile(id: 'minimal-user');

/// A non-mock profile with a different analysis, to check nothing is
/// hard-coded to the sample values.
const realisticProfile = UserProfile(
  id: 'real-user',
  name: 'Sara',
  email: 'sara@example.com',
  latestFaceAnalysis: FaceAnalysisResult(
    faceShape: 'Round',
    skinTone: 'Cool light',
    skinUndertone: 'Cool',
    skinToneHex: '#F1C9B0',
  ),
  savedLooksCount: 3,
  favoriteProductsCount: 0,
);

/// A service the test controls by hand. Each load stays pending until the
/// test completes it, so loading, empty, error and success are all easy to
/// show. No timers are involved.
class FakeProfileService implements ProfileService {
  final List<Completer<UserProfile?>> _loads = [];

  /// How many times the screen asked for the profile.
  int get loadCalls => _loads.length;

  @override
  Future<UserProfile?> loadProfile() {
    final completer = Completer<UserProfile?>();
    _loads.add(completer);
    return completer.future;
  }

  /// Finishes the latest load. Pass null for "no profile yet".
  void complete(UserProfile? profile) => _loads.last.complete(profile);

  void fail([Object error = const ProfileException()]) =>
      _loads.last.completeError(error);
}
