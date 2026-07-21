/// Launches an external URI (e.g. a UPI payment app).
abstract class UrlLauncherService {
  /// Returns false if no app on the device could handle the URI.
  Future<bool> launch(Uri uri);
}
