import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_const.dart';
import '../core/flavor/app_flavor.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/data/services/auth_service.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/splash/presentation/screens/splash_screen.dart';
import '../shared/providers/bill_flow_state.dart';

/// Root widget
class BillSplitApp extends StatelessWidget {
  const BillSplitApp({super.key, this.authService});

  /// Overridable in widget tests; defaults to the Firebase-backed service.
  final AuthService? authService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ...buildAuthProviders(authService ?? AuthService()),
        ChangeNotifierProvider<BillFlowState>(create: (_) => BillFlowState()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light.copyWith(
          textTheme: AppTheme.light.textTheme.apply(fontFamily: 'Outfit'),
        ),
        // Light-only: the app always renders the light theme regardless of
        // the device dark-mode setting.
        themeMode: ThemeMode.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.textScalerOf(
              context,
            ).clamp(minScaleFactor: 0.85, maxScaleFactor: 1.3),
          ),
          child: AppFlavorConfig.isProd
              ? child!
              : Banner(
                  message: AppFlavorConfig.current.label,
                  location: BannerLocation.topEnd,
                  color: Colors.red.shade700,
                  child: child,
                ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
