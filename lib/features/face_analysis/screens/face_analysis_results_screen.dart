import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routing/app_router.dart';
import '../../../shared/widgets/circle_back_button.dart';
import '../../../shared/widgets/primary_button.dart';
import '../models/face_analysis_result.dart';
import '../models/face_analysis_results_arguments.dart';
import '../models/selected_photo.dart';
import '../widgets/avatar_illustration.dart';
import '../widgets/face_shape_illustration.dart';
import '../widgets/portrait_message_card.dart';
import '../widgets/result_summary_card.dart';
import '../widgets/skin_tone_swatch.dart';
import '../widgets/supported_attributes_card.dart';

/// Shows what the analysis found. It only displays the [result] it is given;
/// it never starts or restarts an analysis.
///
/// If [result] is null (e.g. the route was opened without data) it shows a
/// friendly message instead of crashing.
class FaceAnalysisResultsScreen extends StatefulWidget {
  const FaceAnalysisResultsScreen({
    super.key,
    required this.result,
    this.photo,
  });

  final FaceAnalysisResult? result;

  /// The portrait that was analysed, kept for later steps.
  final SelectedPhoto? photo;

  static const String disclaimer =
      'Results are estimates and may vary with lighting. They guide '
      'suggestions, not diagnoses.';

  @override
  State<FaceAnalysisResultsScreen> createState() =>
      _FaceAnalysisResultsScreenState();
}

class _FaceAnalysisResultsScreenState extends State<FaceAnalysisResultsScreen> {
  bool _isNavigating = false;

  /// Opens the next step once, however fast the button is tapped.
  Future<void> _openOccasion() async {
    final result = widget.result;
    if (_isNavigating || result == null) return;
    _isNavigating = true;
    try {
      await Navigator.of(context).pushNamed(
        AppRouter.chooseOccasion,
        arguments: FaceAnalysisResultsArguments(
          result: result,
          photo: widget.photo,
        ),
      );
    } finally {
      _isNavigating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;

    // The Continue button is pinned below the scrolling content, so it is
    // always visible (above the bottom navigation bar) whatever the screen
    // height or text size.
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: CircleBackButton(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _Header(
                      subtitle: result == null
                          ? null
                          : result.isMock
                          ? 'Sample data, estimates only'
                          : 'Estimates only',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (result == null)
                      const PortraitMessageCard(
                        message:
                            "We couldn't load your results. Please go "
                            'back and try again.',
                      )
                    else
                      ..._buildResults(context, result),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: result == null
                  ? PrimaryButton(
                      label: 'Go back',
                      onPressed: () => Navigator.of(context).maybePop(),
                    )
                  : PrimaryButton(label: 'Continue', onPressed: _openOccasion),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildResults(BuildContext context, FaceAnalysisResult result) {
    final swatchArgb = result.skinToneArgb;
    final attributes = <String>[
      if (result.skinUndertone != null) 'Undertone: ${result.skinUndertone}',
      if (result.skinDepth != null) 'Depth: ${result.skinDepth}',
      'Face shape',
      'Skin tone',
    ];

    return [
      ResultSummaryCard(
        label: 'Estimated face shape',
        value: result.faceShape,
        trailing: result.faceShape == null
            ? null
            : FaceShapeIllustration(faceShape: result.faceShape),
      ),
      const SizedBox(height: AppSpacing.md),
      ResultSummaryCard(
        label: 'Estimated skin tone',
        value: result.skinTone,
        trailing: swatchArgb == null
            ? null
            : SkinToneSwatch(color: Color(swatchArgb)),
      ),
      const SizedBox(height: AppSpacing.md),
      SupportedAttributesCard(attributes: attributes),
      const SizedBox(height: AppSpacing.md),
      Text(
        FaceAnalysisResultsScreen.disclaimer,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    ];
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.subtitle});

  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        const SizedBox.square(dimension: 90, child: AvatarIllustration()),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your results', style: textTheme.headlineMedium),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(subtitle!, style: textTheme.bodyMedium),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
