import '../../../core/models/settlement.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/upi_link_builder.dart';

class PaymentMessageBuilder {
  const PaymentMessageBuilder._();

  static String build({
    required Settlement settlement,
    required String billName,
    required String payeeName,
    String? payeeUpiId,
  }) {
    final StringBuffer message = StringBuffer()
      ..writeln('Hi ${settlement.friendName}!')
      ..writeln(
        'Your share of "$billName" on BillSplit is '
        '${CurrencyFormatter.format(settlement.totalOwed)} '
        '(items ${CurrencyFormatter.format(settlement.itemsTotal)} + '
        'tax ${CurrencyFormatter.format(settlement.taxShare)}).',
      );
    if (payeeUpiId != null) {
      message
        ..writeln()
        ..writeln('Pay here:')
        ..writeln(
          UpiLinkBuilder.build(
            payeeUpiId: payeeUpiId,
            payeeName: payeeName,
            amount: settlement.totalOwed,
            note: 'BillSplit: $billName',
          ),
        );
    }
    return message.toString();
  }
}
