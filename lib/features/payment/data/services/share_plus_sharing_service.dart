import 'package:share_plus/share_plus.dart';

import '../../domain/services/sharing_service.dart';

/// [SharingService] backed by the share_plus plugin.
class SharePlusSharingService implements SharingService {
  @override
  Future<void> share(String text) {
    return SharePlus.instance.share(ShareParams(text: text));
  }
}
