import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validation.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../domain/exceptions/auth_exception.dart';
import '../../domain/repositories/auth_repository.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_mode_section.dart';
import '../widgets/auth_mode_toggle.dart';
import '../widgets/google_sign_in_button.dart';
import '../widgets/or_divider.dart';
import '../widgets/password_field.dart';

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

  final ValueNotifier<bool> _isRegistering = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isSubmitting = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _isRegistering.dispose();
    _isSubmitting.dispose();
    super.dispose();
  }

  Future<void> _submitEmailForm() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final AuthRepository authRepository = context.read<AuthRepository>();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;

    _isSubmitting.value = true;
    try {
      if (_isRegistering.value) {
        await authRepository.registerWithEmail(email, password);
      } else {
        await authRepository.signInWithEmail(email, password);
      }
      // Success: AuthGate reacts to the auth state stream and shows home.
    } on AuthException catch (e) {
      _showMessage(e.message, color: AppColors.negativeAmount);
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
      _showMessage(
        '$emailError to reset your password.',
        color: AppColors.negativeAmount,
      );
      return;
    }

    final AuthRepository authRepository = context.read<AuthRepository>();
    _isSubmitting.value = true;
    try {
      await authRepository.sendPasswordResetEmail(email);
      _showMessage(
        'Password reset email sent to $email.',
        color: AppColors.positiveAmount,
      );
    } on AuthException catch (e) {
      _showMessage(e.message, color: AppColors.negativeAmount);
    } finally {
      if (mounted) {
        _isSubmitting.value = false;
      }
    }
  }

  Future<void> _onGoogleSignInPressed() async {
    final AuthRepository authRepository = context.read<AuthRepository>();
    _isSubmitting.value = true;
    try {
      // Returns false when the user dismisses the account picker — no error.
      await authRepository.signInWithGoogle();
    } on AuthException catch (e) {
      _showMessage(e.message, color: AppColors.negativeAmount);
    } finally {
      if (mounted) {
        _isSubmitting.value = false;
      }
    }
  }

  void _showMessage(String message, {required Color color}) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
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
                  const AuthHeader(),
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
                  ValueListenableBuilder<bool>(
                    valueListenable: _isRegistering,
                    builder: (context, isRegistering, _) => PasswordField(
                      controller: _passwordController,
                      textInputAction: isRegistering
                          ? TextInputAction.next
                          : TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: isRegistering
                          ? null
                          : (_) => _submitEmailForm(),
                      validator: Validators.password,
                    ),
                  ),
                  AuthModeSection(
                    isRegistering: _isRegistering,
                    isSubmitting: _isSubmitting,
                    passwordController: _passwordController,
                    confirmPasswordController: _confirmPasswordController,
                    onSubmit: _submitEmailForm,
                    onForgotPassword: _onForgotPasswordPressed,
                  ),
                  const SizedBox(height: 16),
                  ListenableBuilder(
                    listenable: Listenable.merge([
                      _isRegistering,
                      _isSubmitting,
                    ]),
                    builder: (context, _) => AppButton(
                      label: _isRegistering.value
                          ? 'Create Account'
                          : 'Sign In',
                      trailingIcon: Icons.arrow_forward,
                      isLoading: _isSubmitting.value,
                      onPressed: _submitEmailForm,
                    ),
                  ),
                  const SizedBox(height: 20),
                  AuthModeToggle(isRegistering: _isRegistering),
                  const SizedBox(height: 20),
                  const OrDivider(),
                  const SizedBox(height: 20),
                  GoogleSignInButton(
                    isSubmitting: _isSubmitting,
                    onPressed: _onGoogleSignInPressed,
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
