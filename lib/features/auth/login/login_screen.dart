import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'login_screen_mobile.dart';
import 'login_screen_web.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return kIsWeb ? const LoginScreenWeb() : const LoginScreenMobile();
  }
}
