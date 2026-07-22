/// Launches an external URI (e.g. a UPI payment app).
abstract class UrlLauncherService {
  Future<bool> launch(Uri uri);
}
