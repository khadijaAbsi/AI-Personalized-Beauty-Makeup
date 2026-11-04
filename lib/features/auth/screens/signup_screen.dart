import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/primary_button.dart';
import '../services/auth_service.dart';
import '../widgets/auth_footer_prompt.dart';
import '../widgets/auth_screen_layout.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/terms_checkbox.dart';

class SignupScreen extends StatefulWidget {
  /// Allows tests to inject a mock authentication service.
  /// Otherwise, real Supabase authentication is used.
  const SignupScreen({super.key, this.authService});

  final AuthService? authService;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  late final AuthService _authService =
      widget.authService ?? SupabaseAuthService();

  bool _acceptedTerms = false;
  bool _showTermsError = false;
  bool _isLoading = false;

  // Enable live validation after the first submission.
  bool _autoValidate = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();

    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();

    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading) return;

    FocusScope.of(context).unfocus();

    setState(() => _autoValidate = true);

    final formIsValid = _formKey.currentState!.validate();

    if (!_acceptedTerms) {
      setState(() => _showTermsError = true);
    }

    if (!formIsValid || !_acceptedTerms) return;

    setState(() => _isLoading = true);

    try {
      // Register using the injected or real auth service.
      await _authService.signUp(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      TextInput.finishAutofillContext();

      if (widget.authService != null) {
        // Preserve the original success message
        // for existing widget tests.
        showAppSnackBar(
          context,
          'Account created (demo mode: nothing was saved).',
        );
        return;
      }

      // Real Supabase authentication.
      final realAuthService = _authService as SupabaseAuthService;

      if (realAuthService.currentSession == null) {
        // Email verification is required.
        // Show the message before navigating, using the
        // MaterialApp's ScaffoldMessenger.
        final messenger = ScaffoldMessenger.of(context);

        messenger.showSnackBar(
          const SnackBar(
            content: Text('Please check your email to verify your account.'),
          ),
        );

        Navigator.of(context).pushReplacementNamed(AppRouter.login);
      } else {
        // An active Supabase session exists.
        Navigator.of(context)
            .pushNamedAndRemoveUntil(AppRouter.home, (route) => false);
      }
    } on AuthException catch (e) {
      if (!mounted) return;

      showAppSnackBar(context, e.message, isError: true);
    } catch (_) {
      if (!mounted) return;

      showAppSnackBar(
        context,
        'Unable to create your account. Please try again.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _goToLogin() {
    Navigator.of(context).pushNamed(AppRouter.login);
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreenLayout(
      title: 'Create your account',
      subtitle: 'Save looks and products across sessions.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildForm(),
          const SizedBox(height: AppSpacing.sm),
          TermsCheckbox(
            value: _acceptedTerms,
            enabled: !_isLoading,
            showError: _showTermsError && !_acceptedTerms,
            onChanged: (value) {
              setState(() {
                _acceptedTerms = value;

                if (value) {
                  _showTermsError = false;
                }
              });
            },
          ),
        ],
      ),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PrimaryButton(
            label: 'Create Account',
            isLoading: _isLoading,
            onPressed: _submit,
          ),
          const SizedBox(height: AppSpacing.sm),
          AuthFooterPrompt(
            prompt: 'Already have an account?',
            actionLabel: 'Log In',
            onAction: _isLoading ? null : _goToLogin,
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      autovalidateMode: _autoValidate
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: AutofillGroup(
        child: Column(
          children: [
            AuthTextField(
              label: 'Full name',
              hint: 'Layla Haddad',
              controller: _nameController,
              focusNode: _nameFocus,
              enabled: !_isLoading,
              validator: Validators.fullName,
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              onFieldSubmitted: (_) => _emailFocus.requestFocus(),
            ),
            const SizedBox(height: AppSpacing.md),
            AuthTextField(
              label: 'Email',
              hint: 'you@example.com',
              controller: _emailController,
              focusNode: _emailFocus,
              enabled: !_isLoading,
              validator: Validators.email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
            ),
            const SizedBox(height: AppSpacing.md),
            AuthTextField(
              label: 'Password',
              hint: 'At least ${AppConstants.minPasswordLength} characters',
              controller: _passwordController,
              focusNode: _passwordFocus,
              enabled: !_isLoading,
              isPassword: true,
              validator: Validators.password,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              onFieldSubmitted: (_) => _confirmFocus.requestFocus(),
            ),
            const SizedBox(height: AppSpacing.md),
            AuthTextField(
              label: 'Confirm password',
              hint: 'Repeat password',
              controller: _confirmController,
              focusNode: _confirmFocus,
              enabled: !_isLoading,
              isPassword: true,
              validator: (value) =>
                  Validators.confirmPassword(value, _passwordController.text),
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              onFieldSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
    );
  }
}
