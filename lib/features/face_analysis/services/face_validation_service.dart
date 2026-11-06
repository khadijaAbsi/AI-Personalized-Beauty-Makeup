import '../models/selected_photo.dart';

/// What a face detector can report about a photo.
enum FaceIssue {
  noFaceFound,
  multipleFaces,
  notCentered,
  notFacingForward,
  faceNotFullyVisible,
  tooBlurry,
}

extension FaceIssueMessage on FaceIssue {
  String get message {
    switch (this) {
      case FaceIssue.noFaceFound:
        return "We couldn't find a face in this photo.";
      case FaceIssue.multipleFaces:
        return 'Please use a photo with only one face.';
      case FaceIssue.notCentered:
        return 'Please center your face in the photo.';
      case FaceIssue.notFacingForward:
        return 'Please face the camera straight on.';
      case FaceIssue.faceNotFullyVisible:
        return 'Your whole face needs to be visible.';
      case FaceIssue.tooBlurry:
        return 'This photo is too blurry. Please try a sharper one.';
    }
  }
}

enum FaceCheckStatus {
  /// No face detector is connected, so nothing was checked.
  notPerformed,
  passed,
  failed,
}

class FaceValidationResult {
  const FaceValidationResult._(this.status, this.issues);

  /// Nothing was checked. This must never be shown as "face verified".
  const FaceValidationResult.notPerformed()
    : this._(FaceCheckStatus.notPerformed, const []);

  const FaceValidationResult.passed()
    : this._(FaceCheckStatus.passed, const []);

  const FaceValidationResult.failed(List<FaceIssue> issues)
    : this._(FaceCheckStatus.failed, issues);

  final FaceCheckStatus status;
  final List<FaceIssue> issues;

  /// Only a real failure blocks Continue. "Not performed" never does.
  bool get blocksContinue => status == FaceCheckStatus.failed;
}

/// Face checks (one face, centered, facing forward, fully visible, sharp).
///
/// When the backend's RetinaFace model is ready, add a class that implements
/// this interface (it will upload the photo and map the response to a
/// [FaceValidationResult]) and pass it to `AddPortraitScreen`.
abstract interface class FaceValidationService {
  Future<FaceValidationResult> validate(SelectedPhoto photo);
}

/// Used until a real detector exists. It performs NO face checks and reports
/// [FaceCheckStatus.notPerformed], so it never blocks the user.
class NotIntegratedFaceValidationService implements FaceValidationService {
  const NotIntegratedFaceValidationService();

  @override
  Future<FaceValidationResult> validate(SelectedPhoto photo) async {
    return const FaceValidationResult.notPerformed();
  }
}
