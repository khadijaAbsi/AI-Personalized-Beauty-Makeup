import 'package:flutter/material.dart';

/// "I agree to the Terms and the Privacy Policy" row.
/// The whole row is tappable, so the touch target is large.
class TermsCheckbox extends StatelessWidget {
  const TermsCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.showError = false,
    this.enabled = true,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final bool showError;
  final bool enabled;

  static const String _text =
      'I agree to the Terms and the Privacy Policy, including how my photo is processed.';
  static const String _errorText =
      'Please accept the Terms and Privacy Policy to continue';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MergeSemantics(
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: enabled ? () => onChanged(!value) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: value,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      onChanged: enabled
                          ? (checked) => onChanged(checked ?? false)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(_text, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showError)
          Padding(
            padding: const EdgeInsets.only(left: 36),
            child: Text(
              _errorText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }
}
