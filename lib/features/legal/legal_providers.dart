import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/local_preferences.dart';
import '../../shared/legal_constants.dart';

const _localLegalVersionKey = 'nightradar.local_legal_version';

final localLegalConsentProvider =
    StateNotifierProvider<LocalLegalConsentController, bool>((ref) {
      return LocalLegalConsentController(ref.watch(sharedPreferencesProvider));
    });

class LocalLegalConsentController extends StateNotifier<bool> {
  LocalLegalConsentController(this._preferences)
    : super(
        _preferences?.getString(_localLegalVersionKey) ==
            nightRadarLegalVersion,
      );

  final SharedPreferences? _preferences;

  Future<void> acceptCurrentVersion() async {
    await _preferences?.setString(_localLegalVersionKey, nightRadarLegalVersion);
    state = true;
  }
}
