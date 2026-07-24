import 'package:flutter_test/flutter_test.dart';

import 'package:bill_split/features/scan/data/model/parse_bill_model.dart';
import 'package:bill_split/features/scan/domain/services/ocr_service.dart';
import 'package:bill_split/features/scan/domain/usecases/scan_bill_use_case.dart';

/// Stands in for ML Kit so the scan pipeline can be tested without a real
/// image, a device, or the platform text recogniser.
class FakeOcrService implements OcrService {
  FakeOcrService(this.text);

  final String text;

  String? lastImagePath;
  bool disposed = false;

  @override
  Future<String> extractText(String imagePath) async {
    lastImagePath = imagePath;
    return text;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

void main() {
  group('ScanBillUseCase', () {
    test('runs OCR output through the parser and returns a ParsedBill', () async {
      final fake = FakeOcrService('''
SPICE VILLA
Paneer Tikka    250.00
Dal Makhani     180.00
Subtotal        430.00
CGST 2.5%        10.75
SGST 2.5%        10.75
Grand Total     451.50
''');

      final ParsedBill parsed = await ScanBillUseCase(fake)('/tmp/bill.jpg');

      expect(parsed.items, hasLength(2));
      expect(parsed.items[0].name, 'Paneer Tikka');
      expect(parsed.items[0].price, 250.00);
      expect(parsed.items[1].name, 'Dal Makhani');
      expect(parsed.items[1].price, 180.00);
      expect(parsed.taxAmount, closeTo(21.50, 0.001));
      expect(parsed.detectedTotal, 451.50);
    });

    test('passes the image path straight through to the OCR service', () async {
      final fake = FakeOcrService('');

      await ScanBillUseCase(fake)('/storage/emulated/0/receipt.png');

      expect(fake.lastImagePath, '/storage/emulated/0/receipt.png');
    });

    test('an empty scan yields no items and no tax', () async {
      final ParsedBill parsed = await ScanBillUseCase(FakeOcrService(''))('x');

      expect(parsed.items, isEmpty);
      expect(parsed.taxAmount, 0);
    });
  });
}
