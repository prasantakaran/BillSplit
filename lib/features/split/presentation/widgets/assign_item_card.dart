import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/models/bill_item.dart';
import '../../../../core/models/friend.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../providers/bill_flow_state.dart';

class AssignItemCard extends StatelessWidget {
  const AssignItemCard({
    super.key,
    required this.item,
    required this.friends,
    required this.onAddFriend,
  });

  final BillItem item;
  final List<Friend> friends;
  final VoidCallback onAddFriend;

  @override
  Widget build(BuildContext context) {
    final BillFlowState flow = context.read<BillFlowState>();
    final int sharerCount = item.sharedByFriendIds.length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isAssigned ? AppColors.brandTeal : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.name.isEmpty ? '(unnamed item)' : item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.lightTextPrimary,
                  ),
                ),
              ),
              Text(
                CurrencyFormatter.format(item.price),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.brandNavy,
                ),
              ),
            ],
          ),
          if (sharerCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                sharerCount == 1
                    ? 'Paid by 1 person'
                    : 'Split $sharerCount ways - '
                          '${CurrencyFormatter.format(item.price / sharerCount)} each',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.brandTeal,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final Friend friend in friends)
                FilterChip(
                  label: Text(friend.name),
                  selected: item.sharedByFriendIds.contains(friend.id),
                  onSelected: (_) => flow.toggleAssignment(item.id, friend.id),
                  selectedColor: AppColors.brandBlue.withValues(alpha: 0.14),
                  checkmarkColor: AppColors.brandBlue,
                  labelStyle: TextStyle(
                    color: item.sharedByFriendIds.contains(friend.id)
                        ? AppColors.brandBlue
                        : AppColors.lightTextPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  side: const BorderSide(color: AppColors.lightBorder),
                  backgroundColor: AppColors.lightSurface,
                ),
              ActionChip(
                avatar: const Icon(
                  Icons.person_add_alt_1,
                  size: 18,
                  color: AppColors.brandBlue,
                ),
                label: const Text('Add friend'),
                labelStyle: const TextStyle(
                  color: AppColors.brandBlue,
                  fontWeight: FontWeight.w600,
                ),
                side: const BorderSide(color: AppColors.lightBorder),
                backgroundColor: AppColors.lightSurface,
                onPressed: onAddFriend,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
