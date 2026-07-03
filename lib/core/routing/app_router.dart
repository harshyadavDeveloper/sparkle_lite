import 'package:flutter/material.dart';
import 'package:sparkle_lite/features/ai_insight/ai_insight_input_screen.dart';
import 'package:sparkle_lite/features/auth/login/login_screen.dart';
import 'package:sparkle_lite/features/dashboard/web_dashboard_screen.dart';
import 'package:sparkle_lite/features/doctor_visit/doctor_summary_screen.dart';
import 'package:sparkle_lite/features/family/family_screen.dart';
import 'package:sparkle_lite/features/privacy/privacy_settings_screen.dart';
import 'package:sparkle_lite/features/records/health_records_screen.dart';
import 'package:sparkle_lite/features/records/upload_record_screen.dart';
import 'package:sparkle_lite/features/symptom_tracker/add_symptom_screen.dart';
import 'package:sparkle_lite/features/symptom_tracker/symptom_history_screen.dart';
import 'package:sparkle_lite/features/timeline/timeline_screen.dart';
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
  static const String healthRecords = '/health-records';
  static const String uploadRecord = '/upload-record';
  static const String timeline = '/timeline';
  static const String aiInsightInput = '/ai-insight';
  static const String doctorSummary = '/doctor-summary';
  static const String privacySettings = '/privacy-settings';
  static const String notificationSettings = '/notification-settings';
  static const String family = '/family';
  static const String webDashboard = '/web-dashboard';

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
      case healthRecords:
        return MaterialPageRoute(builder: (_) => const HealthRecordsScreen());
      case uploadRecord:
        return MaterialPageRoute(builder: (_) => const UploadRecordScreen());
      case timeline:
        return MaterialPageRoute(builder: (_) => const TimelineScreen());
      case aiInsightInput:
        return MaterialPageRoute(builder: (_) => const AiInsightInputScreen());
      case doctorSummary:
        return MaterialPageRoute(builder: (_) => const DoctorSummaryScreen());
      case privacySettings:
        return MaterialPageRoute(builder: (_) => const PrivacySettingsScreen());
      case family:
        return MaterialPageRoute(builder: (_) => const FamilyScreen());
      case webDashboard:
        return MaterialPageRoute(builder: (_) => const WebDashboardScreen());
      default:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
    }
  }
}
