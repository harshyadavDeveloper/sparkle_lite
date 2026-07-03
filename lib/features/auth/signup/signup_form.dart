import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sparkle_lite/core/theme/app_theme.dart';
import 'package:sparkle_lite/core/utils/logger.dart';
import 'package:sparkle_lite/core/widgets/app_email_field.dart';
import 'package:sparkle_lite/core/widgets/app_password_field.dart';
import 'package:sparkle_lite/core/widgets/auth_toggle_row.dart';
import 'package:sparkle_lite/core/widgets/google_sign_in_button.dart';
import 'package:sparkle_lite/core/widgets/or_divider.dart';
import 'package:sparkle_lite/core/widgets/primary_loading_button.dart';
import 'package:sparkle_lite/features/auth/auth_provider.dart';

class SignupForm extends StatefulWidget {
  final VoidCallback onSignupSuccess;
  final VoidCallback onGoogleSignupSuccess;
  final VoidCallback onSignInTap;

  const SignupForm({
    super.key,
    required this.onSignupSuccess,
    required this.onGoogleSignupSuccess,
    required this.onSignInTap,
  });

  @override
  State<SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends State<SignupForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (success && mounted) widget.onSignupSuccess();
  }

  Future<void> _handleGoogleSignup() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.signInWithGoogle();
    if (success && mounted) widget.onGoogleSignupSuccess();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isLoading = auth.status == AuthStatus.loading;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppEmailField(
            controller: _emailController,
            onChanged: (value) => Logger.info('Email input changed: $value'),
          ),
          const SizedBox(height: 16),
          AppPasswordField(
            controller: _passwordController,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Password is required';
              if (value.length < 6) return 'Minimum 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 16),
          AppPasswordField(
            controller: _confirmPasswordController,
            labelText: 'Confirm Password',
            validator: (value) {
              if (value != _passwordController.text)
                return 'Passwords do not match';
              return null;
            },
          ),
          if (auth.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                auth.errorMessage!,
                style: const TextStyle(color: AppTheme.error),
              ),
            ),
          const SizedBox(height: 24),
          PrimaryLoadingButton(
            isLoading: isLoading,
            onPressed: _handleSignup,
            label: 'Create Account',
          ),
          const SizedBox(height: 16),
          const OrDivider(),
          const SizedBox(height: 24),
          GoogleSignInButton(
            isLoading: isLoading,
            onPressed: _handleGoogleSignup,
          ),
          const SizedBox(height: 24),
          AuthToggleRow(
            promptText: 'Already have an account? ',
            actionText: 'Sign In',
            onTap: widget.onSignInTap,
          ),
        ],
      ),
    );
  }
}
