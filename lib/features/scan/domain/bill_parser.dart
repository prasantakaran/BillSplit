import 'package:bill_split/features/scan/data/model/parse_bill_model.dart';
import 'package:equatable/equatable.dart';

import '../../../core/models/bill_item.dart';
import '../../../core/models/tax_line.dart';

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

  /// A price glued straight onto the item name with no space:
  /// "CHARCOAL GRILLED CALAMAR425.00".
  static final RegExp _gluedPrice = RegExp(
    r'([A-Za-z])((?:rs\.?|inr|₹)?[0-9][0-9,]*(?:\.[0-9]{1,2})?)\s*$',
    caseSensitive: false,
  );

  /// OCR digit lookalikes inside otherwise-numeric tokens.
  static const Map<String, String> _digitLookalikes = {
    'O': '0',
    'o': '0',
    'l': '1',
    'I': '1',
    'S': '5',
    's': '5',
    'B': '8',
  };

  /// Anything larger is OCR noise (pincodes, phone fragments), not a price.
  static const double _maxPlausiblePrice = 99999;

  /// Checked before tax keywords: "GSTIN" contains "gst" and "Taxable
  /// Value" contains "tax", but neither is a tax line.
  static const List<String> _preIgnoreKeywords = ['gstin', 'fssai', 'taxable'];

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
    'gross amount',
    'amount payable',
    'total',
  ];

  /// Other lines that carry a trailing number but are not food items.
  /// Multi-word forms ("kot no") are used where a bare word could appear
  /// inside a real dish name ("Kothimbir Vadi").
  static const List<String> _ignoreKeywords = [
    'discount',
    'invoice',
    'inv-',
    'receipt',
    'bill no',
    'bill#',
    'customer',
    'contact',
    'kot no',
    'kot-',
    'order',
    'date',
    'time',
    'table',
    'guests',
    'pax',
    'qty',
    'cashier',
    'waiter',
    'phone',
    'ph:',
    'cash',
    'card',
    'upi',
    'payment',
    'paid',
    'balance',
    'change',
    'tender',
    'round off',
    'adjustment',
    'covers',
    'shift',
    'thank',
    'visit',
  ];

  static ParsedBill parse(String rawText) {
    final List<BillItem> items = [];
    final List<List<double>> priceVariants = [];
    final List<TaxLine> taxLines = [];
    final List<String> taxTokens = [];
    double taxAmount = 0;
    double? detectedTotal;
    double? detectedSubtotal;
    String? totalToken;

    for (final String rawLine in rawText.split('\n')) {
      if (rawLine.trim().isEmpty) {
        continue;
      }
      // Normalize em/en dashes so keyword and cleanup rules see plain '-',
      // fix digit-lookalike OCR misreads ("8O" → "80") token by token, then
      // detach a price glued straight onto the last word of the name.
      final String line = rawLine
          .trim()
          .replaceAll(RegExp('[—–]'), '-')
          .split(RegExp(r'\s+'))
          .map(_normalizeDigits)
          .join(' ')
          .replaceFirstMapped(
            _gluedPrice,
            (match) => '${match.group(1)} ${match.group(2)}',
          );

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
        final String label = line
            .substring(0, priceMatch.start)
            .trim()
            .replaceAll(RegExp(r'[.\-_:·]+$'), '')
            .trim();
        taxLines.add(
          TaxLine(label: label.isEmpty ? 'Tax' : label, amount: price),
        );
        taxTokens.add(priceMatch.group(1)!);
        continue;
      }
      if (_subtotalKeywords.any(lower.contains)) {
        detectedSubtotal = price;
        continue;
      }
      if (_totalKeywords.any(lower.contains)) {
        detectedTotal = price;
        totalToken = priceMatch.group(1)!;
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
      List<double> variants = tail.numbers.isEmpty
          ? [price]
          : _valueVariants(tail.numbers.last);
      if (tail.numbers.length == 3) {
        final double? validated = _resolveTabularAmount(tail.numbers);
        if (validated != null) {
          itemPrice = validated;
          // Proven by rate × qty — locked against later reconciliation.
          variants = [validated];
        }
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
      priceVariants.add(variants);
    }

    // Cross-check the item sum against the printed subtotal (or total − tax)
    // and apply the unique ₹-misread correction combination if one exists.
    final double? reference =
        detectedSubtotal ??
        (detectedTotal != null ? detectedTotal - taxAmount : null);
    if (reference != null && reference > 0 && items.isNotEmpty) {
      final double itemsSum = items.fold(0.0, (sum, item) => sum + item.price);
      if ((itemsSum - reference).abs() > 0.01) {
        final List<double>? corrected = _reconcilePrices(
          priceVariants,
          reference,
        );
        if (corrected != null) {
          for (int i = 0; i < items.length; i++) {
            if ((items[i].price - corrected[i]).abs() > 0.001) {
              items[i] = items[i].copyWith(price: corrected[i]);
            }
          }
        }
      }
    }

    // Cross-check the tax lines: printed subtotal + taxes must equal the
    // printed total. When they don't, correct ₹-misread tax amounts — first
    // via reading variants, then by recomputing from the percentages printed
    // in the labels ("CGST (2.5%)") — but only if the equation then balances.
    if (detectedSubtotal != null &&
        detectedTotal != null &&
        taxLines.isNotEmpty) {
      final double taxTarget = detectedTotal - detectedSubtotal;
      if (taxTarget > 0 && (taxAmount - taxTarget).abs() > 0.01) {
        final List<double>? correctedTaxes =
            _reconcilePrices([
              for (final String token in taxTokens) _valueVariants(token),
            ], taxTarget) ??
            _taxesFromPercentages(taxLines, detectedSubtotal, taxTarget);
        if (correctedTaxes != null) {
          taxAmount = 0;
          for (int i = 0; i < taxLines.length; i++) {
            taxLines[i] = TaxLine(
              label: taxLines[i].label,
              amount: correctedTaxes[i],
            );
            taxAmount += correctedTaxes[i];
          }
        }
      }
    }

    // A misread grand total is provable from subtotal + tax.
    if (detectedSubtotal != null &&
        detectedTotal != null &&
        totalToken != null) {
      final double expected = detectedSubtotal + taxAmount;
      if ((detectedTotal - expected).abs() > 0.01) {
        for (final double variant in _valueVariants(totalToken)) {
          if ((variant - expected).abs() < 0.01) {
            detectedTotal = variant;
            break;
          }
        }
      }
    }

    return ParsedBill(
      items: items,
      taxAmount: taxAmount,
      taxLines: taxLines,
      detectedTotal: detectedTotal,
      detectedSubtotal: detectedSubtotal,
    );
  }

  /// Replaces digit-lookalike letters when the token contains a real digit
  /// and the result is fully numeric ("8O" → "80"); otherwise the token is
  /// returned unchanged so real words are never altered.
  static String _normalizeDigits(String token) {
    if (_numericToken.hasMatch(token) || !token.contains(RegExp(r'[0-9]'))) {
      return token;
    }
    final String replaced = token
        .split('')
        .map((char) => _digitLookalikes[char] ?? char)
        .join();
    return _numericToken.hasMatch(replaced) ? replaced : token;
  }

  static final RegExp _percentInLabel = RegExp(r'([0-9]+(?:\.[0-9]+)?)\s*%');

  /// Recomputes tax lines from the percentages printed in their labels
  /// ("CGST (2.5%)" → 2.5% of the subtotal); lines without a percentage
  /// keep their read amount. Applied only when the recomputed taxes make
  /// subtotal + taxes equal the printed total, so partial-base taxes
  /// (e.g. VAT on liquor only) are never wrongly recomputed.
  static List<double>? _taxesFromPercentages(
    List<TaxLine> taxLines,
    double subtotal,
    double target,
  ) {
    final List<double> computed = [];
    for (final TaxLine tax in taxLines) {
      final RegExpMatch? percent = _percentInLabel.firstMatch(tax.label);
      if (percent == null) {
        computed.add(tax.amount);
      } else {
        final double value = subtotal * double.parse(percent.group(1)!) / 100;
        computed.add((value * 100).roundToDouble() / 100);
      }
    }
    final double sum = computed.fold(0.0, (a, b) => a + b);
    return (sum - target).abs() <= 0.02 ? computed : null;
  }

  /// Finds the unique combination of per-item price readings that sums to
  /// [target]. Returns null when none — or more than one — combination
  /// matches, so ambiguous bills are never guessed at.
  static List<double>? _reconcilePrices(
    List<List<double>> variants,
    double target,
  ) {
    final int ambiguous = variants.where((v) => v.length > 1).length;
    if (ambiguous == 0 || ambiguous > 15) {
      return null;
    }
    int matches = 0;
    List<double>? result;
    final List<double> current = List.filled(variants.length, 0);

    void search(int index, double sum) {
      // Prices are positive, so overshooting the target can never recover.
      if (matches > 1 || sum - target > 0.01) {
        return;
      }
      if (index == variants.length) {
        if ((sum - target).abs() <= 0.01) {
          matches++;
          if (matches == 1) {
            result = List.of(current);
          }
        }
        return;
      }
      for (final double value in variants[index]) {
        current[index] = value;
        search(index + 1, sum + value);
      }
    }

    search(0, 0);
    return matches == 1 ? result : null;
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

  /// For a 3-number column tail, returns the validated line amount.
  /// Receipts print either [rate, qty, amount] or [qty, rate, amount], so
  /// both orders are tried, across ₹-misread candidates. Null when the
  /// columns don't multiply out either way.
  static double? _resolveTabularAmount(List<String> numbers) {
    return _validateColumns(numbers[0], numbers[1], numbers[2]) ??
        _validateColumns(numbers[1], numbers[0], numbers[2]);
  }

  static double? _validateColumns(
    String rateToken,
    String qtyToken,
    String amountToken,
  ) {
    final String qtyDigits = _numericToken
        .firstMatch(qtyToken)!
        .group(1)!
        .replaceAll(',', '');
    final int? qty = int.tryParse(qtyDigits);
    if (qty == null || qty < 1 || qty > 99) {
      return null;
    }
    for (final double rate in _valueVariants(rateToken)) {
      for (final double amount in _valueVariants(amountToken)) {
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
