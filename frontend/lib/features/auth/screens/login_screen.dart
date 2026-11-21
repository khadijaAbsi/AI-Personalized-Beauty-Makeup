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

class LoginScreen extends StatefulWidget {
  /// Allows tests to inject a mock authentication service.
  /// Otherwise, real Supabase authentication is used.
  const LoginScreen({super.key, this.authService});

  final AuthService? authService;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  late final AuthService _authService =
      widget.authService ?? SupabaseAuthService();

  bool _isLoading = false;

  // Errors update live only after the first submission.
  bool _autoValidate = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();

    _emailFocus.dispose();
    _passwordFocus.dispose();

    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading) return;

    FocusScope.of(context).unfocus();

    setState(() => _autoValidate = true);

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Authenticate using the injected or real service.
      await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      TextInput.finishAutofillContext();

      if (widget.authService != null) {
        // Preserve original behavior for injected test services.
        showAppSnackBar(
          context,
          'Welcome back! (demo mode: no real login yet)',
        );
      } else {
        // Real login succeeded.
        // Remove Login from the navigation stack.
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
        'Unable to log in. Please try again.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Return to Signup if it is in the navigation stack.
  /// Otherwise, navigate to Signup directly.
  void _goToSignup() {
    final navigator = Navigator.of(context);

    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushNamed(AppRouter.signup);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreenLayout(
      title: 'Welcome back',
      subtitle: 'Log in to continue your glow journey.',
      pinFooterToBottom: false,
      body: _buildForm(),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PrimaryButton(
            label: 'Log In',
            isLoading: _isLoading,
            onPressed: _submit,
          ),
          const SizedBox(height: AppSpacing.sm),
          AuthFooterPrompt(
            prompt: 'New to GlowAI?',
            actionLabel: 'Sign up',
            onAction: _isLoading ? null : _goToSignup,
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
              hint: 'Your password',
              controller: _passwordController,
              focusNode: _passwordFocus,
              enabled: !_isLoading,
              isPassword: true,
              validator: Validators.requiredPassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
    );
  }
}
