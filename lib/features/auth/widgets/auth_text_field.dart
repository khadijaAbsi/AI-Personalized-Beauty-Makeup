import 'package:flutter/material.dart';

/// Labeled text field used across the auth screens.
/// The label sits above the field (matches the design); the field's look
/// comes from the global `InputDecorationTheme`.
class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.focusNode,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.onFieldSubmitted,
    this.isPassword = false,
    this.enabled = true,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onFieldSubmitted;
  final bool isPassword;
  final bool enabled;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final obscure = widget.isPassword && _obscured;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The field itself carries the label for screen readers.
        ExcludeSemantics(child: Text(widget.label, style: textTheme.labelMedium)),
        const SizedBox(height: 8),
        Semantics(
          label: widget.label,
          child: TextFormField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            enabled: widget.enabled,
            validator: widget.validator,
            obscureText: obscure,
            enableSuggestions: !widget.isPassword,
            autocorrect: !widget.isPassword,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            textCapitalization: widget.textCapitalization,
            autofillHints: widget.autofillHints,
            onFieldSubmitted: widget.onFieldSubmitted,
            style: textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: widget.hint,
              suffixIcon: widget.isPassword
                  ? IconButton(
                      tooltip: _obscured ? 'Show password' : 'Hide password',
                      icon: Icon(
                        _obscured
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(() => _obscured = !_obscured),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
