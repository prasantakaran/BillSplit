import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_images.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validation.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../data/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final ValueNotifier<bool> _obscurePassword = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _obscureConfirmPassword = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _isRegistering = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isSubmitting = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _obscurePassword.dispose();
    _obscureConfirmPassword.dispose();
    _isRegistering.dispose();
    _isSubmitting.dispose();
    super.dispose();
  }

  Future<void> _submitEmailForm() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final AuthService authService = context.read<AuthService>();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;

    _isSubmitting.value = true;
    try {
      if (_isRegistering.value) {
        await authService.registerWithEmail(email, password);
      } else {
        await authService.signInWithEmail(email, password);
      }
      // Success: AuthGate reacts to the auth state stream and shows home.
    } on AuthException catch (e) {
      _showMessage(e.message);
    } finally {
      if (mounted) {
        _isSubmitting.value = false;
      }
    }
  }

  Future<void> _onForgotPasswordPressed() async {
    final String email = _emailController.text.trim();
    final String? emailError = Validators.email(email);
    if (emailError != null) {
      _showMessage('$emailError to reset your password.');
      return;
    }

    final AuthService authService = context.read<AuthService>();
    _isSubmitting.value = true;
    try {
      await authService.sendPasswordResetEmail(email);
      _showMessage('Password reset email sent to $email.');
    } on AuthException catch (e) {
      _showMessage(e.message);
    } finally {
      if (mounted) {
        _isSubmitting.value = false;
      }
    }
  }

  Future<void> _onGoogleSignInPressed() async {
    final AuthService authService = context.read<AuthService>();
    _isSubmitting.value = true;
    try {
      // Returns false when the user dismisses the account picker — no error.
      await authService.signInWithGoogle();
    } on AuthException catch (e) {
      _showMessage(e.message);
    } finally {
      if (mounted) {
        _isSubmitting.value = false;
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildObscureToggle(ValueNotifier<bool> obscure) {
    return IconButton(
      tooltip: obscure.value ? 'Show password' : 'Hide password',
      icon: Icon(
        obscure.value
            ? Icons.visibility_outlined
            : Icons.visibility_off_outlined,
        color: AppColors.lightTextSecondary,
      ),
      onPressed: () => obscure.value = !obscure.value,
    );
  }

  Widget _buildPasswordField() {
    return ListenableBuilder(
      listenable: Listenable.merge([_obscurePassword, _isRegistering]),
      builder: (context, _) {
        final bool isRegistering = _isRegistering.value;
        return AppTextField(
          controller: _passwordController,
          hint: 'Password',
          prefixIcon: Icons.lock_outline,
          obscureText: _obscurePassword.value,
          textInputAction: isRegistering
              ? TextInputAction.next
              : TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          onFieldSubmitted: isRegistering ? null : (_) => _submitEmailForm(),
          suffixIcon: _buildObscureToggle(_obscurePassword),
          validator: Validators.password,
        );
      },
    );
  }

  /// Confirm-password field in registration mode; forgot-password link in
  /// sign-in mode.
  Widget _buildModeSection() {
    return ListenableBuilder(
      listenable: Listenable.merge([
        _isRegistering,
        _obscureConfirmPassword,
        _isSubmitting,
      ]),
      builder: (context, _) {
        if (_isRegistering.value) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              AppTextField(
                controller: _confirmPasswordController,
                hint: 'Confirm Password',
                prefixIcon: Icons.lock_outline,
                obscureText: _obscureConfirmPassword.value,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submitEmailForm(),
                suffixIcon: _buildObscureToggle(_obscureConfirmPassword),
                validator: (value) =>
                    Validators.confirmPassword(value, _passwordController.text),
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
                onPressed: _isSubmitting.value
                    ? null
                    : _onForgotPasswordPressed,
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

  Widget _buildSubmitButton() {
    return ListenableBuilder(
      listenable: Listenable.merge([_isRegistering, _isSubmitting]),
      builder: (context, _) => AppButton(
        label: _isRegistering.value ? 'Create Account' : 'Sign In',
        trailingIcon: Icons.arrow_forward,
        isLoading: _isSubmitting.value,
        onPressed: _submitEmailForm,
      ),
    );
  }

  Widget _buildModeToggle() {
    return ValueListenableBuilder<bool>(
      valueListenable: _isRegistering,
      builder: (context, isRegistering, _) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            isRegistering
                ? 'Already have an account? '
                : "Don't have an account? ",
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.lightTextSecondary,
            ),
          ),
          GestureDetector(
            onTap: () => _isRegistering.value = !_isRegistering.value,
            child: Text(
              isRegistering ? 'Sign in' : 'Sign up',
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

  Widget _buildGoogleButton() {
    return ValueListenableBuilder<bool>(
      valueListenable: _isSubmitting,
      builder: (context, isSubmitting, _) => SizedBox(
        width: double.infinity,
        height: 56,
        child: OutlinedButton(
          onPressed: isSubmitting ? null : _onGoogleSignInPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: AppColors.lightSurface,
            side: BorderSide(
              color: AppColors.brandBlue.withValues(alpha: 0.55),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CustomPaint(size: Size(22, 22), painter: _GoogleGPainter()),
              const SizedBox(width: 12),
              Text(
                'Continue with Google',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brandNavy.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppLogo(
                    image: AppImagesConst.onlyLogoWithoutText,
                    size: 108,
                  ),
                  const SizedBox(height: 16),
                  const Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        fontFamily: 'Audiowide',
                      ),
                      children: [
                        TextSpan(
                          text: 'Bill',
                          style: TextStyle(color: AppColors.brandNavy),
                        ),
                        TextSpan(
                          text: 'Split',
                          style: TextStyle(color: AppColors.brandTeal),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: const SizedBox(
                        width: 170,
                        height: 4,
                        child: Row(
                          children: [
                            Expanded(
                              child: ColoredBox(color: AppColors.brandBlue),
                            ),
                            Expanded(
                              child: ColoredBox(color: AppColors.brandTeal),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Scan a bill, split it with friends,\nand settle up in seconds.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      height: 1.35,
                      color: AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 28),
                  AppTextField(
                    controller: _emailController,
                    hint: 'Email',
                    prefixIcon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 16),
                  _buildPasswordField(),
                  _buildModeSection(),
                  const SizedBox(height: 16),
                  _buildSubmitButton(),
                  const SizedBox(height: 20),
                  _buildModeToggle(),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Expanded(
                        child: Divider(color: AppColors.lightBorder),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                            color: AppColors.lightTextSecondary.withValues(
                              alpha: 0.9,
                            ),
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Divider(color: AppColors.lightBorder),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildGoogleButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints the multicolour Google "G" mark using canvas arcs, so no image
/// asset is needed.
class _GoogleGPainter extends CustomPainter {
  const _GoogleGPainter();

  static const Color _blue = Color(0xFF4285F4);
  static const Color _green = Color(0xFF34A853);
  static const Color _yellow = Color(0xFFFBBC05);
  static const Color _red = Color(0xFFEA4335);

  @override
  void paint(Canvas canvas, Size size) {
    final double stroke = size.width * 0.22;
    final Rect rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    double rad(double degrees) => degrees * math.pi / 180;

    // Angles: 0° = right, positive sweep = clockwise. The gap between the
    // red arc's end (-45°) and the blue arc's start (0°) forms the G opening.
    canvas.drawArc(rect, rad(180), rad(135), false, paint..color = _red);
    canvas.drawArc(rect, rad(135), rad(45), false, paint..color = _yellow);
    canvas.drawArc(rect, rad(45), rad(90), false, paint..color = _green);
    canvas.drawArc(rect, rad(0), rad(45), false, paint..color = _blue);

    // Horizontal bar of the G.
    canvas.drawRect(
      Rect.fromLTWH(
        size.width / 2,
        (size.height - stroke) / 2,
        size.width / 2 - stroke / 4,
        stroke,
      ),
      paint
        ..style = PaintingStyle.fill
        ..color = _blue,
    );
  }

  @override
  bool shouldRepaint(_GoogleGPainter oldDelegate) => false;
}
