import 'package:flutter/foundation.dart';

class PublicLinkConfig {
  static const fallbackUrl = String.fromEnvironment(
    'PUBLIC_APP_URL',
    defaultValue: 'https://st3fez2.github.io/NightRadar/',
  );

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
