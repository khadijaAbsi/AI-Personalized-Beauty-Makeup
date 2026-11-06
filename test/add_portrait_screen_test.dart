import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// Replace `glowai` with the `name:` in your pubspec.yaml if it differs.
import 'package:glowai/core/routing/app_router.dart';
import 'package:glowai/features/face_analysis/screens/add_portrait_screen.dart';
import 'package:glowai/features/face_analysis/screens/face_analysis_processing_screen.dart';
import 'package:glowai/features/face_analysis/services/camera_service.dart';
import 'package:glowai/features/face_analysis/services/face_validation_service.dart';
import 'package:glowai/features/face_analysis/services/gallery_picker_service.dart';
import 'package:glowai/features/face_analysis/services/image_validation_service.dart';
import 'package:glowai/features/face_analysis/widgets/face_guide_overlay.dart';
import 'package:glowai/features/face_analysis/widgets/portrait_message_card.dart';

import 'helpers/face_test_helpers.dart';

late TestImages images;

Future<void> _pump(
  WidgetTester tester, {
  FakeGalleryPicker? gallery,
  FakeCameraPermissionService? permission,
  FakeCameraService? camera,
  ImageValidationService validator = const ImageValidationService(),
  FaceValidationService? face,
  Size size = const Size(390, 844),
  double textScale = 1.0,
}) async {
  tester.view.devicePixelRatio = 3.0;
  tester.view.physicalSize = size * 3.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      onGenerateRoute: AppRouter.onGenerateRoute,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: AddPortraitScreen(
        galleryPicker: gallery ?? FakeGalleryPicker(const []),
        cameraPermissionService:
            permission ??
            FakeCameraPermissionService(CameraPermissionStatus.granted),
        cameraService:
            camera ?? FakeCameraService(capturePath: images.png('capture.png')),
        imageValidationService: validator,
        faceValidationService: face,
      ),
    ),
  );
}

/// File validation reads real files and decodes real images, which needs the
/// real event loop. This lets it run, then rebuilds the UI, until [finder]
/// appears.
Future<void> _pumpUntil(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 150; i++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
  fail('Timed out waiting for $finder');
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
}

Finder get _continue => find.text('Continue');
Finder get _continueButton => find.widgetWithText(FilledButton, 'Continue');
Finder get _gallery => find.text('Choose from Gallery');
Finder get _takePhoto => find.text('Take a Photo');

/// Choose from the gallery and wait for validation to finish.
Future<void> _chooseValidPhoto(WidgetTester tester) async {
  await _tap(tester, _gallery);
  await tester.pump();
  await _pumpUntil(tester, _continue);
}

String _shownPath(WidgetTester tester) {
  var provider = tester.widget<Image>(find.byType(Image)).image;
  if (provider is ResizeImage) provider = provider.imageProvider;
  return (provider as FileImage).file.path;
}

void main() {
  setUp(() => images = TestImages());
  tearDown(() => images.dispose());

  group('rendering', () {
    testWidgets('shows the upload area and both buttons, no Continue', (
      tester,
    ) async {
      await _pump(tester);

      expect(find.text('Add your portrait'), findsOneWidget);
      expect(find.text('Upload a front-facing photo'), findsOneWidget);
      expect(find.textContaining('one face'), findsOneWidget);
      expect(_takePhoto, findsOneWidget);
      expect(_gallery, findsOneWidget);
      expect(find.byTooltip('Back'), findsOneWidget);

      expect(_continue, findsNothing);
      expect(find.text('Recent photos'), findsNothing);
      expect(find.text('Demo images'), findsNothing);
      expect(find.byType(PortraitMessageCard), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('gallery', () {
    testWidgets('"Choose from Gallery" opens the picker', (tester) async {
      final gallery = FakeGalleryPicker([null]);
      await _pump(tester, gallery: gallery);

      await _tap(tester, _gallery);
      await tester.pump();

      expect(gallery.calls, 1);
    });

    testWidgets('tapping the upload area opens the picker', (tester) async {
      final gallery = FakeGalleryPicker([null]);
      await _pump(tester, gallery: gallery);

      await _tap(tester, find.text('Upload a front-facing photo'));
      await tester.pump();

      expect(gallery.calls, 1);
    });

    testWidgets('cancelling shows no error and changes nothing', (
      tester,
    ) async {
      await _pump(tester, gallery: FakeGalleryPicker([null]));

      await _tap(tester, _gallery);
      await tester.pump();
      await tester.pump();

      expect(find.byType(PortraitMessageCard), findsNothing);
      expect(_continue, findsNothing);
      expect(find.text('Upload a front-facing photo'), findsOneWidget);
      // Buttons are usable again.
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Take a Photo'),
            )
            .onPressed,
        isNotNull,
      );
    });

    testWidgets('picker failure shows a friendly message', (tester) async {
      await _pump(
        tester,
        gallery: FakeGalleryPicker(
          const [],
          error: const GalleryAccessException(),
        ),
      );

      await _tap(tester, _gallery);
      await tester.pump();
      await tester.pump();

      expect(find.textContaining("couldn't open your photos"), findsOneWidget);
    });
  });

  group('valid photos', () {
    for (final name in ['selfie.jpg', 'selfie.png']) {
      testWidgets('$name is accepted and previewed', (tester) async {
        final path = name.endsWith('jpg') ? images.jpg(name) : images.png(name);
        await _pump(tester, gallery: FakeGalleryPicker([path]));

        await _chooseValidPhoto(tester);

        expect(_continue, findsOneWidget);
        expect(find.byType(PortraitMessageCard), findsNothing);
        // The empty upload area is replaced by the photo preview.
        expect(find.text('Upload a front-facing photo'), findsNothing);
        expect(find.byType(Image), findsOneWidget);
        expect(_shownPath(tester), path);
      });
    }
  });

  group('invalid photos', () {
    Future<void> expectRejected(
      WidgetTester tester,
      String path,
      String message, {
      ImageValidationService validator = const ImageValidationService(),
    }) async {
      await _pump(
        tester,
        gallery: FakeGalleryPicker([path]),
        validator: validator,
      );

      await _tap(tester, _gallery);
      await tester.pump();
      await _pumpUntil(tester, find.byType(PortraitMessageCard));

      expect(find.textContaining(message), findsOneWidget);
      expect(_continue, findsNothing);
      // Still able to choose another image.
      expect(_gallery, findsOneWidget);
      expect(find.text('Upload a front-facing photo'), findsOneWidget);
    }

    testWidgets('unsupported format', (tester) async {
      await expectRejected(
        tester,
        images.notAnImage('fake.jpg'),
        // Read from the app, so the test follows any rewording.
        ImageValidationError.unsupportedFormat.message,
      );
    });

    testWidgets('file too large', (tester) async {
      await expectRejected(
        tester,
        images.png('big.png'),
        'too large',
        validator: const ImageValidationService(maxFileSizeBytes: 100),
      );
    });

    testWidgets('resolution too low', (tester) async {
      await expectRejected(
        tester,
        images.png('small.png', width: 300, height: 300),
        'too small for accurate analysis',
      );
    });

    testWidgets('corrupted image', (tester) async {
      await expectRejected(
        tester,
        images.corruptedJpg('bad.jpg'),
        "couldn't open this photo",
      );
    });

    testWidgets('unreadable file', (tester) async {
      await expectRejected(
        tester,
        images.missing('gone.png'),
        "couldn't access this photo",
      );
    });
  });

  group('Continue button', () {
    testWidgets('appears only after the file has really been validated', (
      tester,
    ) async {
      await _pump(tester, gallery: FakeGalleryPicker([images.png('ok.png')]));
      expect(_continue, findsNothing);

      await _tap(tester, _gallery);
      await tester.pump();
      await tester.pump();

      // Validating: spinner shown, buttons locked, no Continue yet.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(_continue, findsNothing);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Take a Photo'),
            )
            .onPressed,
        isNull,
      );

      await _pumpUntil(tester, _continue);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.widget<FilledButton>(_continueButton).onPressed, isNotNull);
    });

    testWidgets('a failed face check disables Continue', (tester) async {
      final face = FakeFaceValidationService(
        const FaceValidationResult.failed([FaceIssue.multipleFaces]),
      );
      await _pump(
        tester,
        gallery: FakeGalleryPicker([images.png('ok.png')]),
        face: face,
      );

      await _chooseValidPhoto(tester);

      expect(face.calls, 1);
      expect(find.textContaining('only one face'), findsOneWidget);
      expect(tester.widget<FilledButton>(_continueButton).onPressed, isNull);
    });

    testWidgets('face checks that were not performed never block', (
      tester,
    ) async {
      final face = FakeFaceValidationService(
        const FaceValidationResult.notPerformed(),
      );
      await _pump(
        tester,
        gallery: FakeGalleryPicker([images.png('ok.png')]),
        face: face,
      );

      await _chooseValidPhoto(tester);

      expect(find.byType(PortraitMessageCard), findsNothing);
      expect(tester.widget<FilledButton>(_continueButton).onPressed, isNotNull);
    });

    testWidgets('navigates to Face Analysis Processing with the photo', (
      tester,
    ) async {
      await _pump(
        tester,
        gallery: FakeGalleryPicker([
          images.png('ok.png', width: 640, height: 800),
        ]),
      );
      await _chooseValidPhoto(tester);

      await _tap(tester, _continue);
      // Not pumpAndSettle: the processing screen keeps updating on its own.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(FaceAnalysisProcessingScreen), findsOneWidget);
      final screen = tester.widget<FaceAnalysisProcessingScreen>(
        find.byType(FaceAnalysisProcessingScreen),
      );
      expect(screen.photo.width, 640);
      expect(screen.photo.height, 800);
    });
  });

  group('retake and change photo', () {
    testWidgets('"Choose another" replaces the photo', (tester) async {
      final first = images.png('first.png');
      final second = images.jpg('second.jpg');
      final gallery = FakeGalleryPicker([first, second]);
      await _pump(tester, gallery: gallery);

      await _chooseValidPhoto(tester);
      expect(_shownPath(tester), first);

      await _tap(tester, find.text('Choose another'));
      await tester.pump();
      await tester.pump();
      for (var i = 0; i < 150 && _shownPath(tester) != second; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
      }

      expect(gallery.calls, 2);
      expect(_shownPath(tester), second);
      expect(_continue, findsOneWidget);
    });

    testWidgets('a bad replacement keeps the previous valid photo', (
      tester,
    ) async {
      final good = images.png('good.png');
      final gallery = FakeGalleryPicker([good, images.notAnImage('bad.jpg')]);
      await _pump(tester, gallery: gallery);
      await _chooseValidPhoto(tester);

      await _tap(tester, find.text('Choose another'));
      await tester.pump();
      await _pumpUntil(tester, find.byType(PortraitMessageCard));

      expect(
        find.text(ImageValidationError.unsupportedFormat.message),
        findsOneWidget,
      );
      expect(_shownPath(tester), good);
      expect(tester.widget<FilledButton>(_continueButton).onPressed, isNotNull);
    });

    testWidgets('"Retake photo" opens the camera and replaces the photo', (
      tester,
    ) async {
      final fromGallery = images.png('gallery.png');
      final fromCamera = images.jpg('camera.jpg');
      final permission = FakeCameraPermissionService(
        CameraPermissionStatus.granted,
      );
      final camera = FakeCameraService(capturePath: fromCamera);
      await _pump(
        tester,
        gallery: FakeGalleryPicker([fromGallery]),
        permission: permission,
        camera: camera,
      );
      await _chooseValidPhoto(tester);

      await _tap(tester, find.text('Retake photo'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('fake-camera-preview')), findsOneWidget);

      await tester.tap(find.byTooltip('Take photo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use photo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      for (var i = 0; i < 150 && _shownPath(tester) != fromCamera; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
      }

      expect(permission.requests, 1);
      expect(_shownPath(tester), fromCamera);
    });
  });

  group('camera', () {
    testWidgets('opens the camera with the oval overlay and captures a photo', (
      tester,
    ) async {
      final permission = FakeCameraPermissionService(
        CameraPermissionStatus.granted,
      );
      final camera = FakeCameraService(capturePath: images.png('shot.png'));
      await _pump(tester, permission: permission, camera: camera);

      await _tap(tester, _takePhoto);
      await tester.pumpAndSettle();

      expect(permission.requests, 1);
      expect(camera.opens, 1);
      expect(find.byKey(const Key('fake-camera-preview')), findsOneWidget);
      expect(find.byType(FaceGuideOverlay), findsOneWidget);
      expect(find.byTooltip('Take photo'), findsOneWidget);

      await tester.tap(find.byTooltip('Take photo'));
      await tester.pumpAndSettle();

      // Review step: retake or use. The oval is gone.
      expect(find.text('Retake'), findsOneWidget);
      expect(find.text('Use photo'), findsOneWidget);
      expect(find.byType(FaceGuideOverlay), findsNothing);

      // Retake reopens the camera.
      await tester.tap(find.text('Retake'));
      await tester.pumpAndSettle();
      expect(camera.opens, 2);
      expect(find.byKey(const Key('fake-camera-preview')), findsOneWidget);
    });

    testWidgets('a captured photo is validated, previewed and can continue', (
      tester,
    ) async {
      final shot = images.jpg('shot.jpg');
      await _pump(tester, camera: FakeCameraService(capturePath: shot));

      await _tap(tester, _takePhoto);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Take photo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use photo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await _pumpUntil(tester, _continue);

      expect(_shownPath(tester), shot);
      expect(find.byType(PortraitMessageCard), findsNothing);
    });

    testWidgets('leaving the camera without a photo is not an error', (
      tester,
    ) async {
      await _pump(tester);

      await _tap(tester, _takePhoto);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(find.byType(AddPortraitScreen), findsOneWidget);
      expect(find.byType(PortraitMessageCard), findsNothing);
      expect(_continue, findsNothing);
    });

    testWidgets('permission denied: explains and can try again', (
      tester,
    ) async {
      final permission = FakeCameraPermissionService(
        CameraPermissionStatus.denied,
      );
      final camera = FakeCameraService(capturePath: images.png('shot.png'));
      await _pump(tester, permission: permission, camera: camera);

      await _tap(tester, _takePhoto);
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('Camera access is needed'), findsOneWidget);
      expect(camera.opens, 0);
      expect(_gallery, findsOneWidget);

      // The user allows it this time.
      permission.status = CameraPermissionStatus.granted;
      await _tap(tester, find.text('Try again'));
      await tester.pumpAndSettle();

      expect(permission.requests, 2);
      expect(camera.opens, 1);
      expect(find.byKey(const Key('fake-camera-preview')), findsOneWidget);
    });

    testWidgets('permission permanently denied: offers Open Settings', (
      tester,
    ) async {
      final permission = FakeCameraPermissionService(
        CameraPermissionStatus.permanentlyDenied,
      );
      final camera = FakeCameraService(capturePath: images.png('shot.png'));
      await _pump(tester, permission: permission, camera: camera);

      await _tap(tester, _takePhoto);
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('turned off for GlowAI'), findsOneWidget);
      expect(camera.opens, 0);

      await _tap(tester, find.text('Open Settings'));
      await tester.pump();
      expect(permission.settingsOpened, 1);
    });

    testWidgets('camera unavailable: friendly message and a way back', (
      tester,
    ) async {
      await _pump(
        tester,
        camera: FakeCameraService(error: const CameraUnavailableException()),
      );

      await _tap(tester, _takePhoto);
      await tester.pumpAndSettle();

      expect(find.textContaining("couldn't access a camera"), findsOneWidget);
      expect(find.byTooltip('Take photo'), findsNothing);

      await tester.tap(find.text('Go back'));
      await tester.pumpAndSettle();
      expect(find.byType(AddPortraitScreen), findsOneWidget);
      expect(_gallery, findsOneWidget);
    });

    testWidgets('camera permission revoked while opening is handled', (
      tester,
    ) async {
      await _pump(
        tester,
        camera: FakeCameraService(
          error: const CameraPermissionDeniedException(),
        ),
      );

      await _tap(tester, _takePhoto);
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Camera access is turned off'),
        findsOneWidget,
      );
    });
  });

  group('layout', () {
    for (final size in const [Size(320, 480), Size(360, 640), Size(411, 891)]) {
      for (final scale in const [1.0, 1.5]) {
        testWidgets(
          'no overflow at ${size.width.toInt()}x${size.height.toInt()}, ${scale}x text',
          (tester) async {
            final path = images.png('ok.png');
            await _pump(
              tester,
              size: size,
              textScale: scale,
              gallery: FakeGalleryPicker([path]),
            );
            expect(tester.takeException(), isNull);

            // The ready state (with Continue and the two small buttons) too.
            await _chooseValidPhoto(tester);
            await tester.ensureVisible(_continue);
            await tester.pump();

            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  });
}
