import '../../../../core/models/bill_item.dart';
import '../../../../core/models/settlement.dart';

abstract final class SettlementCalculator {
  static List<Settlement> calculate({
    required List<BillItem> items,
    required double taxAmount,
    required Map<String, String> friendNamesById,
  }) {
    final Map<String, double> itemsTotalByFriend = {};
    double assignedSubtotal = 0;

    for (final BillItem item in items) {
      if (!item.isAssigned) {
        continue;
      }
      assignedSubtotal += item.price;
      final double share = item.price / item.sharedByFriendIds.length;
      for (final String friendId in item.sharedByFriendIds) {
        itemsTotalByFriend[friendId] =
            (itemsTotalByFriend[friendId] ?? 0) + share;
      }
    }

    final List<Settlement> settlements = itemsTotalByFriend.entries.map((
      entry,
    ) {
      final double taxShare = assignedSubtotal == 0
          ? 0
          : taxAmount * entry.value / assignedSubtotal;
      return Settlement(
        friendId: entry.key,
        friendName: friendNamesById[entry.key] ?? 'Unknown',
        itemsTotal: _roundToPaise(entry.value),
        taxShare: _roundToPaise(taxShare),
      );
    }).toList()..sort((a, b) => b.totalOwed.compareTo(a.totalOwed));

    return settlements;
  }

  static double _roundToPaise(double value) =>
      (value * 100).roundToDouble() / 100;
}
