import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:nightradar/core/app_copy.dart';
import 'package:nightradar/features/promoter/promoter_event_exports.dart';
import 'package:nightradar/shared/models.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('it_IT');
    await initializeDateFormatting('en_US');
  });

  test('buildPromoterEventPromoText creates a shareable promoter caption', () {
    final copy = AppCopy(const Locale('it'));
    final profile = AppProfile(
      id: 'profile-1',
      fullName: 'Marco Night',
      role: AppRole.promoter,
    );
    final event = EventSummary(
      id: 'event-1',
      venueId: 'venue-1',
      title: 'Signal Future',
      venueName: 'Volt Club Milano',
      city: 'Milano',
      startsAt: DateTime(2026, 5, 20, 23, 30),
      radarLabel: 'hot',
      radarScore: 80,
      minimumAge: 18,
      promoCaption: 'House all night, lista ridotta e tavoli.',
    );
    final offers = [
      EventOffer(
        id: 'offer-1',
        eventId: 'event-1',
        title: 'Lista ridotta',
        type: 'guest_list_reduced',
        price: 15,
      ),
      EventOffer(
        id: 'offer-2',
        eventId: 'event-1',
        title: 'Tavolo',
        type: 'table',
        price: 250,
      ),
    ];

    final text = buildPromoterEventPromoText(
      copy: copy,
      profile: profile,
      event: event,
      offers: offers,
    );

    expect(text, contains('Signal Future'));
    expect(text, contains('Volt Club Milano - Milano'));
    expect(text, contains('House all night, lista ridotta e tavoli.'));
    expect(text, contains('Lista ridotta, Tavolo'));
  });

  test('buildVenueDeliveryExport creates a venue-ready summary', () {
    final copy = AppCopy(const Locale('en'));
    final profile = AppProfile(
      id: 'profile-1',
      fullName: 'Marco Night',
      role: AppRole.promoter,
    );
    final event = EventSummary(
      id: 'event-1',
      venueId: 'venue-1',
      title: 'Signal Future',
      venueName: 'Volt Club Milano',
      city: 'Milano',
      startsAt: DateTime(2026, 5, 20, 23, 30),
      radarLabel: 'hot',
      radarScore: 80,
    );
    final offers = [
      EventOffer(
        id: 'offer-1',
        eventId: 'event-1',
        title: 'VIP Entry',
        type: 'vip_pass',
        price: 35,
      ),
    ];
    final reservations = [
      ReservationRecord(
        id: 'reservation-1',
        eventId: 'event-1',
        eventTitle: 'Signal Future',
        venueName: 'Volt Club Milano',
        startsAt: DateTime(2026, 5, 20, 23, 30),
        guestName: 'Luca',
        guestLastName: 'Rossi',
        partySize: 2,
        status: 'approved',
        offerTitle: 'VIP Entry',
      ),
    ];

    final text = buildVenueDeliveryExport(
      copy: copy,
      profile: profile,
      event: event,
      offers: offers,
      reservations: reservations,
      contactRequests: const [],
    );

    expect(text, contains('NightRadar operational delivery to venue'));
    expect(text, contains('Delivered guest entries: 1'));
    expect(text, contains('Luca Rossi - 2 pax - APPROVED - VIP Entry'));
  });
}
