import 'package:intl/intl.dart';

/// Formats amounts as Indian rupees: 1234.5 -> "₹1,234.50".
abstract final class CurrencyFormatter {
  static final NumberFormat _format = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static String format(double amount) => _format.format(amount);
}
