import 'package:flutter/material.dart';

import '../../../../core/constants/app_images.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_logo.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppLogo(image: AppImagesConst.onlyLogoWithoutText, size: 108),
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
                  Expanded(child: ColoredBox(color: AppColors.brandBlue)),
                  Expanded(child: ColoredBox(color: AppColors.brandTeal)),
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
      ],
    );
  }
}
