/// Builds UPI deep links (`upi://pay?...`) that open any UPI app with the
/// payee, amount and note prefilled.
///
/// Pure Dart — no Flutter imports — fully unit-testable
/// (see test/upi_link_builder_test.dart).
abstract final class UpiLinkBuilder {
  /// Creates a payment link asking for [amount] to be paid to [payeeUpiId].
  ///
  /// [payeeName] is shown by the UPI app; [note] appears as the transaction
  /// remark. Query values are percent-encoded by [Uri].
  static String build({
    required String payeeUpiId,
    required String payeeName,
    required double amount,
    String? note,
  }) {
    return Uri(
      scheme: 'upi',
      host: 'pay',
      queryParameters: {
        'pa': payeeUpiId,
        'pn': payeeName,
        'am': amount.toStringAsFixed(2),
        'cu': 'INR',
        if (note != null && note.isNotEmpty) 'tn': note,
      },
    ).toString();
  }
}
