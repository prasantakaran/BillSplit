import 'package:flutter_test/flutter_test.dart';

import 'package:bill_split/core/models/bill.dart';
import 'package:bill_split/core/models/bill_item.dart';
import 'package:bill_split/core/models/friend.dart';
import 'package:bill_split/core/models/settlement.dart';

void main() {
  group('Friend', () {
    test('round-trips through toMap/fromMap', () {
      const friend = Friend(
        id: 'f1',
        name: 'Asha',
        upiId: 'asha@upi',
        phone: '9876543210',
      );

      final restored = Friend.fromMap('f1', friend.toMap());

      expect(restored.id, 'f1');
      expect(restored.name, 'Asha');
      expect(restored.upiId, 'asha@upi');
      expect(restored.phone, '9876543210');
    });

    test('omits null optional fields from the map', () {
      const friend = Friend(id: 'f2', name: 'Ravi');

      final map = friend.toMap();

      expect(map.containsKey('upiId'), isFalse);
      expect(map.containsKey('phone'), isFalse);
      expect(Friend.fromMap('f2', map).upiId, isNull);
    });
  });

  group('BillItem', () {
    test('round-trips through toMap/fromMap', () {
      const item = BillItem(
        id: 'i1',
        name: 'Paneer Tikka',
        price: 249.5,
        sharedByFriendIds: ['f1', 'f2'],
      );

      final restored = BillItem.fromMap(item.toMap());

      expect(restored.id, 'i1');
      expect(restored.name, 'Paneer Tikka');
      expect(restored.price, 249.5);
      expect(restored.sharedByFriendIds, ['f1', 'f2']);
      expect(restored.isAssigned, isTrue);
    });

    test('defaults to unassigned', () {
      const item = BillItem(id: 'i2', name: 'Roti', price: 30);
      expect(item.isAssigned, isFalse);
    });
  });

  group('Settlement', () {
    test('round-trips and computes totalOwed', () {
      const settlement = Settlement(
        friendId: 'f1',
        friendName: 'Asha',
        itemsTotal: 300,
        taxShare: 15,
      );

      final restored = Settlement.fromMap(settlement.toMap());

      expect(restored.friendId, 'f1');
      expect(restored.totalOwed, 315);
    });
  });

  group('Bill', () {
    test('round-trips with nested items and settlements', () {
      final bill = Bill(
        id: 'b1',
        restaurantName: 'Spice Villa',
        createdAt: DateTime.fromMillisecondsSinceEpoch(1721300000000),
        items: const [
          BillItem(id: 'i1', name: 'Biryani', price: 350, sharedByFriendIds: ['f1']),
          BillItem(id: 'i2', name: 'Lassi', price: 80),
        ],
        taxAmount: 21.5,
        totalAmount: 451.5,
        settlements: const [
          Settlement(
            friendId: 'f1',
            friendName: 'Asha',
            itemsTotal: 350,
            taxShare: 17.5,
          ),
        ],
      );

      final restored = Bill.fromMap('b1', bill.toMap());

      expect(restored.restaurantName, 'Spice Villa');
      expect(restored.createdAt, bill.createdAt);
      expect(restored.items, hasLength(2));
      expect(restored.items.first.sharedByFriendIds, ['f1']);
      expect(restored.settlements.single.totalOwed, 367.5);
      expect(restored.itemsSubtotal, 430);
    });
  });
}
