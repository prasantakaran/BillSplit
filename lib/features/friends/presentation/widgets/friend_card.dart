import 'package:flutter/material.dart';

import '../../../../core/models/friend.dart';
import '../../../../core/theme/app_colors.dart';

class FriendCard extends StatelessWidget {
  const FriendCard({
    super.key,
    required this.friend,
    this.onEdit,
    this.onDelete,
  });

  final Friend friend;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final String initial = friend.name.isEmpty
        ? '?'
        : friend.name[0].toUpperCase();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: AppColors.brandBlue.withValues(alpha: 0.12),
          child: Text(
            initial,
            style: const TextStyle(
              color: AppColors.brandBlue,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Text(
          friend.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.lightTextPrimary,
          ),
        ),
        subtitle: friend.upiId == null && friend.phone == null
            ? null
            : Text(
                friend.upiId ?? friend.phone!,
                style: const TextStyle(color: AppColors.lightTextSecondary),
              ),
        trailing: onEdit == null && onDelete == null
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onEdit != null)
                    IconButton(
                      tooltip: 'Edit friend',
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: AppColors.brandBlue,
                      ),
                      onPressed: onEdit,
                    ),
                  if (onDelete != null)
                    IconButton(
                      tooltip: 'Remove friend',
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.lightTextSecondary,
                      ),
                      onPressed: onDelete,
                    ),
                ],
              ),
      ),
    );
  }
}
