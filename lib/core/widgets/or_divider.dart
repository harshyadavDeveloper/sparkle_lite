import 'package:flutter/material.dart';
import 'package:sparkle_lite/core/theme/app_theme.dart';

class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider()),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('OR', style: TextStyle(color: AppTheme.textSecondary)),
        ),
        Expanded(child: Divider()),
      ],
    );
  }
}
