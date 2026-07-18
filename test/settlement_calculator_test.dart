import 'package:flutter_test/flutter_test.dart';

import 'package:bill_split/core/models/bill_item.dart';
import 'package:bill_split/core/models/settlement.dart';
import 'package:bill_split/features/split/domain/settlement_calculator.dart';

void main() {
  const Map<String, String> names = {'a': 'Asha', 'b': 'Bala', 'c': 'Chitra'};

  group('SettlementCalculator', () {
    test('splits single-owner and shared items with proportional tax', () {
      // The worked example from the architecture docs:
      // A alone eats 300; A and B share 100 (50 each); tax 40 on subtotal 400.
      final items = const [
        BillItem(id: 'i1', name: 'Biryani', price: 300, sharedByFriendIds: ['a']),
        BillItem(id: 'i2', name: 'Naan', price: 100, sharedByFriendIds: ['a', 'b']),
      ];

      final List<Settlement> result = SettlementCalculator.calculate(
        items: items,
        taxAmount: 40,
        friendNamesById: names,
      );

      expect(result, hasLength(2));
      // Sorted by descending total owed: Asha first.
      expect(result[0].friendId, 'a');
      expect(result[0].friendName, 'Asha');
      expect(result[0].itemsTotal, 350);
      expect(result[0].taxShare, 35);
      expect(result[0].totalOwed, 385);
      expect(result[1].friendId, 'b');
      expect(result[1].itemsTotal, 50);
      expect(result[1].taxShare, 5);
      expect(result[1].totalOwed, 55);
    });

    test('zero tax produces zero tax shares', () {
      final items = const [
        BillItem(id: 'i1', name: 'Pizza', price: 200, sharedByFriendIds: ['a', 'b']),
      ];

      final result = SettlementCalculator.calculate(
        items: items,
        taxAmount: 0,
        friendNamesById: names,
      );

      expect(result.every((s) => s.taxShare == 0), isTrue);
      expect(result.every((s) => s.itemsTotal == 100), isTrue);
    });

    test('skips unassigned items entirely', () {
      final items = const [
        BillItem(id: 'i1', name: 'Dosa', price: 120, sharedByFriendIds: ['a']),
        BillItem(id: 'i2', name: 'Coffee', price: 45),
      ];

      final result = SettlementCalculator.calculate(
        items: items,
        taxAmount: 12,
        friendNamesById: names,
      );

      expect(result, hasLength(1));
      expect(result.single.itemsTotal, 120);
      // Tax is distributed over the assigned subtotal only.
      expect(result.single.taxShare, 12);
    });

    test('rounds uneven three-way splits to paise', () {
      final items = const [
        BillItem(id: 'i1', name: 'Platter', price: 100, sharedByFriendIds: ['a', 'b', 'c']),
      ];

      final result = SettlementCalculator.calculate(
        items: items,
        taxAmount: 0,
        friendNamesById: names,
      );

      expect(result, hasLength(3));
      for (final Settlement s in result) {
        expect(s.itemsTotal, closeTo(33.33, 0.005));
      }
    });

    test('returns empty for no items or nothing assigned', () {
      expect(
        SettlementCalculator.calculate(
          items: const [],
          taxAmount: 10,
          friendNamesById: names,
        ),
        isEmpty,
      );
      expect(
        SettlementCalculator.calculate(
          items: const [BillItem(id: 'i1', name: 'Roti', price: 30)],
          taxAmount: 10,
          friendNamesById: names,
        ),
        isEmpty,
      );
    });

    test('falls back to Unknown when a friend name is missing', () {
      final result = SettlementCalculator.calculate(
        items: const [
          BillItem(id: 'i1', name: 'Thali', price: 150, sharedByFriendIds: ['zz']),
        ],
        taxAmount: 0,
        friendNamesById: names,
      );

      expect(result.single.friendName, 'Unknown');
    });
  });
}
