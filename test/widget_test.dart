import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:nightradar/core/app_providers.dart';
import 'package:nightradar/core/widgets/common_widgets.dart';
import 'package:nightradar/core/widgets/public_link_card.dart';
import 'package:nightradar/features/auth/auth_screen.dart';
import 'package:nightradar/features/public/public_home_screen.dart';
import 'package:nightradar/shared/models.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('it_IT');
  });

  testWidgets('auth screen exposes demo accounts', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AuthScreen())),
    );

    expect(find.text('NightRadar MVP'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.textContaining('user@nightradar.app'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('user@nightradar.app'), findsOneWidget);
    expect(find.textContaining('promoter@nightradar.app'), findsOneWidget);
    expect(find.textContaining('venue@nightradar.app'), findsNothing);
    expect(find.textContaining('staff@nightradar.app'), findsNothing);
  });

  testWidgets('radar chip formats label for UI', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: RadarChip(label: 'near_full')),
      ),
    );

    expect(find.text('NEAR FULL'), findsOneWidget);
  });

  testWidgets('public link card shows live actions and fallback url', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: PublicLinkCard(),
            ),
          ),
        ),
      ),
    );

    expect(find.text('QR pubblico NightRadar'), findsOneWidget);
    expect(find.text('Condividi QR'), findsOneWidget);
    expect(find.text('Scarica'), findsOneWidget);
    expect(find.text('https://st3fez2.github.io/NightRadar/'), findsOneWidget);
  });

  testWidgets('public home keeps QR and highlights visible', (tester) async {
    final events = [
      EventSummary(
        id: 'event-1',
        venueId: 'venue-1',
        title: 'Friday Signal',
        venueName: 'Volt Club Milano',
        city: 'Milano',
        startsAt: DateTime(2026, 3, 20, 23, 30),
        radarLabel: 'hot',
        radarScore: 78,
        musicTags: const ['house'],
        bestOfferPrice: 20,
        offerCount: 2,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          eventFeedProvider.overrideWith((ref) async => events),
          currentProfileProvider.overrideWith((ref) async => null),
        ],
        child: const MaterialApp(home: PublicHomeScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Main page con QR sempre pronto'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Serate live in evidenza'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Serate live in evidenza'), findsOneWidget);
    expect(find.text('Friday Signal'), findsOneWidget);
  });
}
