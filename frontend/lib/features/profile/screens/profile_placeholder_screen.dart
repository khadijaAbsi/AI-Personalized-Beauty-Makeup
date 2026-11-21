import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/circle_back_button.dart';

/// TEMPORARY PLACEHOLDER for screens the Profile links to that don't exist
/// yet (Saved looks, Favorite products). It shows no content, because none
/// exists. To replace one, change its case in `app_router.dart` to build the
/// real screen, and the placeholder is no longer used.
class ProfilePlaceholderScreen extends StatelessWidget {
  const ProfilePlaceholderScreen({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

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
              Text(title, style: textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.xs),
              Text('Temporary placeholder', style: textTheme.bodySmall),
              const SizedBox(height: AppSpacing.md),
              Text(message, style: textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}
