import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_const.dart';
import '../../../../core/constants/app_images.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../auth/presentation/screens/login_screen.dart';

/// Branded splash screen shown on app launch.
///
/// Plays a short intro animation (logo fades and scales in, tagline slides up
/// after it), then fades into the login screen once
/// [AppConstants.splashMinDuration] has elapsed. Once Firebase Authentication
/// is added this will hand off to the auth gate instead, so signed-in users
/// skip the login screen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _introController;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _logoFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );
    _textFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.45, 0.85, curve: Curves.easeOut),
    );
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _introController,
            curve: const Interval(0.45, 0.9, curve: Curves.easeOutCubic),
          ),
        );

    _introController.forward();
    _timer = Timer(AppConstants.splashMinDuration, _goToNextScreen);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _introController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    super.dispose();
  }

  void _goToNextScreen() {
    if (!mounted) {
      return;
    }
    // TODO(auth): navigate to AuthGate once Firebase Authentication is added.
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, _, _) => const LoginScreen(),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(AppImagesConst.splashScreen, fit: BoxFit.cover),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 72),
                FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: const AppLogo(
                      image: AppImagesConst.onlyLogoWithoutText,
                      size: 116,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontFamily: 'Audiowide',
                          fontSize: 30,
                          height: 1,
                          letterSpacing: 1,
                        ),
                        children: [
                          TextSpan(
                            text: 'BILL',
                            style: TextStyle(color: AppColors.brandBlue),
                          ),
                          TextSpan(
                            text: 'SPLIT',
                            style: TextStyle(color: AppColors.brandTeal),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FadeTransition(
                  opacity: _textFade,
                  child: SlideTransition(
                    position: _textSlide,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        AppConstants.tagline,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                          color: AppColors.brandNavy.withValues(alpha: 0.75),
                        ),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
