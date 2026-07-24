abstract class OcrService {
  Future<String> extractText(String imagePath);

  Future<void> dispose();
}


// an abstract interface (extractText, dispose).
//The domain layer declares what it needs without knowing which OCR engine provides it.
//This is the Dependency Inversion piece: domain doesn't import google_mlkit_text_recognition at all.