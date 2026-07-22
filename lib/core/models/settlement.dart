import 'package:equatable/equatable.dart';

class Settlement extends Equatable {
  final String friendId;
  final String friendName;
  final double itemsTotal;
  final double taxShare;

  double get totalOwed => itemsTotal + taxShare;

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

  @override
  List<Object?> get props => [friendId, friendName, itemsTotal, taxShare];

  Map<String, dynamic> toMap() {
    return {
      'friendId': friendId,
      'friendName': friendName,
      'itemsTotal': itemsTotal,
      'taxShare': taxShare,
    };
  }
}
