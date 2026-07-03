import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'login_screen_mobile.dart';
import 'login_screen_web.dart';

/// Keep registering this widget in your router as before —
/// it just delegates to the right layout.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return kIsWeb ? const LoginScreenWeb() : const LoginScreenMobile();
  }
}
