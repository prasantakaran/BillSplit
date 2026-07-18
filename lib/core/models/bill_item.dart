/// A single line item on a restaurant bill.
///
/// [sharedByFriendIds] holds the ids of the friends who shared this item;
/// the settlement calculator divides [price] equally between them.
class BillItem {
  const BillItem({
    required this.id,
    required this.name,
    required this.price,
    this.sharedByFriendIds = const [],
  });

  factory BillItem.fromMap(Map<String, dynamic> map) {
    return BillItem(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      price: (map['price'] as num? ?? 0).toDouble(),
      sharedByFriendIds: List<String>.from(
        map['sharedByFriendIds'] as List? ?? const [],
      ),
    );
  }

  final String id;
  final String name;
  final double price;
  final List<String> sharedByFriendIds;

  bool get isAssigned => sharedByFriendIds.isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'sharedByFriendIds': sharedByFriendIds,
    };
  }

  BillItem copyWith({
    String? id,
    String? name,
    double? price,
    List<String>? sharedByFriendIds,
  }) {
    return BillItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      sharedByFriendIds: sharedByFriendIds ?? this.sharedByFriendIds,
    );
  }
}
