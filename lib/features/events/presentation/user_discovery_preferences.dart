import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/local_preferences.dart';

const _timePlanKey = 'nightradar.user.time_plan';
const _maxDriveMinutesKey = 'nightradar.user.max_drive_minutes';
const _originCityKey = 'nightradar.user.origin_city';
const _trustedPromotersKey = 'nightradar.user.trusted_promoters';

enum UserEventTimePlan {
  tonight('tonight'),
  tomorrow('tomorrow'),
  flexible('flexible');

  const UserEventTimePlan(this.value);

  final String value;

  static UserEventTimePlan fromValue(String? value) {
    return switch (value) {
      'tonight' => UserEventTimePlan.tonight,
      'tomorrow' => UserEventTimePlan.tomorrow,
      _ => UserEventTimePlan.flexible,
    };
  }
}

class UserDiscoveryPreferences {
  const UserDiscoveryPreferences({
    this.timePlan = UserEventTimePlan.flexible,
    this.maxDriveMinutes = 45,
    this.originCity,
    this.trustedPromoters = const {},
  });

  final UserEventTimePlan timePlan;
  final int? maxDriveMinutes;
  final String? originCity;
  final Map<String, String> trustedPromoters;

  Set<String> get trustedPromoterIds => trustedPromoters.keys.toSet();

  bool isTrustedPromoter(String? promoterId) {
    return promoterId != null && trustedPromoters.containsKey(promoterId);
  }

  UserDiscoveryPreferences copyWith({
    UserEventTimePlan? timePlan,
    int? maxDriveMinutes,
    bool clearMaxDriveMinutes = false,
    String? originCity,
    bool clearOriginCity = false,
    Map<String, String>? trustedPromoters,
  }) {
    return UserDiscoveryPreferences(
      timePlan: timePlan ?? this.timePlan,
      maxDriveMinutes: clearMaxDriveMinutes
          ? null
          : maxDriveMinutes ?? this.maxDriveMinutes,
      originCity: clearOriginCity ? null : originCity ?? this.originCity,
      trustedPromoters: trustedPromoters ?? this.trustedPromoters,
    );
  }
}

final userDiscoveryPreferencesProvider = StateNotifierProvider<
    UserDiscoveryPreferencesController, UserDiscoveryPreferences>((ref) {
  return UserDiscoveryPreferencesController(
    ref.watch(sharedPreferencesProvider),
  );
});

class UserDiscoveryPreferencesController
    extends StateNotifier<UserDiscoveryPreferences> {
  UserDiscoveryPreferencesController(this._preferences)
      : super(_loadInitialState(_preferences));

  final SharedPreferences? _preferences;

  static UserDiscoveryPreferences _loadInitialState(
    SharedPreferences? preferences,
  ) {
    final trustedRaw = preferences?.getString(_trustedPromotersKey);
    final trustedPromoters = <String, String>{};
    if (trustedRaw != null && trustedRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(trustedRaw);
        if (decoded is Map<String, dynamic>) {
          for (final entry in decoded.entries) {
            final key = entry.key.trim();
            final value = entry.value?.toString().trim() ?? '';
            if (key.isEmpty || value.isEmpty) {
              continue;
            }
            trustedPromoters[key] = value;
          }
        }
      } on FormatException {
        preferences?.remove(_trustedPromotersKey);
      }
    }

    return UserDiscoveryPreferences(
      timePlan: UserEventTimePlan.fromValue(
        preferences?.getString(_timePlanKey),
      ),
      maxDriveMinutes: preferences?.getInt(_maxDriveMinutesKey) ?? 45,
      originCity: _nullIfBlank(preferences?.getString(_originCityKey)),
      trustedPromoters: trustedPromoters,
    );
  }

  Future<void> setTimePlan(UserEventTimePlan plan) async {
    state = state.copyWith(timePlan: plan);
    await _preferences?.setString(_timePlanKey, plan.value);
  }

  Future<void> setMaxDriveMinutes(int? maxDriveMinutes) async {
    state = state.copyWith(
      maxDriveMinutes: maxDriveMinutes,
      clearMaxDriveMinutes: maxDriveMinutes == null,
    );

    if (maxDriveMinutes == null) {
      await _preferences?.remove(_maxDriveMinutesKey);
      return;
    }

    await _preferences?.setInt(_maxDriveMinutesKey, maxDriveMinutes);
  }

  Future<void> setOriginCity(String? originCity) async {
    final normalized = _nullIfBlank(originCity);
    state = state.copyWith(
      originCity: normalized,
      clearOriginCity: normalized == null,
    );

    if (normalized == null) {
      await _preferences?.remove(_originCityKey);
      return;
    }

    await _preferences?.setString(_originCityKey, normalized);
  }

  Future<void> toggleTrustedPromoter({
    required String promoterId,
    required String promoterName,
  }) async {
    final next = Map<String, String>.from(state.trustedPromoters);
    if (next.containsKey(promoterId)) {
      next.remove(promoterId);
    } else {
      next[promoterId] = promoterName;
    }

    state = state.copyWith(trustedPromoters: next);
    await _preferences?.setString(_trustedPromotersKey, jsonEncode(next));
  }

  static String? _nullIfBlank(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }
}
