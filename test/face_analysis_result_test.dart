import 'package:flutter_test/flutter_test.dart';
// Replace `glowai` with the `name:` in your pubspec.yaml if it differs.
import 'package:glowai/features/face_analysis/models/face_analysis_result.dart';
import 'package:glowai/features/face_analysis/services/mock_face_analysis_result.dart';

void main() {
  group('mock result', () {
    test('has the agreed sample values and is flagged as mock', () {
      expect(mockFaceAnalysisResult.faceShape, 'Oval');
      expect(mockFaceAnalysisResult.skinTone, 'Warm medium');
      expect(mockFaceAnalysisResult.skinUndertone, 'Warm');
      expect(mockFaceAnalysisResult.skinDepth, 'Medium');
      expect(mockFaceAnalysisResult.skinToneHex, '#D8A17E');
      expect(mockFaceAnalysisResult.isMock, isTrue);
    });

    test('its color is #D8A17E', () {
      expect(mockFaceAnalysisResult.skinToneArgb, 0xFFD8A17E);
    });
  });

  group('FaceAnalysisResult.fromJson (FastAPI-style response)', () {
    test('reads every field', () {
      final result = FaceAnalysisResult.fromJson({
        'face_shape': 'Round',
        'skin_tone': 'Cool light',
        'skin_undertone': 'Cool',
        'skin_depth': 'Light',
        'skin_tone_hex': '#f1c9b0',
        'is_mock': false,
      });
      expect(result.faceShape, 'Round');
      expect(result.skinTone, 'Cool light');
      expect(result.skinUndertone, 'Cool');
      expect(result.skinDepth, 'Light');
      expect(result.skinToneHex, '#F1C9B0'); // normalised
      expect(result.skinToneArgb, 0xFFF1C9B0);
      expect(result.isMock, isFalse);
    });

    test('is not a mock unless the response says so', () {
      expect(FaceAnalysisResult.fromJson(const {}).isMock, isFalse);
    });

    test('missing keys become null', () {
      final result = FaceAnalysisResult.fromJson({'face_shape': 'Oval'});
      expect(result.faceShape, 'Oval');
      expect(result.skinTone, isNull);
      expect(result.skinUndertone, isNull);
      expect(result.skinDepth, isNull);
      expect(result.skinToneHex, isNull);
      expect(result.skinToneArgb, isNull);
    });

    test('wrong types, blanks and bad colors become null instead of throwing',
        () {
      final result = FaceAnalysisResult.fromJson({
        'face_shape': 42,
        'skin_tone': '   ',
        'skin_undertone': null,
        'skin_depth': ['Medium'],
        'skin_tone_hex': 'not-a-color',
        'is_mock': 'yes',
        'unexpected_extra_key': true,
      });
      expect(result.faceShape, isNull);
      expect(result.skinTone, isNull);
      expect(result.skinUndertone, isNull);
      expect(result.skinDepth, isNull);
      expect(result.skinToneHex, isNull);
      expect(result.skinToneArgb, isNull);
      expect(result.isMock, isFalse);
    });

    test('accepts a color without the leading #', () {
      expect(
        FaceAnalysisResult.fromJson({'skin_tone_hex': 'D8A17E'}).skinToneHex,
        '#D8A17E',
      );
    });

    test('toJson and fromJson round-trip', () {
      final copy = FaceAnalysisResult.fromJson(mockFaceAnalysisResult.toJson());
      expect(copy.faceShape, mockFaceAnalysisResult.faceShape);
      expect(copy.skinTone, mockFaceAnalysisResult.skinTone);
      expect(copy.skinUndertone, mockFaceAnalysisResult.skinUndertone);
      expect(copy.skinDepth, mockFaceAnalysisResult.skinDepth);
      expect(copy.skinToneHex, mockFaceAnalysisResult.skinToneHex);
      expect(copy.isMock, mockFaceAnalysisResult.isMock);
    });
  });

  test('an invalid hex given straight to the constructor gives no color', () {
    const result = FaceAnalysisResult(skinToneHex: '#12');
    expect(result.skinToneArgb, isNull);
  });
}
