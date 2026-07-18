import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/splash/presentation/screens/splash_screen.dart';

/// Root widget of the BillSplit application.
class BillSplitApp extends StatelessWidget {
  const BillSplitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
    );
  }
}
