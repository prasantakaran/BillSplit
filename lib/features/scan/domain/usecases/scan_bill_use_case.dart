import 'package:bill_split/features/scan/data/model/parse_bill_model.dart';

import '../bill_parser.dart';
import '../services/ocr_service.dart';

// This is the single entry point the presentation layer calls;
// it hides the two-step pipeline behind one call(imagePath).

// O — Open/Closed

class ScanBillUseCase {
  final OcrService _ocrService;

  ScanBillUseCase(this._ocrService);

  Future<ParsedBill> call(String imagePath) async {
    final String rawText = await _ocrService.extractText(imagePath);
    return BillParser.parse(rawText);
  }
}
