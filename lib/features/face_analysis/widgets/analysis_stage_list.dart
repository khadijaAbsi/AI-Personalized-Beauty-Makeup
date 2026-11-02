import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../models/face_analysis_progress.dart';

extension FaceAnalysisStageLabel on FaceAnalysisStage {
  String get label {
    switch (this) {
      case FaceAnalysisStage.detectingFace:
        return 'Detecting your face';
      case FaceAnalysisStage.estimatingFaceShape:
        return 'Estimating face shape';
      case FaceAnalysisStage.estimatingSkinTone:
        return 'Estimating skin tone';
      case FaceAnalysisStage.preparingRecommendations:
        return 'Preparing recommendations';
    }
  }
}

enum AnalysisStageState { done, active, upcoming }

/// White card listing the four stages: finished ones get a check mark, the
/// current one a plum ring and bold text, upcoming ones a pale ring.
/// Every row has the same height in every state, so nothing shifts.
class AnalysisStageList extends StatelessWidget {
  const AnalysisStageList({
    super.key,
    required this.currentStage,
    required this.isComplete,
  });

  final FaceAnalysisStage currentStage;

  /// When true every stage shows as done.
  final bool isComplete;

  AnalysisStageState _stateOf(FaceAnalysisStage stage) {
    if (isComplete || stage.index < currentStage.index) {
      return AnalysisStageState.done;
    }
    if (stage == currentStage) return AnalysisStageState.active;
    return AnalysisStageState.upcoming;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md + AppSpacing.xs,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (final stage in FaceAnalysisStage.values) ...[
            if (stage.index > 0) const SizedBox(height: 14),
            _StageRow(stage: stage, state: _stateOf(stage)),
          ],
        ],
      ),
    );
  }
}

class _StageRow extends StatelessWidget {
  const _StageRow({required this.stage, required this.state});

  final FaceAnalysisStage stage;
  final AnalysisStageState state;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.bodyLarge;
    final TextStyle? textStyle;
    final String statusWord;
    switch (state) {
      case AnalysisStageState.done:
        textStyle = base;
        statusWord = 'done';
      case AnalysisStageState.active:
        textStyle = base?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        );
        statusWord = 'in progress';
      case AnalysisStageState.upcoming:
        textStyle = base?.copyWith(color: AppColors.textSecondary);
        statusWord = 'waiting';
    }

    return Semantics(
      excludeSemantics: true,
      liveRegion: state == AnalysisStageState.active,
      label: '${stage.label}, $statusWord',
      child: Row(
        children: [
          SizedBox.square(
            dimension: 24,
            child: Center(
              child: _StageIcon(
                key: ValueKey('stage-${stage.name}-${state.name}'),
                state: state,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(stage.label, style: textStyle)),
        ],
      ),
    );
  }
}

class _StageIcon extends StatelessWidget {
  const _StageIcon({super.key, required this.state});

  final AnalysisStageState state;

  @override
  Widget build(BuildContext context) {
    if (state == AnalysisStageState.done) {
      return const Icon(Icons.check, size: 22, color: AppColors.accentDark);
    }
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: state == AnalysisStageState.active
              ? AppColors.primary
              : AppColors.border,
          width: 2,
        ),
      ),
    );
  }
}
