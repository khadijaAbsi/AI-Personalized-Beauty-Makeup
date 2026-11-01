import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routing/app_router.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/secondary_button.dart';
import '../models/face_analysis_progress.dart';
import '../models/face_analysis_result.dart';
import '../models/face_analysis_results_arguments.dart';
import '../models/selected_photo.dart';
import '../services/face_analysis_service.dart';
import '../services/mock_face_analysis_service.dart';
import '../widgets/analysis_avatar.dart';
import '../widgets/analysis_progress_bar.dart';
import '../widgets/analysis_stage_list.dart';
import '../widgets/portrait_message_card.dart';

/// Shows analysis progress. What it displays comes only from the events the
/// [FaceAnalysisService] emits; nothing is animated on its own timeline.
///
/// The analysis starts once, when the screen opens (never on rebuild). It is
/// cancelled when the screen is left. Only when the service reports successful
/// completion (with a result) does it show 100% briefly and then open the
/// results screen, once, with that result and the same, untouched [photo].
/// Failure or leaving the screen never opens Results.
class FaceAnalysisProcessingScreen extends StatefulWidget {
  const FaceAnalysisProcessingScreen({
    super.key,
    required this.photo,
    this.analysisService,
    this.completionDelay = const Duration(milliseconds: 600),
  });

  final SelectedPhoto photo;

  /// Defaults to [MockFaceAnalysisService]. Pass the real service later.
  final FaceAnalysisService? analysisService;

  /// How long 100% stays visible before moving on.
  final Duration completionDelay;

  @override
  State<FaceAnalysisProcessingScreen> createState() =>
      _FaceAnalysisProcessingScreenState();
}

class _FaceAnalysisProcessingScreenState
    extends State<FaceAnalysisProcessingScreen> {
  late final FaceAnalysisService _service =
      widget.analysisService ?? MockFaceAnalysisService();

  StreamSubscription<FaceAnalysisProgress>? _subscription;
  Timer? _navigationTimer;

  FaceAnalysisProgress? _progress;
  FaceAnalysisResult? _result;
  String? _errorMessage;
  bool _hasNavigated = false;

  bool get _isComplete => _progress?.isComplete ?? false;

  @override
  void initState() {
    super.initState();
    _startAnalysis();
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    _subscription = null;
    _navigationTimer?.cancel();
    super.dispose();
  }

  void _startAnalysis() {
    // Never run two analyses at once.
    if (_subscription != null) return;
    _subscription = _service.analyze(widget.photo).listen(
          _onProgress,
          onError: _onError,
          onDone: _onDone,
          cancelOnError: true,
        );
  }

  void _retry() {
    if (_subscription != null) return;
    setState(() {
      _errorMessage = null;
      _progress = null;
      _result = null;
    });
    _startAnalysis();
  }

  void _onProgress(FaceAnalysisProgress progress) {
    if (progress.isComplete) {
      final result = progress.result;
      if (result == null) {
        // "Completed" without a result is a service bug: treat it as a failure
        // rather than showing empty results.
        unawaited(_subscription?.cancel());
        _onError(const FaceAnalysisException());
        return;
      }
      _result = result;
      setState(() => _progress = progress);
      _navigationTimer?.cancel();
      _navigationTimer = Timer(widget.completionDelay, _openResults);
      return;
    }
    setState(() => _progress = progress);
  }

  void _onError(Object error) {
    _subscription = null;
    setState(() {
      _errorMessage = error is FaceAnalysisException
          ? error.message
          : FaceAnalysisException.defaultMessage;
    });
  }

  /// The stream ended. If it never reported completion, that's a failure.
  void _onDone() {
    _subscription = null;
    if (!_isComplete && _errorMessage == null) {
      setState(() => _errorMessage = FaceAnalysisException.defaultMessage);
    }
  }

  void _openResults() {
    final result = _result;
    if (!mounted || _hasNavigated || result == null) return;
    _hasNavigated = true;
    Navigator.of(context).pushReplacementNamed(
      AppRouter.faceAnalysisResults,
      arguments: FaceAnalysisResultsArguments(
        result: result,
        photo: widget.photo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final progress = _progress;
    final errorMessage = _errorMessage;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xxl,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(child: AnalysisAvatar(progress: progress?.progress ?? 0)),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Analyzing your features',
                      textAlign: TextAlign.center,
                      style: textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AnalysisProgressBar(value: progress?.progress ?? 0),
                    const SizedBox(height: AppSpacing.md + AppSpacing.xs),
                    AnalysisStageList(
                      currentStage:
                          progress?.stage ?? FaceAnalysisStage.detectingFace,
                      isComplete: _isComplete,
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      PortraitMessageCard(message: errorMessage),
                      const SizedBox(height: AppSpacing.md),
                      PrimaryButton(label: 'Retry', onPressed: _retry),
                      const SizedBox(height: AppSpacing.md),
                      SecondaryButton(
                        label: 'Choose a different photo',
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
