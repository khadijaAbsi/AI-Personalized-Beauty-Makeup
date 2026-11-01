import 'package:flutter/material.dart';

/// "Already have an account? Log In" / "New to GlowAI? Sign up".
class AuthFooterPrompt extends StatelessWidget {
  const AuthFooterPrompt({
    super.key,
    required this.prompt,
    required this.actionLabel,
    required this.onAction,
  });

  final String prompt;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(prompt, style: Theme.of(context).textTheme.bodyMedium),
        TextButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    );
  }
}
