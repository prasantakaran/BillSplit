abstract final class UpiLinkBuilder {
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
