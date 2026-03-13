import 'package:flutter/foundation.dart';

import 'app_flavor.dart';

class PublicLinkConfig {
  static String get fallbackUrl => AppFlavorConfig.defaultPublicAppUrl;

  static String resolveAppUrl() {
    if (kIsWeb) {
      final base = Uri.base;
      final normalizedPath = base.path.endsWith('/')
          ? base.path
          : '${base.path}/';

      return Uri(
        scheme: base.scheme,
        host: base.host,
        port: base.hasPort ? base.port : null,
        path: normalizedPath,
      ).toString();
    }

    return fallbackUrl;
  }
}
