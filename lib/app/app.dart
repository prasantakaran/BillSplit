import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../features/auth/data/services/auth_service.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/splash/presentation/screens/splash_screen.dart';

/// Root widget
class BillSplitApp extends StatelessWidget {
  const BillSplitApp({super.key, this.authService});

  /// Overridable in widget tests; defaults to the Firebase-backed service.
  final AuthService? authService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: buildAuthProviders(authService ?? AuthService()),
      child: MaterialApp(
        title: 'BillSplit',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light.copyWith(
          textTheme: AppTheme.light.textTheme.apply(fontFamily: 'Outfit'),
        ),
        darkTheme: AppTheme.dark.copyWith(
          textTheme: AppTheme.dark.textTheme.apply(fontFamily: 'Outfit'),
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.textScalerOf(
              context,
            ).clamp(minScaleFactor: 0.85, maxScaleFactor: 1.3),
          ),
          child: child!,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
