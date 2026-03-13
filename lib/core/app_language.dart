import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'local_preferences.dart';

const _languageCodeKey = 'nightradar.language_code';

enum AppLanguage {
  italian('it', 'IT', 'Italiano'),
  english('en', 'EN', 'English');

  const AppLanguage(this.languageCode, this.shortLabel, this.nativeLabel);

  final String languageCode;
  final String shortLabel;
  final String nativeLabel;

  Locale get locale => Locale(languageCode);

  static const supportedLocales = [
    Locale('it'),
    Locale('en'),
  ];

  static AppLanguage fromCode(String? code) {
    return switch (code) {
      'en' => AppLanguage.english,
      _ => AppLanguage.italian,
    };
  }

  static AppLanguage fromLocale(Locale locale) {
    return fromCode(locale.languageCode);
  }
}

final appLanguageProvider =
    StateNotifierProvider<AppLanguageController, Locale>((ref) {
      return AppLanguageController(ref.watch(sharedPreferencesProvider));
    });

class AppLanguageController extends StateNotifier<Locale> {
  AppLanguageController(this._preferences)
    : super(
        AppLanguage.fromCode(
          _preferences?.getString(_languageCodeKey),
        ).locale,
      );

  final SharedPreferences? _preferences;

  AppLanguage get currentLanguage => AppLanguage.fromLocale(state);

  Future<void> setLanguage(AppLanguage language) async {
    if (state.languageCode == language.languageCode) {
      return;
    }

    await _preferences?.setString(_languageCodeKey, language.languageCode);
    state = language.locale;
  }

  Future<void> toggleLanguage() {
    return setLanguage(
      currentLanguage == AppLanguage.italian
          ? AppLanguage.english
          : AppLanguage.italian,
    );
  }
}
