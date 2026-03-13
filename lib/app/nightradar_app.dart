import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_language.dart';
import '../core/app_flavor.dart';
import '../core/app_router.dart';
import '../core/app_theme.dart';

class NightRadarApp extends ConsumerWidget {
  const NightRadarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(appLanguageProvider);

    return MaterialApp.router(
      title: AppFlavorConfig.appTitle,
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: AppLanguage.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}
