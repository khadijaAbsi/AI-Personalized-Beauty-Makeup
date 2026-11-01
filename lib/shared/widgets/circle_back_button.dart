import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Circular outlined back button used at the top-left of screens.
///
/// Safe to use on the first screen of the app: it only pops when there is a
/// previous route.
///
/// Inside a `Column` with `CrossAxisAlignment.stretch`, wrap it in
/// `Align(alignment: Alignment.centerLeft, ...)` so it stays circular.
class CircleBackButton extends StatelessWidget {
  const CircleBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
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
    );
  }
}
