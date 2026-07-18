/// One person's share of a bill: their item costs plus a proportional part
/// of the tax.
class Settlement {
  const Settlement({
    required this.friendId,
    required this.friendName,
    required this.itemsTotal,
    required this.taxShare,
  });

  factory Settlement.fromMap(Map<String, dynamic> map) {
    return Settlement(
      friendId: map['friendId'] as String? ?? '',
      friendName: map['friendName'] as String? ?? '',
      itemsTotal: (map['itemsTotal'] as num? ?? 0).toDouble(),
      taxShare: (map['taxShare'] as num? ?? 0).toDouble(),
    );
  }

  final String friendId;
  final String friendName;
  final double itemsTotal;
  final double taxShare;

  double get totalOwed => itemsTotal + taxShare;

  Map<String, dynamic> toMap() {
    return {
      'friendId': friendId,
      'friendName': friendName,
      'itemsTotal': itemsTotal,
      'taxShare': taxShare,
    };
  }

  Settlement copyWith({
    String? friendId,
    String? friendName,
    double? itemsTotal,
    double? taxShare,
  }) {
    return Settlement(
      friendId: friendId ?? this.friendId,
      friendName: friendName ?? this.friendName,
      itemsTotal: itemsTotal ?? this.itemsTotal,
      taxShare: taxShare ?? this.taxShare,
    );
  }
}
