import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routing/app_router.dart';
import '../../../shared/widgets/circle_back_button.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/secondary_button.dart';
import '../models/selected_photo.dart';
import '../services/camera_service.dart';
import '../services/face_validation_service.dart';
import '../services/gallery_picker_service.dart';
import '../services/image_validation_service.dart';
import '../services/temp_file_cleaner.dart';
import '../widgets/photo_upload_area.dart';
import '../widgets/web_safe_photo.dart';
import '../widgets/portrait_message_card.dart';
import 'camera_capture_screen.dart';

enum _CameraNotice { denied, permanentlyDenied }

/// "Add your portrait": take a selfie or choose a photo, validate the file,
/// preview it, then continue.
///
/// All device access is injectable, so tests don't need hardware and the real
/// face detector can be plugged in later via [faceValidationService].
class AddPortraitScreen extends StatefulWidget {
  const AddPortraitScreen({
    super.key,
    this.cameraService,
    this.cameraPermissionService,
    this.galleryPicker,
    this.imageValidationService,
    this.faceValidationService,
  });

  final CameraService? cameraService;
  final CameraPermissionService? cameraPermissionService;
  final GalleryPicker? galleryPicker;
  final ImageValidationService? imageValidationService;
  final FaceValidationService? faceValidationService;

  @override
  State<AddPortraitScreen> createState() => _AddPortraitScreenState();
}

class _AddPortraitScreenState extends State<AddPortraitScreen> {
  late final CameraService _cameraService =
      widget.cameraService ?? const DeviceCameraService();
  late final CameraPermissionService _permissionService =
      widget.cameraPermissionService ?? const SystemCameraPermissionService();
  late final GalleryPicker _galleryPicker =
      widget.galleryPicker ?? SystemGalleryPicker();
  late final ImageValidationService _imageValidator =
      widget.imageValidationService ?? const ImageValidationService();
  late final FaceValidationService _faceValidator =
      widget.faceValidationService ?? const NotIntegratedFaceValidationService();

  /// The current accepted photo. Only replaced when a new one passes
  /// validation, so a bad pick never loses a good photo.
  SelectedPhoto? _photo;
  FaceValidationResult _faceResult = const FaceValidationResult.notPerformed();

  /// Picker, permission prompt or validation in progress: buttons disabled.
  bool _isBusy = false;

  /// File validation in progress: shows the spinner.
  bool _isValidating = false;

  String? _errorMessage;
  _CameraNotice? _cameraNotice;

  bool get _canContinue =>
      _photo != null && !_isBusy && !_faceResult.blocksContinue;

  void _clearMessages() {
    _errorMessage = null;
    _cameraNotice = null;
  }

  Future<void> _chooseFromGallery() async {
    if (_isBusy) return;
    setState(() {
      _isBusy = true;
      _clearMessages();
    });
    try {
      final path = await _galleryPicker.pickImagePath();
      if (!mounted) return;
      if (path == null) return; // Cancelled: not an error.
      await _validateAndSelect(path, PhotoSource.gallery);
    } on GalleryAccessException {
      if (!mounted) return;
      setState(() {
        _errorMessage = "We couldn't open your photos. Please try again.";
      });
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _takePhoto() async {
    if (_isBusy) return;
    setState(() {
      _isBusy = true;
      _clearMessages();
    });
    try {
      final status = await _permissionService.requestCameraPermission();
      if (!mounted) return;
      if (status != CameraPermissionStatus.granted) {
        setState(() {
          _cameraNotice = status == CameraPermissionStatus.permanentlyDenied
              ? _CameraNotice.permanentlyDenied
              : _CameraNotice.denied;
        });
        return;
      }

      final path = await Navigator.of(context).push<String>(
        MaterialPageRoute<String>(
          builder: (_) => CameraCaptureScreen(cameraService: _cameraService),
        ),
      );
      if (!mounted || path == null) return; // Left the camera: not an error.
      await _validateAndSelect(path, PhotoSource.camera);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _validateAndSelect(String path, PhotoSource source) async {
    setState(() => _isValidating = true);

    ImageValidationResult result;
    try {
      result = await _imageValidator.validate(path, source: source);
    } catch (_) {
      if (mounted) {
        setState(() {
          _isValidating = false;
          _errorMessage = 'Unable to read this photo. Please try a JPG or PNG.';
        });
      }
      return;
    }
    if (!mounted) return;

    final photo = result.photo;
    if (photo == null) {
      if (!kIsWeb) unawaited(deleteTempFileQuietly(path));
      setState(() {
        _isValidating = false;
        _errorMessage = result.error?.message;
      });
      return;
    }

    // Face checks are separate from file checks. If the detector fails to run,
    // treat it as "not performed" rather than blocking the user.
    FaceValidationResult faceResult;
    try {
      faceResult = await _faceValidator.validate(photo);
    } catch (_) {
      faceResult = const FaceValidationResult.notPerformed();
    }
    if (!mounted) return;

    // A converted HEIC leaves its (temp) source copy behind: drop it.
    if (!kIsWeb && photo.path != path) {
      unawaited(deleteTempFileQuietly(path));
    }

    final previous = _photo;
    setState(() {
      _photo = photo;
      _faceResult = faceResult;
      _isValidating = false;
    });
    if (previous != null && previous.path != photo.path) {
      if (!kIsWeb) unawaited(deleteTempFileQuietly(previous.path));
    }
  }

  void _continue() {
    final photo = _photo;
    if (photo == null) return;
    Navigator.of(context).pushNamed(
      AppRouter.faceAnalysisProcessing,
      arguments: photo,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // A plain scroll view, not SliverFillRemaining: that sizes itself from
    // the content's intrinsic height, which can't see the upload area's
    // aspect ratio and so under-measured the column (the bottom overflows).
    // Nothing on this screen needs to stretch to fill the viewport.
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: CircleBackButton(),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Add your portrait', style: textTheme.headlineMedium),
                const SizedBox(height: AppSpacing.lg),
                kIsWeb && _photo != null
                    ? AspectRatio(
                        aspectRatio: 1.2,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: WebSafePhoto(path: _photo!.path, fit: BoxFit.contain),
                        ),
                      )
                    : PhotoUploadArea(
                        photoPath: _photo?.path,
                        isLoading: _isValidating,
                        onTap: _isBusy ? null : _chooseFromGallery,
                      ),
                const SizedBox(height: AppSpacing.md),
                ..._buildMessages(),
                ..._buildActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMessages() {
    final widgets = <Widget>[];

    if (_errorMessage != null) {
      widgets.add(PortraitMessageCard(message: _errorMessage!));
    }

    switch (_cameraNotice) {
      case _CameraNotice.denied:
        widgets.add(
          PortraitMessageCard(
            message: 'Camera access is needed to take a photo. You can allow '
                'it when asked, or choose a photo from your gallery instead.',
            actionLabel: 'Try again',
            onAction: _isBusy ? null : _takePhoto,
          ),
        );
      case _CameraNotice.permanentlyDenied:
        widgets.add(
          PortraitMessageCard(
            message: 'Camera access is turned off for GlowAI. Turn it on in '
                'Settings to take a photo, or choose one from your gallery.',
            actionLabel: 'Open Settings',
            onAction: _permissionService.openSettings,
          ),
        );
      case null:
        break;
    }

    if (_photo != null && _faceResult.status == FaceCheckStatus.failed) {
      final issues = _faceResult.issues.map((i) => '\u2022 ${i.message}').join('\n');
      widgets.add(
        PortraitMessageCard(
          message: "We couldn't use this photo:\n$issues",
        ),
      );
    }

    return [
      for (final card in widgets) ...[card, const SizedBox(height: AppSpacing.md)],
    ];
  }

  List<Widget> _buildActions() {
    if (_photo == null) {
      return [
        PrimaryButton(
          label: 'Take a Photo',
          onPressed: _isBusy ? null : _takePhoto,
        ),
        const SizedBox(height: AppSpacing.md),
        SecondaryButton(
          label: 'Choose from Gallery',
          onPressed: _isBusy ? null : _chooseFromGallery,
        ),
      ];
    }

    return [
      PrimaryButton(
        label: 'Continue',
        onPressed: _canContinue ? _continue : null,
      ),
      const SizedBox(height: AppSpacing.md),
      _SecondaryActions(
        children: [
          SecondaryButton(
            label: 'Retake photo',
            onPressed: _isBusy ? null : _takePhoto,
          ),
          SecondaryButton(
            label: 'Choose another',
            onPressed: _isBusy ? null : _chooseFromGallery,
          ),
        ],
      ),
    ];
  }
}

/// Two secondary buttons side by side, or stacked when there isn't room
/// (narrow screens or large text), so labels never get squeezed or clipped.
class _SecondaryActions extends StatelessWidget {
  const _SecondaryActions({required this.children});

  final List<Widget> children;

  /// Minimum width each button needs to sit beside the other.
  static const double _minButtonWidth = 150;

  @override
  Widget build(BuildContext context) {
    // 16 is the button label size; this measures how much text is enlarged.
    final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;

    return LayoutBuilder(
      builder: (context, constraints) {
        final perButton = (constraints.maxWidth - AppSpacing.md) / 2;
        final sideBySide = perButton >= _minButtonWidth && textScale <= 1.3;

        if (sideBySide) {
          return Row(
            children: [
              Expanded(child: children[0]),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: children[1]),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            children[0],
            const SizedBox(height: AppSpacing.md),
            children[1],
          ],
        );
      },
    );
  }
}
