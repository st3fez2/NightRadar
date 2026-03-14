import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nightradar/features/events/presentation/user_discovery_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('user discovery preferences ignore invalid trusted promoter json', () async {
    SharedPreferences.setMockInitialValues({
      'nightradar.user.trusted_promoters': '{broken-json',
    });
    final sharedPreferences = await SharedPreferences.getInstance();

    final controller = UserDiscoveryPreferencesController(sharedPreferences);

    expect(controller.state.trustedPromoters, isEmpty);
    expect(
      sharedPreferences.getString('nightradar.user.trusted_promoters'),
      isNull,
    );
  });

  test('user discovery preferences persist trusted promoter toggles', () async {
    final sharedPreferences = await SharedPreferences.getInstance();
    final controller = UserDiscoveryPreferencesController(sharedPreferences);

    await controller.toggleTrustedPromoter(
      promoterId: 'pr-1',
      promoterName: 'Marco Night',
    );

    expect(controller.state.trustedPromoters['pr-1'], 'Marco Night');
    expect(
      sharedPreferences.getString('nightradar.user.trusted_promoters'),
      contains('pr-1'),
    );
  });
}
