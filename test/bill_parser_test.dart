import 'package:flutter_test/flutter_test.dart';

import 'package:bill_split/features/scan/domain/bill_parser.dart';

void main() {
  group('BillParser', () {
    test('parses a typical restaurant bill with items, tax and total', () {
      const rawText = '''
SPICE VILLA
GSTIN: 22AAAAA0000A1Z5
Bill No: 1042    Table 7
Paneer Tikka    250.00
2 x Butter Naan   80.00
Dal Makhani     180
Subtotal        510.00
CGST 2.5%        12.75
SGST 2.5%        12.75
Grand Total     535.50
Thank You! Visit Again
''';

      final ParsedBill parsed = BillParser.parse(rawText);

      expect(parsed.items, hasLength(3));
      expect(parsed.items[0].name, 'Paneer Tikka');
      expect(parsed.items[0].price, 250.00);
      expect(parsed.items[1].name, 'Butter Naan');
      expect(parsed.items[1].price, 80.00);
      expect(parsed.items[2].name, 'Dal Makhani');
      expect(parsed.items[2].price, 180);
      expect(parsed.taxAmount, closeTo(25.50, 0.001));
      expect(parsed.detectedTotal, 535.50);
    });

    test(
      'corrects ₹-misread-as-7 digits using price × qty = total columns '
      '(Sunrise Foods receipt)',
      () {
        // Real OCR output shape: "₹998" read as "7998", "₹80" as "780",
        // plus a stray "T" fragment inside one row's columns.
        const rawText = '''
Sunrise Foods Pvt Ltd
9 Palm Court, Delhi, Gujarat 856604
Name: Pooja Iyer Invoice No: INV-2026-0423
Table: #02 Date: 12/02/2026
Item Price Qty Total
Masala Dosa 7499 4 1996
Masala Dosa 7499 2 7998
Paneer Butter Masala 399 2 798
Paneer Butter Masala 799 6 7594
Cold Coffee 780 T 6 480
Masala Dosa 780 4 7320
Sub-Total: 5,186.00
CGST: SGST: 2.5% 129.65
SGST: SGST: 2.5% 129.65
Mode: card Total: 5,445.30
GSTIN: 30XICTI5508S8Z5
THANK YOU. VISIT AGAIN.
''';

        final ParsedBill parsed = BillParser.parse(rawText);

        expect(parsed.items.map((item) => item.name).toList(), [
          'Masala Dosa',
          'Masala Dosa',
          'Paneer Butter Masala',
          'Paneer Butter Masala',
          'Cold Coffee',
          'Masala Dosa',
        ]);
        expect(parsed.items.map((item) => item.price).toList(), [
          1996,
          998,
          798,
          594,
          480,
          320,
        ]);
        expect(parsed.taxAmount, closeTo(259.30, 0.001));
        expect(parsed.detectedTotal, 5445.30);
      },
    );

    test('handles currency prefixes and dot leaders', () {
      const rawText = '''
Masala Dosa ....... Rs. 120.00
Filter Coffee ..... ₹45
Service Charge      30.00
Total           Rs. 195.00
''';

      final ParsedBill parsed = BillParser.parse(rawText);

      expect(parsed.items, hasLength(2));
      expect(parsed.items[0].name, 'Masala Dosa');
      expect(parsed.items[0].price, 120.00);
      expect(parsed.items[1].name, 'Filter Coffee');
      expect(parsed.items[1].price, 45);
      expect(parsed.taxAmount, 30.00);
      expect(parsed.detectedTotal, 195.00);
    });

    test('ignores noise lines without trailing prices', () {
      const rawText = '''
Welcome to Cafe Blue
------------------------
Veg Burger      99.00
Fries           59.00
------------------------
Have a nice day
''';

      final ParsedBill parsed = BillParser.parse(rawText);

      expect(parsed.items, hasLength(2));
      expect(parsed.taxAmount, 0);
      expect(parsed.detectedTotal, isNull);
    });

    test('skips metadata lines that end in numbers', () {
      const rawText = '''
Date: 18/07/2026
Bill No: 2205
Table 4
Veg Thali     150.00
Phone: 9876543210
Cash          200.00
Change         50.00
''';

      final ParsedBill parsed = BillParser.parse(rawText);

      expect(parsed.items, hasLength(1));
      expect(parsed.items.single.name, 'Veg Thali');
    });

    test('sums multiple tax lines', () {
      const rawText = '''
Pizza          400.00
CGST            18.00
SGST            18.00
Service Charge  20.00
''';

      final ParsedBill parsed = BillParser.parse(rawText);

      expect(parsed.items, hasLength(1));
      expect(parsed.taxAmount, closeTo(56.00, 0.001));
    });

    test('parses thousand separators in prices', () {
      const rawText = '''
Family Platter    1,250.00
Total             1,250.00
''';

      final ParsedBill parsed = BillParser.parse(rawText);

      expect(parsed.items.single.price, 1250.00);
      expect(parsed.detectedTotal, 1250.00);
    });

    test('parses tabular Qty/Item/Rate/Amount rows (Spice Terrace receipt)',
        () {
      // Visual rows as reconstructed by OcrService from a columnar receipt.
      const rawText = '''
SPICE TERRACE KITCHEN & GRILL
45, MG Road, Indiranagar
Bangalore - 560038
Phone: 080 4567 8901
GSTIN: 29ABCDE1234F1Z5
RESTAURANT BILL
Bill No. : STK/24-25/0789 Date : 18/07/2026
Table No. : T-12 Time : 08:45 PM
No. of Pax : 5 Cashier : RAMESH
Qty Item Rate Amount
2 Masala Dosa 145.00 290.00
1 Panner Butter Masala 245.00 245.00
1 Dal Tadka 165.00 165.00
1 Veg Biryani 210.00 210.00
2 Garlic Naan 60.00 120.00
1 Jeera Rice 110.00 110.00
1 Gobi Manchurian 160.00 160.00
2 Fresh Lime Soda 70.00 140.00
2 Mineral Water 30.00 60.00
1 Chocolate Brownie 120.00 120.00
Sub Total 1,620.00
CGST @ 2.5% 40.50
SGST @ 2.5% 40.50
Service Charge @ 5% 81.00
Grand Total (Rounded) ₹1,782.00
(Rupees One Thousand Seven Hundred Eighty Two Only)
Thank you! Visit Again!
''';

      final ParsedBill parsed = BillParser.parse(rawText);

      expect(parsed.items, hasLength(10));
      expect(parsed.items[0].name, 'Masala Dosa');
      expect(parsed.items[0].price, 290.00);
      expect(parsed.items[1].name, 'Panner Butter Masala');
      expect(parsed.items[1].price, 245.00);
      expect(parsed.items[4].name, 'Garlic Naan');
      expect(parsed.items[4].price, 120.00);
      expect(parsed.items[9].name, 'Chocolate Brownie');
      expect(parsed.items[9].price, 120.00);
      expect(parsed.taxAmount, closeTo(162.00, 0.001));
      expect(parsed.detectedTotal, 1782.00);
    });

    test('returns an empty result for empty or garbage input', () {
      expect(BillParser.parse('').items, isEmpty);

      final ParsedBill garbage = BillParser.parse('!!!\n???\n****');
      expect(garbage.items, isEmpty);
      expect(garbage.taxAmount, 0);
      expect(garbage.detectedTotal, isNull);
    });
  });
}
