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

class LoginForm extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  final VoidCallback onGoogleLoginSuccess;
  final VoidCallback onSignUpTap;

  const LoginForm({
    super.key,
    required this.onLoginSuccess,
    required this.onGoogleLoginSuccess,
    required this.onSignUpTap,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (success && mounted) {
      widget.onLoginSuccess();
    } else if (mounted) {
      _passwordController.clear();
    }
  }

  Future<void> _handleGoogleLogin() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.signInWithGoogle();
    if (success && mounted) widget.onGoogleLoginSuccess();
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
              if (value.length < 6)
                return 'Password must be at least 6 characters';
              return null;
            },
          ),
          if (auth.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                auth.errorMessage!,
                style: const TextStyle(color: AppTheme.error),
              ),
            ),
          const SizedBox(height: 24),
          PrimaryLoadingButton(
            isLoading: isLoading,
            onPressed: _handleLogin,
            label: 'Sign In',
          ),
          const SizedBox(height: 24),
          const OrDivider(),
          const SizedBox(height: 24),
          GoogleSignInButton(
            isLoading: isLoading,
            onPressed: _handleGoogleLogin,
          ),
          const SizedBox(height: 16),
          AuthToggleRow(
            promptText: "Don't have an account? ",
            actionText: 'Sign Up',
            onTap: widget.onSignUpTap,
          ),
        ],
      ),
    );
  }
}
