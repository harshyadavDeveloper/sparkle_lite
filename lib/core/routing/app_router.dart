import 'package:flutter/material.dart';
import 'package:sparkle_lite/features/symptom_tracker/add_symptom_screen.dart';
import 'package:sparkle_lite/features/symptom_tracker/symptom_history_screen.dart';

import '../../features/auth/login_screen.dart';
import '../../features/auth/onboarding_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/profile/health_profile_screen.dart';

class AppRouter {
  static const String login = '/login';
  static const String signup = '/signup';
  static const String onboarding = '/onboarding';
  static const String healthProfile = '/health-profile';
  static const String dashboard = '/dashboard';
  static const String symptomHistory = '/symptom-history';
  static const String addSymptom = '/add-symptom';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case signup:
        return MaterialPageRoute(builder: (_) => const SignupScreen());
      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case healthProfile:
        return MaterialPageRoute(builder: (_) => const HealthProfileScreen());
      case dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case symptomHistory:
        return MaterialPageRoute(builder: (_) => const SymptomHistoryScreen());
      case addSymptom:
        return MaterialPageRoute(builder: (_) => const AddSymptomScreen());
      default:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
    }
  }
}
