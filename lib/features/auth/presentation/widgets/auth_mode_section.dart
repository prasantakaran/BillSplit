import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validation.dart';
import 'password_field.dart';

class AuthModeSection extends StatelessWidget {
  const AuthModeSection({
    super.key,
    required this.isRegistering,
    required this.isSubmitting,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.onSubmit,
    required this.onForgotPassword,
  });

  final ValueListenable<bool> isRegistering;
  final ValueListenable<bool> isSubmitting;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final VoidCallback onSubmit;
  final VoidCallback onForgotPassword;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([isRegistering, isSubmitting]),
      builder: (context, _) {
        if (isRegistering.value) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              PasswordField(
                controller: confirmPasswordController,
                hint: 'Confirm Password',
                onFieldSubmitted: (_) => onSubmit(),
                validator: (value) =>
                    Validators.confirmPassword(value, passwordController.text),
              ),
            ],
          );
        }
        return Column(
          children: [
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: isSubmitting.value ? null : onForgotPassword,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                ),
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: AppColors.brandBlue,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
