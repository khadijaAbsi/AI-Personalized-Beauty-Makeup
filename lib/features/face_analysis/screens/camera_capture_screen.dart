import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/circle_back_button.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/secondary_button.dart';
import '../services/camera_service.dart';
import '../services/temp_file_cleaner.dart';
import '../widgets/web_safe_photo.dart';
import '../widgets/face_guide_overlay.dart';

/// Full-screen selfie camera with an oval guide.
///
/// Pops with the captured photo's file path when the user taps "Use photo",
/// or with null if they leave without using one. Camera permission must
/// already be granted (AddPortraitScreen asks for it first).
class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({super.key, required this.cameraService});

  final CameraService cameraService;

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

enum _Phase { opening, preview, capturing, captured, unavailable, permissionDenied }

class _CameraCaptureScreenState extends State<CameraCaptureScreen>
    with WidgetsBindingObserver {
  CameraSession? _session;
  _Phase _phase = _Phase.opening;
  String? _capturedPath;
  bool _capturedPhotoUsed = false;
  bool _showCaptureError = false;
  bool _isOpening = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setPortraitLock(locked: true);
    _openCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _setPortraitLock(locked: false);
    final session = _session;
    _session = null;
    if (session != null) unawaited(session.dispose());
    final captured = _capturedPath;
    if (captured != null && !_capturedPhotoUsed) {
      unawaited(deleteTempFileQuietly(captured));
    }
    super.dispose();
  }

  /// Keeps the preview upright and the oval in the right place.
  void _setPortraitLock({required bool locked}) {
    unawaited(
      SystemChrome.setPreferredOrientations(
        locked ? const [DeviceOrientation.portraitUp] : const <DeviceOrientation>[],
      ).catchError((Object _) {}),
    );
  }

  /// Release the camera when the app leaves the foreground, reopen on return.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        final session = _session;
        if (session != null) {
          setState(() {
            _session = null;
            _phase = _Phase.opening;
          });
          unawaited(session.dispose());
        }
      case AppLifecycleState.resumed:
        if (_phase == _Phase.opening && _session == null) _openCamera();
      case AppLifecycleState.detached:
        break;
    }
  }

  Future<void> _openCamera() async {
    if (_isOpening) return;
    _isOpening = true;

    final previousCapture = _capturedPath;
    if (_phase != _Phase.opening || previousCapture != null) {
      setState(() {
        _phase = _Phase.opening;
        _capturedPath = null;
        _showCaptureError = false;
      });
      if (previousCapture != null) {
        unawaited(deleteTempFileQuietly(previousCapture));
      }
    }

    try {
      final session = await widget.cameraService.openFrontCamera();
      if (!mounted) {
        await session.dispose();
        return;
      }
      setState(() {
        _session = session;
        _phase = _Phase.preview;
      });
    } on CameraPermissionDeniedException {
      if (mounted) setState(() => _phase = _Phase.permissionDenied);
    } catch (_) {
      if (mounted) setState(() => _phase = _Phase.unavailable);
    } finally {
      _isOpening = false;
    }
  }

  Future<void> _capture() async {
    final session = _session;
    if (session == null || _phase != _Phase.preview) return;

    setState(() {
      _phase = _Phase.capturing;
      _showCaptureError = false;
    });
    try {
      final path = await session.takePicture();
      // Free the camera while the user reviews the photo.
      _session = null;
      await session.dispose();
      if (!mounted) {
        unawaited(deleteTempFileQuietly(path));
        return;
      }
      setState(() {
        _capturedPath = path;
        _phase = _Phase.captured;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.preview;
        _showCaptureError = true;
      });
    }
  }

  void _usePhoto() {
    final path = _capturedPath;
    if (path == null) return;
    _capturedPhotoUsed = true;
    Navigator.of(context).pop(path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: CircleBackButton(),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(child: _buildMainArea()),
              const SizedBox(height: AppSpacing.md),
              _buildControls(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainArea() {
    switch (_phase) {
      case _Phase.opening:
        return const Center(child: CircularProgressIndicator());
      case _Phase.preview:
      case _Phase.capturing:
        final session = _session;
        if (session == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return _DarkFrame(
          child: Center(
            child: session.buildPreview(overlay: const FaceGuideOverlay()),
          ),
        );
      case _Phase.captured:
        return _DarkFrame(
          child: WebSafePhoto(path: _capturedPath!, fit: BoxFit.contain),
        );
      case _Phase.unavailable:
        return const _MessageView(
          icon: Icons.no_photography_outlined,
          text: "We couldn't access a camera on this device. Go back and "
              'choose a photo from your gallery instead.',
        );
      case _Phase.permissionDenied:
        return const _MessageView(
          icon: Icons.lock_outline,
          text: 'Camera access is turned off. Go back to allow it, or choose '
              'a photo from your gallery instead.',
        );
    }
  }

  Widget _buildControls(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    switch (_phase) {
      case _Phase.opening:
      case _Phase.preview:
      case _Phase.capturing:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _showCaptureError
                  ? "We couldn't take the photo. Please try again."
                  : 'Center your face in the oval, then tap the button.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: _showCaptureError
                    ? Theme.of(context).colorScheme.error
                    : null,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _CaptureButton(onPressed: _phase == _Phase.preview ? _capture : null),
          ],
        );
      case _Phase.captured:
        return Row(
          children: [
            Expanded(
              child: SecondaryButton(label: 'Retake', onPressed: _openCamera),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: PrimaryButton(label: 'Use photo', onPressed: _usePhoto),
            ),
          ],
        );
      case _Phase.unavailable:
      case _Phase.permissionDenied:
        return PrimaryButton(
          label: 'Go back',
          onPressed: () => Navigator.of(context).maybePop(),
        );
    }
  }
}

class _DarkFrame extends StatelessWidget {
  const _DarkFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: ColoredBox(
        color: AppColors.textPrimary,
        child: SizedBox.expand(child: child),
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.accentDark),
            const SizedBox(height: AppSpacing.md),
            Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

/// Round shutter button.
class _CaptureButton extends StatelessWidget {
  const _CaptureButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Tooltip(
        message: 'Take photo',
        child: SizedBox(
          width: 76,
          height: 76,
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(
              side: BorderSide(color: AppColors.primary, width: 3),
            ),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPressed,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: onPressed == null
                        ? AppColors.disabledBackground
                        : AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
