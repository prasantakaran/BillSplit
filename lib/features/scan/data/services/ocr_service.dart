import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// On-device text recognition for bill photos via Google ML Kit.
///
/// The only class that talks to ML Kit. On-device means it is free, fast,
/// works offline, and bill photos never leave the phone.
class OcrService {
  final TextRecognizer _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  /// Runs OCR on the image at [imagePath] and returns text reassembled into
  /// visual rows, ready for BillParser.
  Future<String> extractText(String imagePath) async {
    final InputImage image = InputImage.fromFilePath(imagePath);
    final RecognizedText result = await _recognizer.processImage(image);
    return _reconstructRows(result);
  }

  /// ML Kit groups tabular receipts into column blocks, so [RecognizedText.text]
  /// returns all item names followed by all prices instead of "name price"
  /// rows. Rebuild the visual rows instead: collect every text line with its
  /// bounding box, cluster lines whose vertical centres overlap, and join
  /// each cluster left-to-right.
  String _reconstructRows(RecognizedText recognized) {
    final List<TextLine> lines = [
      for (final TextBlock block in recognized.blocks) ...block.lines,
    ];
    if (lines.isEmpty) {
      return '';
    }

    lines.sort(
      (a, b) => a.boundingBox.center.dy.compareTo(b.boundingBox.center.dy),
    );

    final List<List<TextLine>> rows = [];
    for (final TextLine line in lines) {
      final double centerY = line.boundingBox.center.dy;
      if (rows.isNotEmpty) {
        final List<TextLine> currentRow = rows.last;
        final double rowCenterY = currentRow
                .map((l) => l.boundingBox.center.dy)
                .reduce((a, b) => a + b) /
            currentRow.length;
        final double tolerance = line.boundingBox.height * 0.6;
        if ((centerY - rowCenterY).abs() <= tolerance) {
          currentRow.add(line);
          continue;
        }
      }
      rows.add([line]);
    }

    final StringBuffer buffer = StringBuffer();
    for (final List<TextLine> row in rows) {
      row.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
      buffer.writeln(row.map((l) => l.text).join(' '));
    }
    return buffer.toString();
  }

  /// Releases the native recognizer.
  Future<void> dispose() => _recognizer.close();
}
