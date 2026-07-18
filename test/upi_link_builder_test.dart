import 'package:flutter_test/flutter_test.dart';

import 'package:bill_split/core/utils/upi_link_builder.dart';

void main() {
  group('UpiLinkBuilder', () {
    test('builds a upi://pay link with payee, amount and currency', () {
      final String link = UpiLinkBuilder.build(
        payeeUpiId: 'prasanta@okbank',
        payeeName: 'Prasanta',
        amount: 385,
      );

      final Uri uri = Uri.parse(link);
      expect(uri.scheme, 'upi');
      expect(uri.host, 'pay');
      expect(uri.queryParameters['pa'], 'prasanta@okbank');
      expect(uri.queryParameters['pn'], 'Prasanta');
      expect(uri.queryParameters['am'], '385.00');
      expect(uri.queryParameters['cu'], 'INR');
      expect(uri.queryParameters.containsKey('tn'), isFalse);
    });

    test('always formats the amount with two decimals', () {
      final String link = UpiLinkBuilder.build(
        payeeUpiId: 'a@b',
        payeeName: 'A',
        amount: 55.5,
      );

      expect(Uri.parse(link).queryParameters['am'], '55.50');
    });

    test('includes and encodes the transaction note', () {
      final String link = UpiLinkBuilder.build(
        payeeUpiId: 'a@b',
        payeeName: 'Asha Rao',
        amount: 100,
        note: 'BillSplit: Spice Terrace',
      );

      final Uri uri = Uri.parse(link);
      expect(uri.queryParameters['tn'], 'BillSplit: Spice Terrace');
      expect(uri.queryParameters['pn'], 'Asha Rao');
      // Raw link must not contain unencoded spaces.
      expect(link.contains(' '), isFalse);
    });
  });
}
