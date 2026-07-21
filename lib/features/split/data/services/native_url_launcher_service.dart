import 'package:url_launcher/url_launcher.dart' as launcher;

import '../../domain/services/url_launcher_service.dart';

/// [UrlLauncherService] backed by the url_launcher plugin.
class NativeUrlLauncherService implements UrlLauncherService {
  @override
  Future<bool> launch(Uri uri) {
    return launcher.launchUrl(uri, mode: launcher.LaunchMode.externalApplication);
  }
}
