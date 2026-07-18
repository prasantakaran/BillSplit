import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_images.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../../../auth/data/services/auth_service.dart';

/// Temporary home screen proving the signed-in state.
///
/// Replaced by the real dashboard (scan / friends / history) in later steps.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = context.watch<User?>();

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('BillSplit'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthService>().signOut(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogo(
              image: AppImagesConst.onlyLogoWithoutText,
              size: 96,
            ),
            const SizedBox(height: 20),
            const Text(
              'Welcome,',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user?.displayName ?? user?.email ?? 'there',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.lightTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
