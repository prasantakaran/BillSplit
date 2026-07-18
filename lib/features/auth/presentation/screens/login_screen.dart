import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_images.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../../../../shared/widgets/app_text_field.dart';

/// Sign-in screen shown to unauthenticated users.
///
/// Supports email/password sign-in or registration, plus Google Sign-In.
/// UI only for now — both flows are wired to Firebase Authentication in a
/// later step.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isRegistering = false;

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final String email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Enter your email';
    }
    if (!_emailPattern.hasMatch(email)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final String password = value ?? '';
    if (password.isEmpty) {
      return 'Enter your password';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  void _submitEmailForm() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }
    // TODO(auth): sign in / register with email and password via AuthService.
    _showComingSoon();
  }

  void _onForgotPasswordPressed() {
    // TODO(auth): send a password reset email via AuthService.
    _showComingSoon();
  }

  void _onGoogleSignInPressed() {
    // TODO(auth): trigger Google Sign-In via AuthService once Firebase is set up.
    _showComingSoon();
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Authentication is coming in a later step.'),
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
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _passwordController,
                    hint: 'Password',
                    prefixIcon: Icons.lock_outline,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onFieldSubmitted: (_) => _submitEmailForm(),
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword
                          ? 'Show password'
                          : 'Hide password',
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.lightTextSecondary,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    validator: _validatePassword,
                  ),
                  if (!_isRegistering) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _onForgotPasswordPressed,
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
                  const SizedBox(height: 16),
                  AppButton(
                    label: _isRegistering ? 'Create Account' : 'Sign In',
                    trailingIcon: Icons.arrow_forward,
                    onPressed: _submitEmailForm,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isRegistering
                            ? 'Already have an account? '
                            : "Don't have an account? ",
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.lightTextSecondary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() => _isRegistering = !_isRegistering);
                        },
                        child: Text(
                          _isRegistering ? 'Sign in' : 'Sign up',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.brandBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
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
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: _onGoogleSignInPressed,
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
                          const CustomPaint(
                            size: Size(22, 22),
                            painter: _GoogleGPainter(),
                          ),
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
