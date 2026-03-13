import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nightradar/core/local_preferences.dart';
import 'package:nightradar/core/app_providers.dart';
import 'package:nightradar/core/widgets/common_widgets.dart';
import 'package:nightradar/core/widgets/public_link_card.dart';
import 'package:nightradar/features/auth/auth_screen.dart';
import 'package:nightradar/features/events/presentation/user_home_screen.dart';
import 'package:nightradar/features/legal/legal_consent_screen.dart';
import 'package:nightradar/features/public/public_home_screen.dart';
import 'package:nightradar/shared/models.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('it_IT');
    await initializeDateFormatting('en_US');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestApp(Widget child, {Locale locale = const Locale('it')}) {
    return MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('it'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: child,
    );
  }

  testWidgets('auth screen exposes active auth flow in prod', (tester) async {
    final sharedPreferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        ],
        child: buildTestApp(const AuthScreen()),
      ),
    );

    expect(find.text('NightRadar MVP'), findsOneWidget);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Registrati'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Registrati'), findsOneWidget);
    expect(find.text('Richiedi account PR'), findsOneWidget);
    expect(find.textContaining('user@nightradar.app'), findsNothing);
    expect(find.textContaining('promoter@nightradar.app'), findsNothing);
  });

  testWidgets('auth screen exposes promoter request flow', (tester) async {
    final sharedPreferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        ],
        child: buildTestApp(const AuthScreen()),
      ),
    );

    await tester.scrollUntilVisible(
      find.text('Richiedi account PR'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Richiedi account PR'));
    await tester.pumpAndSettle();

    expect(find.text('Richiesta account PR'), findsOneWidget);
    expect(find.text('Invia richiesta PR'), findsOneWidget);
  });

  testWidgets('radar chip formats label for UI', (tester) async {
    await tester.pumpWidget(
      buildTestApp(
        const Scaffold(body: RadarChip(label: 'near_full')),
        locale: const Locale('en'),
      ),
    );

    expect(find.text('NEAR FULL'), findsOneWidget);
  });

  testWidgets('public link card shows live actions and fallback url', (
    tester,
  ) async {
    final sharedPreferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        ],
        child: buildTestApp(
          const Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: PublicLinkCard(),
              ),
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
    final sharedPreferences = await SharedPreferences.getInstance();
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
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          eventFeedProvider.overrideWith((ref) async => events),
          currentProfileProvider.overrideWith((ref) async => null),
        ],
        child: buildTestApp(const PublicHomeScreen()),
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

  testWidgets('legal gate exposes and toggles both acceptance checkboxes', (
    tester,
  ) async {
    final sharedPreferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        ],
        child: buildTestApp(const LegalConsentScreen(signedInOverride: false)),
      ),
    );

    await tester.scrollUntilVisible(
      find.textContaining('Accetto il disclaimer operativo'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final firstCheckbox = tester.widget<CheckboxListTile>(
      find.byType(CheckboxListTile).first,
    );
    final secondCheckbox = tester.widget<CheckboxListTile>(
      find.byType(CheckboxListTile).last,
    );
    expect(firstCheckbox.value, isFalse);
    expect(secondCheckbox.value, isFalse);

    await tester.tap(find.byType(CheckboxListTile).first);
    await tester.pump();

    await tester.tap(find.byType(CheckboxListTile).last);
    await tester.pump();

    final enabledFirstCheckbox = tester.widget<CheckboxListTile>(
      find.byType(CheckboxListTile).first,
    );
    final enabledSecondCheckbox = tester.widget<CheckboxListTile>(
      find.byType(CheckboxListTile).last,
    );
    expect(enabledFirstCheckbox.value, isTrue);
    expect(enabledSecondCheckbox.value, isTrue);
  });

  testWidgets('user home supports planning for tonight and trusted promoters', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'nightradar.user.trusted_promoters': '{"pr-1":"Marco Night"}',
    });
    final sharedPreferences = await SharedPreferences.getInstance();
    final startsAt = DateTime.now().add(const Duration(hours: 6));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          currentProfileProvider.overrideWith(
            (ref) async => AppProfile(
              id: 'user-1',
              fullName: 'Luca Rossi',
              role: AppRole.user,
              city: 'Milano',
            ),
          ),
          myReservationsProvider.overrideWith((ref) async => const []),
          eventFeedProvider.overrideWith(
            (ref) async => [
              EventSummary(
                id: 'event-1',
                venueId: 'venue-1',
                title: 'Friday Signal',
                venueName: 'Volt Club Milano',
                city: 'Milano',
                startsAt: startsAt,
                radarLabel: 'hot',
                radarScore: 82,
                musicTags: const ['house'],
                bestOfferPrice: 20,
                offerCount: 3,
                primaryPromoterId: 'pr-1',
                primaryPromoterName: 'Marco Night',
                likeCount: 7,
              ),
            ],
          ),
        ],
        child: buildTestApp(const UserHomeScreen()),
      ),
    );

    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Planner rapido per due amici'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Planner rapido per due amici'), findsOneWidget);
    expect(find.text('PR fidati da tenere d occhio'), findsOneWidget);
    expect(find.text('Friday Signal'), findsAtLeastNWidgets(1));
  });
}
