import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routing/app_router.dart';
import '../../../shared/widgets/circle_back_button.dart';
import '../../../shared/widgets/primary_button.dart';
import '../widgets/photo_guidelines_card.dart';
import '../widgets/privacy_info_card.dart';

/// "Let's analyze your face": first step of the face-analysis flow.
///
/// Open it from anywhere with:
/// `Navigator.of(context).pushNamed(AppRouter.faceAnalysisGuide)`
class FaceAnalysisGuideScreen extends StatelessWidget {
  const FaceAnalysisGuideScreen({super.key});

  static const List<String> _guidelines = [
    'Face the camera straight on',
    'Soft, even natural light',
    'No filters, sunglasses or heavy makeup',
    'Keep your facial features clearly visible',
    'Make sure your full face is visible and in focus',
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Continue sits at the bottom when there's room and the page
            // scrolls on short screens or with large text.
            SliverFillRemaining(
              hasScrollBody: false,
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
                    Text("Let's analyze your face", style: textTheme.headlineMedium),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'A good photo gives the most accurate estimates.',
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const PhotoGuidelinesCard(guidelines: _guidelines),
                    const SizedBox(height: AppSpacing.lg),
                    const PrivacyInfoCard(),
                    const SizedBox(height: AppSpacing.lg),
                    const Spacer(),
                    PrimaryButton(
                      label: 'Continue',
                      onPressed: () =>
                          Navigator.of(context).pushNamed(AppRouter.addPortrait),
                    ),
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
