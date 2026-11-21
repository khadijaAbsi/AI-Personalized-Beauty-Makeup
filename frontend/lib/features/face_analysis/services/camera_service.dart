import 'package:camera/camera.dart' as cam;
import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';

// ---------------------------------------------------------------- permission

enum CameraPermissionStatus { granted, denied, permanentlyDenied }

abstract interface class CameraPermissionService {
  /// Shows the Android permission prompt if needed.
  Future<CameraPermissionStatus> requestCameraPermission();

  /// Opens GlowAI's page in the system Settings app.
  Future<bool> openSettings();
}

class SystemCameraPermissionService implements CameraPermissionService {
  const SystemCameraPermissionService();

  @override
  Future<CameraPermissionStatus> requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) return CameraPermissionStatus.granted;
    if (status.isPermanentlyDenied) {
      return CameraPermissionStatus.permanentlyDenied;
    }
    return CameraPermissionStatus.denied;
  }

  @override
  Future<bool> openSettings() => openAppSettings();
}

// -------------------------------------------------------------------- camera

class CameraUnavailableException implements Exception {
  const CameraUnavailableException();
}

class CameraPermissionDeniedException implements Exception {
  const CameraPermissionDeniedException();
}

/// One open camera: a live preview plus the ability to take a picture.
abstract interface class CameraSession {
  /// The live preview. [overlay] is drawn on top of the preview only; it is
  /// never part of the captured image.
  Widget buildPreview({Widget? overlay});

  /// Takes a picture and returns the file path of the original image.
  Future<String> takePicture();

  Future<void> dispose();
}

abstract interface class CameraService {
  /// Opens the front camera (or the first available one).
  /// Throws [CameraUnavailableException] or [CameraPermissionDeniedException].
  Future<CameraSession> openFrontCamera();
}

/// Real camera, using Flutter's `camera` package.
class DeviceCameraService implements CameraService {
  const DeviceCameraService();

  @override
  Future<CameraSession> openFrontCamera() async {
    final List<cam.CameraDescription> cameras;
    try {
      cameras = await cam.availableCameras();
    } on cam.CameraException {
      throw const CameraUnavailableException();
    }
    if (cameras.isEmpty) throw const CameraUnavailableException();

    final description = cameras.firstWhere(
      (camera) => camera.lensDirection == cam.CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    final controller = cam.CameraController(
      description,
      cam.ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: cam.ImageFormatGroup.jpeg,
    );

    try {
      await controller.initialize();
    } on cam.CameraException catch (e) {
      await controller.dispose();
      if (e.code.startsWith('CameraAccess')) {
        throw const CameraPermissionDeniedException();
      }
      throw const CameraUnavailableException();
    }
    return _DeviceCameraSession(controller);
  }
}

class _DeviceCameraSession implements CameraSession {
  _DeviceCameraSession(this._controller);

  final cam.CameraController _controller;

  @override
  Widget buildPreview({Widget? overlay}) {
    // CameraPreview sizes itself to the camera's real aspect ratio (no
    // stretching) and draws `child` on top of the preview.
    return cam.CameraPreview(_controller, child: overlay);
  }

  @override
  Future<String> takePicture() async {
    final file = await _controller.takePicture();
    return file.path;
  }

  @override
  Future<void> dispose() => _controller.dispose();
}
