import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nightradar/features/events/presentation/event_like_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('event like preferences initialize a viewer token without crashing', () async {
    final sharedPreferences = await SharedPreferences.getInstance();

    final controller = EventLikePreferencesController(sharedPreferences);

    expect(controller.state.viewerToken, startsWith('viewer-'));
    expect(controller.state.viewerToken.length, greaterThan('viewer-'.length));
    expect(controller.state.likedEventIds, isEmpty);
  });

  test('event like preferences persist liked event ids', () async {
    final sharedPreferences = await SharedPreferences.getInstance();
    final controller = EventLikePreferencesController(sharedPreferences);

    await controller.setLiked('event-1', true);

    expect(controller.state.likedEventIds, contains('event-1'));
    expect(
      sharedPreferences.getString('nightradar.user.liked_events'),
      contains('event-1'),
    );
  });

  test('event like preferences ignore invalid stored liked event json', () async {
    SharedPreferences.setMockInitialValues({
      'nightradar.user.liked_events': '{not-json',
    });
    final sharedPreferences = await SharedPreferences.getInstance();

    final controller = EventLikePreferencesController(sharedPreferences);

    expect(controller.state.likedEventIds, isEmpty);
    expect(sharedPreferences.getString('nightradar.user.liked_events'), isNull);
  });
}
