/// A person the user splits bills with.
///
/// Pure Dart — Firestore document id is kept outside [toMap] and supplied
/// back through [Friend.fromMap].
class Friend {
  const Friend({required this.id, required this.name, this.upiId, this.phone});

  factory Friend.fromMap(String id, Map<String, dynamic> map) {
    return Friend(
      id: id,
      name: map['name'] as String? ?? '',
      upiId: map['upiId'] as String?,
      phone: map['phone'] as String?,
    );
  }

  final String id;
  final String name;
  final String? upiId;
  final String? phone;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      if (upiId != null) 'upiId': upiId,
      if (phone != null) 'phone': phone,
    };
  }
}
