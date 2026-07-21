import '../bill_parser.dart';
import '../services/ocr_service.dart';

class ScanBillUseCase {
  ScanBillUseCase(this._ocrService);

  final OcrService _ocrService;

  Future<ParsedBill> call(String imagePath) async {
    final String rawText = await _ocrService.extractText(imagePath);
    return BillParser.parse(rawText);
  }
}
