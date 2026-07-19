import 'package:equatable/equatable.dart';

import '../../../core/models/bill_item.dart';

/// Result of parsing raw OCR text from a restaurant bill.
class ParsedBill extends Equatable {
  const ParsedBill({
    required this.items,
    required this.taxAmount,
    this.detectedTotal,
  });

  final List<BillItem> items;
  final double taxAmount;

  final double? detectedTotal;

  @override
  List<Object?> get props => [items, taxAmount, detectedTotal];
}

abstract final class BillParser {
  /// A price at the end of a line, optionally prefixed with a currency
  /// marker: "Paneer Tikka 250.00", "Total: Rs. 535.50", "Naan ₹80".
  static final RegExp _priceAtEnd = RegExp(
    r'(?:rs\.?|inr|₹)?\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?|[0-9]+(?:[.,][0-9]{1,2})?)\s*$',
    caseSensitive: false,
  );

  /// Leading quantity markers: "2 x Butter Naan", "2* Lassi", "2 Masala Dosa".
  static final RegExp _qtyPrefix = RegExp(r'^\d{1,2}\s*[xX*]?\s+');

  /// Anything larger is OCR noise (pincodes, phone fragments), not a price.
  static const double _maxPlausiblePrice = 99999;

  /// Checked before tax keywords: "GSTIN" contains "gst" but is metadata.
  static const List<String> _preIgnoreKeywords = ['gstin', 'fssai'];

  static const List<String> _taxKeywords = [
    'cgst',
    'sgst',
    'igst',
    'gst',
    'vat',
    'tax',
    'service charge',
    'service chg',
  ];

  /// Checked before total keywords: "subtotal" contains "total".
  static const List<String> _subtotalKeywords = [
    'subtotal',
    'sub total',
    'sub-total',
  ];

  static const List<String> _totalKeywords = [
    'grand total',
    'total amount',
    'net amount',
    'amount payable',
    'total',
  ];

  /// Other lines that carry a trailing number but are not food items.
  static const List<String> _ignoreKeywords = [
    'discount',
    'invoice',
    'bill no',
    'bill#',
    'order',
    'date',
    'time',
    'table',
    'guests',
    'pax',
    'qty',
    'phone',
    'ph:',
    'cash',
    'card',
    'change',
    'tender',
    'round off',
    'thank',
    'visit',
  ];

  static ParsedBill parse(String rawText) {
    final List<BillItem> items = [];
    double taxAmount = 0;
    double? detectedTotal;

    for (final String rawLine in rawText.split('\n')) {
      final String line = rawLine.trim();
      if (line.isEmpty) {
        continue;
      }

      final RegExpMatch? priceMatch = _priceAtEnd.firstMatch(line);
      if (priceMatch == null) {
        continue;
      }
      final double? price = double.tryParse(
        priceMatch.group(1)!.replaceAll(',', ''),
      );
      if (price == null || price <= 0 || price > _maxPlausiblePrice) {
        continue;
      }

      final String lower = line.toLowerCase();

      if (_preIgnoreKeywords.any(lower.contains)) {
        continue;
      }
      if (_taxKeywords.any(lower.contains)) {
        taxAmount += price;
        continue;
      }
      if (_subtotalKeywords.any(lower.contains)) {
        continue;
      }
      if (_totalKeywords.any(lower.contains)) {
        detectedTotal = price;
        continue;
      }
      if (_ignoreKeywords.any(lower.contains)) {
        continue;
      }

      String name = line.substring(0, priceMatch.start).trim();
      // Tabular Qty/Item/Rate/Amount rows leave the rate column at the end
      // of the name ("2 Masala Dosa 145.00") — strip it; the line amount
      // already captured above stays as the item price.
      final RegExpMatch? rateMatch = _priceAtEnd.firstMatch(name);
      if (rateMatch != null && rateMatch.start > 0) {
        name = name.substring(0, rateMatch.start).trim();
      }
      name = name.replaceFirst(_qtyPrefix, '');
      // Strip dot/dash leaders between name and price: "Dal Makhani ....".
      name = name.replaceAll(RegExp(r'[.\-_:·]+$'), '').trim();
      if (name.length < 2 || !name.contains(RegExp(r'[A-Za-z]'))) {
        continue;
      }

      items.add(BillItem(id: 'item-${items.length}', name: name, price: price));
    }

    return ParsedBill(
      items: items,
      taxAmount: taxAmount,
      detectedTotal: detectedTotal,
    );
  }
}
