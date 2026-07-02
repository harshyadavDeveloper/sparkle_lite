import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sparkle_lite/core/routing/app_router.dart';
import 'package:sparkle_lite/features/ai_insight/ai_insight_provider.dart';
import 'package:sparkle_lite/features/auth/login_screen.dart';
import 'package:sparkle_lite/features/dashboard/dashboard_screen.dart';
import 'package:sparkle_lite/features/doctor_visit/doctor_summary_provider.dart';
import 'package:sparkle_lite/features/records/health_record_provider.dart';
import 'package:sparkle_lite/features/symptom_tracker/symptom_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SparkleApp());
}

class SparkleApp extends StatelessWidget {
  const SparkleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SymptomProvider()),
        ChangeNotifierProvider(create: (_) => HealthRecordProvider()),
        ChangeNotifierProvider(create: (_) => AiInsightProvider()),
        ChangeNotifierProvider(create: (_) => DoctorSummaryProvider()),
      ],
      child: MaterialApp(
        title: 'Sparkle Lite',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,

        onGenerateRoute: AppRouter.generateRoute,

        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (auth.status == AuthStatus.initial) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            return auth.isAuthenticated
                ? const DashboardScreen()
                : const LoginScreen();
          },
        ),
      ),
    );
  }
}
