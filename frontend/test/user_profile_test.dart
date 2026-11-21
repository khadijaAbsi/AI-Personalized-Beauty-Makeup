import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
// Replace `glowai` with the `name:` in your pubspec.yaml if it differs.
import 'package:glowai/features/face_analysis/services/mock_face_analysis_result.dart';
// import 'package:glowai/features/profile/models/user_profile.dart';
import 'package:glowai/features/profile/services/mock_profile_service.dart';
import 'package:glowai/features/profile/services/mock_user_profile.dart';
import 'package:glowai/features/profile/services/profile_service.dart';

void main() {
  group('mock profile', () {
    test('has the sample values and is flagged as mock', () {
      expect(mockUserProfile.name, 'Layla');
      expect(mockUserProfile.email, 'layla@example.com');
      expect(mockUserProfile.savedLooksCount, 12);
      expect(mockUserProfile.favoriteProductsCount, 8);
      expect(mockUserProfile.isMock, isTrue);
    });

    test('reuses the existing face analysis model and sample result', () {
      expect(mockUserProfile.latestFaceAnalysis, same(mockFaceAnalysisResult));
    });
  });

  group('MockProfileService', () {
    test('returns the sample profile', () async {
      final service = MockProfileService(delay: Duration.zero);
      expect(await service.loadProfile(), same(mockUserProfile));
    });

    test('profile: null means "no profile yet"', () async {
      final service = MockProfileService(profile: null, delay: Duration.zero);
      expect(await service.loadProfile(), isNull);
    });

    test('failFirstAttempts fails early loads, then succeeds', () async {
      final service = MockProfileService(
        delay: Duration.zero,
        failFirstAttempts: 2,
      );
      await expectLater(
        service.loadProfile(),
        throwsA(isA<ProfileException>()),
      );
      await expectLater(
        service.loadProfile(),
        throwsA(isA<ProfileException>()),
      );
      expect(await service.loadProfile(), same(mockUserProfile));
    });

    testWidgets('takes its simulated delay (fake clock)', (tester) async {
      var done = false;
      unawaited(MockProfileService().loadProfile().then((_) => done = true));

      await tester.pump(const Duration(milliseconds: 599));
      expect(done, isFalse);
      await tester.pump(const Duration(milliseconds: 1));
      expect(done, isTrue);
    });
  });

  test('ProfileException has a friendly default message', () {
    expect(const ProfileException().message, ProfileException.defaultMessage);
  });
}
