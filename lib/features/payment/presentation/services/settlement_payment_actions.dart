import 'package:flutter/material.dart';

import '../../../../core/models/settlement.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/upi_link_builder.dart';
import '../../data/services/native_url_launcher_service.dart';
import '../../data/services/share_plus_sharing_service.dart';
import '../../domain/payment_message_builder.dart';
import '../../domain/services/sharing_service.dart';
import '../../domain/services/url_launcher_service.dart';
import '../widgets/upi_qr_sheet.dart';

/// Share / open-UPI-app / QR actions for one settlement, shared by the
/// results screen and the history bill detail sheet.
class SettlementPaymentActions {
  SettlementPaymentActions({
    SharingService? sharingService,
    UrlLauncherService? urlLauncherService,
  }) : _sharingService = sharingService ?? SharePlusSharingService(),
       _urlLauncherService = urlLauncherService ?? NativeUrlLauncherService();

  final SharingService _sharingService;
  final UrlLauncherService _urlLauncherService;

  Future<void> shareRequest({
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
    await _sharingService.share(message);
  }

  Future<void> openUpiApp(
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
    final bool launched = await _urlLauncherService.launch(link);
    if (!launched && context.mounted) {
      _showMessage(context, 'No UPI app found on this device.');
    }
  }

  void showQr(
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

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
