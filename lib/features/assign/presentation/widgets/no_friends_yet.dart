import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';

class NoFriendsYet extends StatelessWidget {
  const NoFriendsYet({super.key, required this.onAddFriend});

  final VoidCallback onAddFriend;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.group_add_outlined,
              size: 64,
              color: AppColors.brandBlue.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            const Text(
              'Add friends first',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'You need at least one friend to split this bill with.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.lightTextSecondary),
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'Add Friend',
              icon: Icons.person_add_alt_1,
              onPressed: onAddFriend,
            ),
          ],
        ),
      ),
    );
  }
}
