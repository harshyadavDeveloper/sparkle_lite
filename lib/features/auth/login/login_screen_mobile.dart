import 'package:flutter/material.dart';
import 'package:sparkle_lite/core/routing/app_router.dart';
import 'package:sparkle_lite/core/theme/app_theme.dart';
import 'login_form.dart';

class LoginScreenMobile extends StatelessWidget {
  const LoginScreenMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              Text(
                'Welcome back',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your health journey continues here.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 40),
              LoginForm(
                onLoginSuccess: () => Navigator.pushReplacementNamed(
                  context,
                  AppRouter.dashboard,
                ),
                onGoogleLoginSuccess: () => Navigator.pushReplacementNamed(
                  context,
                  AppRouter.dashboard,
                ),
                onSignUpTap: () =>
                    Navigator.pushNamed(context, AppRouter.signup),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
