import 'package:share_plus/share_plus.dart';

class ShareStore {
  static Uri? buildUri(String businessId) {
    final normalizedId = businessId.trim().toLowerCase();
    if (normalizedId.isEmpty || normalizedId == 'null') return null;
    if (normalizedId.length > 20 ||
        !RegExp(r'^[a-z0-9](?:[a-z0-9-]*[a-z0-9])?$').hasMatch(normalizedId)) {
      return null;
    }
    return Uri.https('$normalizedId.asoud.ir', '/');
  }

  static Future<bool> share(String businessId) async {
    final uri = buildUri(businessId);
    if (uri == null) return false;

    try {
      final result = await SharePlus.instance.share(
        ShareParams(text: uri.toString()),
      );
      return result.status != ShareResultStatus.unavailable;
    } catch (_) {
      return false;
    }
  }
}
