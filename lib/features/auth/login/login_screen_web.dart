import 'package:flutter/material.dart';
import 'package:sparkle_lite/core/routing/app_router.dart';
import 'package:sparkle_lite/core/theme/app_theme.dart';
import 'login_form.dart';

class LoginScreenWeb extends StatelessWidget {
  const LoginScreenWeb({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          if (MediaQuery.of(context).size.width > 900)
            Expanded(
              flex: 5,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primary,
                      AppTheme.primary.withValues(alpha: 0.75),
                    ],
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 64,
                  vertical: 48,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.spa_outlined,
                      color: Colors.white,
                      size: 40,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Your health journey\ncontinues here.',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Track, reflect, and grow — one day at a time.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            flex: 4,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  vertical: 48,
                  horizontal: 32,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Welcome back',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to pick up where you left off.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 40),
                      LoginForm(
                        onLoginSuccess: () => Navigator.pushReplacementNamed(
                          context,
                          AppRouter.webDashboard,
                        ),
                        onGoogleLoginSuccess: () =>
                            Navigator.pushReplacementNamed(
                              context,
                              AppRouter.webDashboard,
                            ),
                        onSignUpTap: () =>
                            Navigator.pushNamed(context, AppRouter.signup),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
