import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:nightradar/features/promoter/guest_list_exporter.dart';
import 'package:nightradar/shared/models.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('it_IT');
  });

  test('buildGuestListExport produces a shareable event list', () {
    final profile = AppProfile(
      id: 'profile-1',
      fullName: 'Marco Bianchi',
      role: AppRole.promoter,
    );
    final event = EventSummary(
      id: 'event-1',
      venueId: 'venue-1',
      title: 'Friday Signal',
      venueName: 'Volt Club Milano',
      city: 'Milano',
      startsAt: DateTime(2026, 3, 20, 23, 30),
      radarLabel: 'hot',
      radarScore: 72,
    );
    final reservations = [
      ReservationRecord(
        id: 'reservation-1',
        eventId: 'event-1',
        eventTitle: 'Friday Signal',
        venueName: 'Volt Club Milano',
        startsAt: DateTime(2026, 3, 20, 23, 30),
        guestName: 'Alice',
        partySize: 3,
        status: 'approved',
        notes: 'Arriva tardi',
      ),
      ReservationRecord(
        id: 'reservation-2',
        eventId: 'event-1',
        eventTitle: 'Friday Signal',
        venueName: 'Volt Club Milano',
        startsAt: DateTime(2026, 3, 20, 23, 30),
        guestName: 'Bruno',
        partySize: 2,
        status: 'checked_in',
      ),
    ];

    final export = buildGuestListExport(
      profile: profile,
      event: event,
      reservations: reservations,
    );

    expect(export, contains('Night Radar'));
    expect(export, contains('Friday Signal'));
    expect(export, contains('PR: Marco Bianchi'));
    expect(export, contains('Nominativi: 2'));
    expect(export, contains('Persone: 5'));
    expect(export, contains('1. Alice - 3 pax - APPROVED'));
    expect(export, contains('Note: Arriva tardi'));
    expect(export, contains('2. Bruno - 2 pax - CHECKED_IN'));
  });
}
