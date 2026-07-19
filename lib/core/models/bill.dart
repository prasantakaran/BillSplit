import 'package:equatable/equatable.dart';

import 'bill_item.dart';
import 'settlement.dart';

/// A scanned and settled restaurant bill.
///
/// [createdAt] is stored as milliseconds since epoch so the model stays free
/// of Firebase types and fully unit-testable.
class Bill extends Equatable {
  const Bill({
    required this.id,
    required this.restaurantName,
    required this.createdAt,
    required this.items,
    required this.taxAmount,
    required this.totalAmount,
    this.settlements = const [],
  });

  factory Bill.fromMap(String id, Map<String, dynamic> map) {
    return Bill(
      id: id,
      restaurantName: map['restaurantName'] as String? ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAtMillis'] as int? ?? 0,
      ),
      items: (map['items'] as List? ?? const [])
          .map((item) => BillItem.fromMap(item as Map<String, dynamic>))
          .toList(),
      taxAmount: (map['taxAmount'] as num? ?? 0).toDouble(),
      totalAmount: (map['totalAmount'] as num? ?? 0).toDouble(),
      settlements: (map['settlements'] as List? ?? const [])
          .map((s) => Settlement.fromMap(s as Map<String, dynamic>))
          .toList(),
    );
  }

  final String id;
  final String restaurantName;
  final DateTime createdAt;
  final List<BillItem> items;
  final double taxAmount;
  final double totalAmount;
  final List<Settlement> settlements;

  @override
  List<Object?> get props =>
      [id, restaurantName, createdAt, items, taxAmount, totalAmount, settlements];

  /// Sum of all item prices, before tax.
  double get itemsSubtotal => items.fold(0, (sum, item) => sum + item.price);

  Map<String, dynamic> toMap() {
    return {
      'restaurantName': restaurantName,
      'createdAtMillis': createdAt.millisecondsSinceEpoch,
      'items': items.map((item) => item.toMap()).toList(),
      'taxAmount': taxAmount,
      'totalAmount': totalAmount,
      'settlements': settlements.map((s) => s.toMap()).toList(),
    };
  }
}
