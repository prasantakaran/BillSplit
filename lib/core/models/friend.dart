import 'package:equatable/equatable.dart';

class Friend extends Equatable {
  final String id;
  final String name;
  final String? upiId;
  final String? phone;

  const Friend({required this.id, required this.name, this.upiId, this.phone});

  @override
  List<Object?> get props => [id, name, upiId, phone];

  factory Friend.fromMap(String id, Map<String, dynamic> map) {
    return Friend(
      id: id,
      name: map['name'] as String? ?? '',
      upiId: map['upiId'] as String?,
      phone: map['phone'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      if (upiId != null) 'upiId': upiId,
      if (phone != null) 'phone': phone,
    };
  }
}
