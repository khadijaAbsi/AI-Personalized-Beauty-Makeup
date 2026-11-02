import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Main call-to-action button.
///
/// - Normal:   pass [onPressed].
/// - Disabled: pass `onPressed: null`.
/// - Loading:  set [isLoading] (taps are ignored and a spinner is shown,
///             while keeping the brand color so it doesn't look disabled).
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;

    return FilledButton(
      onPressed: isEnabled ? onPressed : null,
      style: isLoading
          ? FilledButton.styleFrom(
              disabledBackgroundColor: AppColors.primary,
              disabledForegroundColor: Colors.white,
            )
          : null,
      child: isLoading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
                semanticsLabel: 'Loading',
              ),
            )
          : Text(label),
    );
  }
}
