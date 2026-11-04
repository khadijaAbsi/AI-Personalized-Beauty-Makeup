import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/circle_back_button.dart';

/// Minimal Settings & Privacy screen. It only lists what will exist later;
/// nothing here does anything yet (in particular, there is no working log
/// out, because sign-in is not connected).
///
/// Later, turn each entry into a real action once its feature exists
/// (account settings, privacy controls such as deleting saved photos, and
/// log out via Supabase Auth).
class SettingsPrivacyScreen extends StatelessWidget {
  const SettingsPrivacyScreen({super.key});

  static const List<(IconData, String)> _plannedEntries = [
    (Icons.person_outline, 'Account settings'),
    (Icons.lock_outline, 'Privacy controls'),
    (Icons.logout, 'Log out'),
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
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
              Text('Settings & Privacy', style: textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'These options will be available once sign-in is connected.',
                style: textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < _plannedEntries.length; i++) ...[
                      if (i > 0)
                        const Divider(height: 1, color: AppColors.border),
                      _PlannedEntry(
                        icon: _plannedEntries[i].$1,
                        label: _plannedEntries[i].$2,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A greyed-out, non-interactive row with a "Coming soon" tag.
class _PlannedEntry extends StatelessWidget {
  const _PlannedEntry({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      enabled: false,
      label: '$label, coming soon',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md + AppSpacing.xs,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.disabledForeground),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: textTheme.bodyLarge?.copyWith(
                  color: AppColors.disabledForeground,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text('Coming soon', style: textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
