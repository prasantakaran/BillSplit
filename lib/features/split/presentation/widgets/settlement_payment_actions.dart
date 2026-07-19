import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/models/settlement.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/upi_link_builder.dart';
import '../../domain/payment_message_builder.dart';
import 'upi_qr_sheet.dart';

/// Share / open-UPI-app / QR actions for one settlement, shared by the
/// results screen and the history bill detail sheet.
abstract final class SettlementPaymentActions {
  static Future<void> shareRequest({
    required Settlement settlement,
    required String billName,
    required String payeeName,
    String? payeeUpiId,
  }) async {
    final String message = PaymentMessageBuilder.build(
      settlement: settlement,
      billName: billName,
      payeeName: payeeName,
      payeeUpiId: payeeUpiId,
    );
    await SharePlus.instance.share(ShareParams(text: message));
  }

  static Future<void> openUpiApp(
    BuildContext context, {
    required Settlement settlement,
    required String billName,
    required String payeeName,
    required String? payeeUpiId,
  }) async {
    if (payeeUpiId == null) {
      _showMessage(context, 'Enter your UPI ID above to build payment links.');
      return;
    }
    final Uri link = Uri.parse(
      UpiLinkBuilder.build(
        payeeUpiId: payeeUpiId,
        payeeName: payeeName,
        amount: settlement.totalOwed,
        note: 'BillSplit: $billName',
      ),
    );
    final bool launched = await launchUrl(
      link,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && context.mounted) {
      _showMessage(context, 'No UPI app found on this device.');
    }
  }

  static void showQr(
    BuildContext context, {
    required Settlement settlement,
    required String billName,
    required String payeeName,
    required String? payeeUpiId,
  }) {
    if (payeeUpiId == null) {
      _showMessage(context, 'Enter your UPI ID above to build payment links.');
      return;
    }
    final String uri = UpiLinkBuilder.build(
      payeeUpiId: payeeUpiId,
      payeeName: payeeName,
      amount: settlement.totalOwed,
      note: 'BillSplit: $billName',
    );
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.lightBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => UpiQrSheet(
        settlement: settlement,
        upiUri: uri,
        payeeUpiId: payeeUpiId,
      ),
    );
  }

  static void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
