import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Shows a single floating snackbar (replacing any visible one).
/// Styling comes from the global `SnackBarTheme`; errors use the error color.
void showAppSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? AppColors.error : null,
    ),
  );
}
