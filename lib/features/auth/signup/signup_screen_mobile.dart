import 'package:flutter/material.dart';
import 'package:sparkle_lite/core/routing/app_router.dart';
import 'package:sparkle_lite/core/theme/app_theme.dart';
import 'signup_form.dart';

class SignupScreenMobile extends StatelessWidget {
  const SignupScreenMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create your account',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your information is private and secure.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 40),
              SignupForm(
                onSignupSuccess: () => Navigator.pushReplacementNamed(
                  context,
                  AppRouter.dashboard,
                ),
                onGoogleSignupSuccess: () => Navigator.pushReplacementNamed(
                  context,
                  AppRouter.onboarding,
                ),
                onSignInTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
