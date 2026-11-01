import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Outlined pill button that pairs with [PrimaryButton].
/// Pass `onPressed: null` to disable it.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final style = OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary,
      disabledForegroundColor: AppColors.disabledForeground,
      minimumSize: const Size.fromHeight(56),
      shape: const StadiumBorder(),
      textStyle: Theme.of(context).textTheme.labelLarge,
    ).copyWith(
      side: WidgetStateProperty.resolveWith(
        (states) => BorderSide(
          color: states.contains(WidgetState.disabled)
              ? AppColors.border
              : AppColors.primary,
        ),
      ),
    );

    return OutlinedButton(
      onPressed: onPressed,
      style: style,
      child: Text(label, textAlign: TextAlign.center),
    );
  }
}
