/// Shares text content via the platform's share sheet.
abstract class SharingService {
  Future<void> share(String text);
}
