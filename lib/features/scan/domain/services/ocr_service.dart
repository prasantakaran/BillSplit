abstract class OcrService {
  Future<String> extractText(String imagePath);

  Future<void> dispose();
}
// 