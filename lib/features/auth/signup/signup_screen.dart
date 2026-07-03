import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'signup_screen_mobile.dart';
import 'signup_screen_web.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return kIsWeb ? const SignupScreenWeb() : const SignupScreenMobile();
  }
}
