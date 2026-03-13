import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/local_preferences.dart';

const _viewerTokenKey = 'nightradar.user.viewer_token';
const _likedEventsKey = 'nightradar.user.liked_events';

class EventLikePreferences {
  const EventLikePreferences({
    required this.viewerToken,
    this.likedEventIds = const {},
  });

  final String viewerToken;
  final Set<String> likedEventIds;

  bool hasLiked(String eventId) => likedEventIds.contains(eventId);

  EventLikePreferences copyWith({
    String? viewerToken,
    Set<String>? likedEventIds,
  }) {
    return EventLikePreferences(
      viewerToken: viewerToken ?? this.viewerToken,
      likedEventIds: likedEventIds ?? this.likedEventIds,
    );
  }
}

final eventLikePreferencesProvider = StateNotifierProvider<
    EventLikePreferencesController, EventLikePreferences>((ref) {
  return EventLikePreferencesController(ref.watch(sharedPreferencesProvider));
});

class EventLikePreferencesController
    extends StateNotifier<EventLikePreferences> {
  EventLikePreferencesController(this._preferences)
      : super(_loadInitialState(_preferences));

  final SharedPreferences? _preferences;

  static EventLikePreferences _loadInitialState(
    SharedPreferences? preferences,
  ) {
    final viewerToken =
        preferences?.getString(_viewerTokenKey) ?? _generateViewerToken();
    preferences?.setString(_viewerTokenKey, viewerToken);

    final rawLikes = preferences?.getString(_likedEventsKey);
    final likedEventIds = <String>{};
    if (rawLikes != null && rawLikes.isNotEmpty) {
      final decoded = jsonDecode(rawLikes);
      if (decoded is List<dynamic>) {
        for (final item in decoded) {
          final eventId = item?.toString().trim() ?? '';
          if (eventId.isNotEmpty) {
            likedEventIds.add(eventId);
          }
        }
      }
    }

    return EventLikePreferences(
      viewerToken: viewerToken,
      likedEventIds: likedEventIds,
    );
  }

  Future<void> setLiked(String eventId, bool liked) async {
    final next = Set<String>.from(state.likedEventIds);
    if (liked) {
      next.add(eventId);
    } else {
      next.remove(eventId);
    }

    state = state.copyWith(likedEventIds: next);
    await _preferences?.setString(_likedEventsKey, jsonEncode(next.toList()));
  }

  static String _generateViewerToken() {
    final random = Random.secure();
    final first = random.nextInt(1 << 32).toRadixString(16).padLeft(8, '0');
    final second = random.nextInt(1 << 32).toRadixString(16).padLeft(8, '0');
    final millis = DateTime.now().millisecondsSinceEpoch.toRadixString(16);
    return 'viewer-$millis-$first$second';
  }
}
