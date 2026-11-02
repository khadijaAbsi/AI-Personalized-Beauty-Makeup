import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/circle_back_button.dart';

/// TEMPORARY PLACEHOLDER for "Choose Your Occasion".
///
/// The real screen is being built separately. To swap it in, change ONE line:
/// the `AppRouter.chooseOccasion` case in `app_router.dart` (point its builder
/// at the real screen), then delete this file. Nothing else needs to change.
///
/// The Results screen passes a `FaceAnalysisResultsArguments` (the result and
/// the portrait) as route arguments, available to the real screen via
/// `ModalRoute.of(context)?.settings.arguments`.
class ChooseOccasionPlaceholderScreen extends StatelessWidget {
  const ChooseOccasionPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
              const SizedBox(height: AppSpacing.lg),
              Text('Choose Your Occasion', style: textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Occasion selection is coming soon.',
                style: textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
