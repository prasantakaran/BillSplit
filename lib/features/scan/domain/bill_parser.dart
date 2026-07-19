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

  /// One numeric column token, optionally currency-prefixed: "₹499",
  /// "Rs.80", "1,996.00".
  static final RegExp _numericToken = RegExp(
    r'^(?:rs\.?|inr|₹)?([0-9][0-9,]*(?:\.[0-9]{1,2})?)$',
    caseSensitive: false,
  );

  /// Currency marks OCR sometimes splits into their own token.
  static const Set<String> _currencyOnlyTokens = {'rs', 'rs.', 'inr', '₹'};

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

      // Tabular "Item Price Qty Total" rows: read the trailing numeric
      // columns as [rate, qty, amount] and use rate × qty == amount to both
      // pick the true line amount and self-correct '₹' misread as '7'.
      final List<String> tokens = line.split(RegExp(r'\s+'));
      final ({List<String> numbers, int nameEnd}) tail = _numericTail(tokens);
      double itemPrice = price;
      if (tail.numbers.length == 3) {
        itemPrice = _resolveTabularAmount(tail.numbers) ?? price;
      }

      String name = tokens.sublist(0, tail.nameEnd).join(' ');
      name = name.replaceFirst(_qtyPrefix, '');
      // Strip dot/dash leaders between name and price: "Dal Makhani ....".
      name = name.replaceAll(RegExp(r'[.\-_:·]+$'), '').trim();
      if (name.length < 2 || !name.contains(RegExp(r'[A-Za-z]'))) {
        continue;
      }

      items.add(
        BillItem(id: 'item-${items.length}', name: name, price: itemPrice),
      );
    }

    return ParsedBill(
      items: items,
      taxAmount: taxAmount,
      detectedTotal: detectedTotal,
    );
  }

  /// Collects up to three trailing numeric column tokens from a tokenized
  /// row, tolerating stray currency marks and single-character OCR junk
  /// between columns ("Cold Coffee 780 T 6 480"). Returns the numeric
  /// tokens left-to-right and the token index where the item name ends.
  static ({List<String> numbers, int nameEnd}) _numericTail(
    List<String> tokens,
  ) {
    final List<String> numbers = [];
    int nameEnd = tokens.length;
    for (int i = tokens.length - 1; i >= 0 && numbers.length < 3; i--) {
      final String token = tokens[i];
      if (_numericToken.hasMatch(token)) {
        numbers.insert(0, token);
        nameEnd = i;
        continue;
      }
      if (_currencyOnlyTokens.contains(token.toLowerCase()) ||
          (token.length == 1 && numbers.isNotEmpty)) {
        nameEnd = i;
        continue;
      }
      break;
    }
    return (numbers: numbers, nameEnd: nameEnd);
  }

  /// Candidate readings of a numeric token. ML Kit often misreads the '₹'
  /// sign as a leading '7' ("₹998" → "7998"), so the value with that digit
  /// stripped is offered as a second candidate.
  static List<double> _valueVariants(String token) {
    final String digits = _numericToken
        .firstMatch(token)!
        .group(1)!
        .replaceAll(',', '');
    final List<double> variants = [];
    final double? raw = double.tryParse(digits);
    if (raw != null) {
      variants.add(raw);
    }
    if (digits.length > 1 &&
        digits.startsWith('7') &&
        !digits.startsWith('7.')) {
      final double? stripped = double.tryParse(digits.substring(1));
      if (stripped != null && stripped > 0) {
        variants.add(stripped);
      }
    }
    return variants;
  }

  /// For a [rate, qty, amount] column tail, returns the line amount —
  /// validated by rate × qty == amount across ₹-misread candidates — or
  /// null when the columns don't multiply out.
  static double? _resolveTabularAmount(List<String> numbers) {
    final String qtyDigits = _numericToken
        .firstMatch(numbers[1])!
        .group(1)!
        .replaceAll(',', '');
    final int? qty = int.tryParse(qtyDigits);
    if (qty == null || qty < 1 || qty > 99) {
      return null;
    }
    for (final double rate in _valueVariants(numbers[0])) {
      for (final double amount in _valueVariants(numbers[2])) {
        if (amount > 0 &&
            amount <= _maxPlausiblePrice &&
            (rate * qty - amount).abs() < 0.01) {
          return amount;
        }
      }
    }
    return null;
  }
}
