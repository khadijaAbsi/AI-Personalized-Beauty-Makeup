/// What the analysis found. Every attribute is optional, because a real
/// backend may be unable to estimate some of them; the UI copes with gaps.
///
/// [fromJson] matches a snake_case FastAPI response, for example:
/// `{"face_shape": "Oval", "skin_tone": "Warm medium",
///   "skin_undertone": "Warm", "skin_depth": "Medium",
///   "skin_tone_hex": "#D8A17E"}`
/// Unknown keys are ignored and wrongly-typed or malformed values become
/// null instead of throwing.
class FaceAnalysisResult {
  const FaceAnalysisResult({
    this.faceShape,
    this.skinTone,
    this.skinUndertone,
    this.skinDepth,
    this.skinToneHex,
    this.isMock = false,
  });

  factory FaceAnalysisResult.fromJson(Map<String, dynamic> json) {
    return FaceAnalysisResult(
      faceShape: _text(json['face_shape']),
      skinTone: _text(json['skin_tone']),
      skinUndertone: _text(json['skin_undertone']),
      skinDepth: _text(json['skin_depth']),
      skinToneHex: _hex(json['skin_tone_hex']),
      isMock: json['is_mock'] == true,
    );
  }

  /// For example "Oval".
  final String? faceShape;

  /// Human-readable name, for example "Warm medium".
  final String? skinTone;

  /// For example "Warm".
  final String? skinUndertone;

  /// For example "Medium".
  final String? skinDepth;

  /// "#RRGGBB" color for the swatch.
  final String? skinToneHex;

  /// True for sample data. The UI labels these results as samples.
  final bool isMock;

  /// [skinToneHex] as an opaque ARGB value (for `Color(value)`), or null if
  /// it is missing or not a valid #RRGGBB color.
  int? get skinToneArgb {
    final hex = skinToneHex;
    if (hex == null) return null;
    final match = _hexPattern.firstMatch(hex.trim());
    if (match == null) return null;
    return 0xFF000000 | int.parse(match.group(1)!, radix: 16);
  }

  Map<String, dynamic> toJson() => {
        'face_shape': faceShape,
        'skin_tone': skinTone,
        'skin_undertone': skinUndertone,
        'skin_depth': skinDepth,
        'skin_tone_hex': skinToneHex,
        'is_mock': isMock,
      };

  static final RegExp _hexPattern = RegExp(r'^#?([0-9a-fA-F]{6})$');

  static String? _text(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String? _hex(Object? value) {
    if (value is! String) return null;
    final match = _hexPattern.firstMatch(value.trim());
    return match == null ? null : '#${match.group(1)!.toUpperCase()}';
  }
}
