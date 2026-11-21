import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

/// Shared page structure for the auth screens: back button + wordmark,
/// heading, description, [body], and a [footer].
///
/// Scrolls when the keyboard is open or the screen is short. By default the
/// footer is pinned to the bottom of the screen.
class AuthScreenLayout extends StatelessWidget {
  const AuthScreenLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.footer,
    this.pinFooterToBottom = true,
  });

  final String title;
  final String subtitle;
  final Widget body;
  final Widget footer;

  /// true: [footer] sits at the bottom of the screen (Create Account).
  /// false: [footer] follows [body] directly (Login).
  final bool pinFooterToBottom;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _TopBar(),
                    const SizedBox(height: AppSpacing.lg),
                    Text(title, style: textTheme.headlineMedium),
                    const SizedBox(height: AppSpacing.sm),
                    Text(subtitle, style: textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.lg),
                    body,
                    const SizedBox(height: AppSpacing.lg),
                    if (pinFooterToBottom) const Spacer(),
                    footer,
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

/// Back button (left) and GlowAI wordmark (center).
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.chevron_left),
          style: IconButton.styleFrom(
            fixedSize: const Size(44, 44),
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.border),
          ),
          onPressed: () {
            final navigator = Navigator.of(context);
            if (navigator.canPop()) navigator.pop();
          },
        ),
        Expanded(
          child: Text(
            AppConstants.appName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        // Mirrors the back button's width so the wordmark stays centered.
        const SizedBox(width: 44),
      ],
    );
  }
}
