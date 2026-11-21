import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/circle_back_button.dart';

/// One stage in the "How GlowAI works" list.
class HowItWorksStage {
  const HowItWorksStage({required this.title, required this.description});

  final String title;
  final String description;
}

/// Informational screen: the five stages that turn a photo into a try-on.
///
/// It only explains the flow. It starts no processing and calls no backend.
class HowGlowAiWorksScreen extends StatelessWidget {
  const HowGlowAiWorksScreen({super.key});

  static const String heading = 'How GlowAI works';
  static const String subheading =
      'Five AI stages turn your photo into a try-on.';

  static const List<HowItWorksStage> stages = [
    HowItWorksStage(title: 'Upload', description: 'Your portrait is received.'),
    HowItWorksStage(
      title: 'Face Detection',
      description: 'Finds face and landmarks.',
    ),
    HowItWorksStage(
      title: 'Attribute Estimation',
      description: 'Estimates face shape and skin tone.',
    ),
    HowItWorksStage(
      title: 'Look Matching',
      description: 'Ranks reference looks.',
    ),
    HowItWorksStage(
      title: 'Virtual Try-On',
      description: 'Renders the look on your photo.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            // Keeps the cards readable on tablets and Flutter web.
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleBackButton(),
                  const SizedBox(height: AppSpacing.lg),
                  Semantics(
                    header: true,
                    child: Text(heading, style: textTheme.headlineMedium),
                  ),
                  const SizedBox(height: AppSpacing.md - AppSpacing.xs),
                  Text(subheading, style: textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.lg),
                  for (var i = 0; i < stages.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.md),
                    _StageCard(number: i + 1, stage: stages[i]),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StageCard extends StatelessWidget {
  const _StageCard({required this.number, required this.stage});

  final int number;
  final HowItWorksStage stage;

  static const double _badgeSize = 44;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return MergeSemantics(
      child: Container(
        key: ValueKey('how-it-works-stage-$number'),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.blush,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          children: [
            Container(
              width: _badgeSize,
              height: _badgeSize,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$number',
                style: textTheme.labelLarge?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Expanded + wrapping text: nothing overflows at large text sizes.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stage.title,
                    style: textTheme.titleMedium?.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stage.description,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textLabel,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
