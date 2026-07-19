import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class AuthModeToggle extends StatelessWidget {
  const AuthModeToggle({super.key, required this.isRegistering});

  final ValueNotifier<bool> isRegistering;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isRegistering,
      builder: (context, registering, _) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            registering
                ? 'Already have an account? '
                : "Don't have an account? ",
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.lightTextSecondary,
            ),
          ),
          GestureDetector(
            onTap: () => isRegistering.value = !isRegistering.value,
            child: Text(
              registering ? 'Sign in' : 'Sign up',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.brandBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
