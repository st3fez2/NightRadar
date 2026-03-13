import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models.dart';

class NightRadarRepository {
  NightRadarRepository(this._client);

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;

  Future<void> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  }) {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<AppProfile?> getCurrentProfile() async {
    final user = currentUser;
    if (user == null) {
      return null;
    }

    final row = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (row == null) {
      return null;
    }

    return AppProfile.fromMap(row);
  }

  Future<String?> getCurrentPromoterId() async {
    final user = currentUser;
    if (user == null) {
      return null;
    }

    final row = await _client
        .from('promoters')
        .select('id')
        .eq('profile_id', user.id)
        .maybeSingle();

    return row?['id'] as String?;
  }

  Future<List<EventSummary>> fetchEventFeed() async {
    final eventRows = await _client
        .from('events')
        .select(
          'id, venue_id, title, event_date, starts_at, description, music_tags, '
          'entry_policy, status, cover_image_url, '
          'venue:venues!events_venue_id_fkey(id, name, city, address_line, dress_code, price_band)',
        )
        .eq('is_public', true)
        .inFilter('status', ['published', 'live'])
        .order('starts_at');

    final eventMaps = eventRows.cast<Map<String, dynamic>>();

    if (eventMaps.isEmpty) {
      return const [];
    }

    final eventIds = eventMaps.map((event) => event['id'] as String).toList();
    final radarByEventId = await _fetchRadarMap(eventIds);
    final offersByEventId = await _fetchOfferMap(eventIds);

    return eventMaps.map((event) {
      final id = event['id'] as String;
      final base = _buildEventSummary(
        event,
        radar: radarByEventId[id],
      );
      final offers = offersByEventId[id] ?? const <Map<String, dynamic>>[];

      if (offers.isEmpty) {
        return base;
      }

      final cheapest = offers
          .map((offer) => (offer['price'] as num?)?.toDouble() ?? 0)
          .reduce(min);

      return base.copyWith(
        bestOfferPrice: cheapest,
        offerCount: offers.length,
      );
    }).toList();
  }

  Future<EventDetails> fetchEventDetails(String eventId) async {
    final eventRow = await _client
        .from('events')
        .select(
          'id, venue_id, title, event_date, starts_at, description, lineup, '
          'music_tags, entry_policy, status, cover_image_url, '
          'venue:venues!events_venue_id_fkey(id, name, city, address_line, dress_code, price_band)',
        )
        .eq('id', eventId)
        .single();

    final radarRows = await _client
        .from('event_radar_live')
        .select('event_id, radar_label, radar_score')
        .eq('event_id', eventId)
        .maybeSingle();

    final offerRows = await _client
        .from('event_offers')
        .select(
          'id, event_id, promoter_id, type, title, description, price, valid_until, conditions, '
          'promoter:promoters!event_offers_promoter_id_fkey(id, display_name, rating)',
        )
        .eq('event_id', eventId)
        .eq('is_active', true)
        .order('price');

    final availabilityRows = await _client
        .from('event_offer_availability')
        .select('offer_id, spots_left')
        .eq('event_id', eventId);

    final spotsByOffer = {
      for (final row in (availabilityRows as List<dynamic>).cast<Map<String, dynamic>>())
        row['offer_id'] as String: row['spots_left'] as int?,
    };

    final offers = (offerRows as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map((offer) => EventOffer(
              id: offer['id'] as String,
              eventId: offer['event_id'] as String,
              promoterId: offer['promoter_id'] as String?,
              title: offer['title'] as String? ?? 'Offerta',
              type: offer['type'] as String? ?? 'guest_list_reduced',
              description: offer['description'] as String?,
              price: (offer['price'] as num?)?.toDouble() ?? 0,
              validUntil: _parseDateTime(offer['valid_until'] as String?),
              conditions: offer['conditions'] as String?,
              promoterName:
                  (offer['promoter'] as Map<String, dynamic>?)?['display_name']
                      as String?,
              promoterRating: ((offer['promoter']
                          as Map<String, dynamic>?)?['rating'] as num?)
                      ?.toDouble() ??
                  0,
              spotsLeft: spotsByOffer[offer['id'] as String],
            ))
        .toList();

    final summary = _buildEventSummary(
      eventRow,
      radar: radarRows,
      bestOfferPrice: offers.isEmpty
          ? null
          : offers.map((offer) => offer.price).reduce(min),
      offerCount: offers.length,
    );

    return EventDetails(
      summary: summary,
      venue: VenueInfo.fromMap(eventRow['venue'] as Map<String, dynamic>? ?? {}),
      offers: offers,
      description: eventRow['description'] as String?,
      lineup: eventRow['lineup'] as String?,
    );
  }

  Future<ReservationRecord> createReservation({
    required EventDetails event,
    EventOffer? offer,
    required String guestName,
    required String phone,
    required int partySize,
    String? notes,
  }) async {
    final profile = await getCurrentProfile();
    if (profile == null) {
      throw const AuthException('Utente non autenticato');
    }

    final inserted = await _client
        .from('reservations')
        .insert({
          'event_id': event.summary.id,
          'offer_id': offer?.id,
          'user_id': profile.id,
          'promoter_id': offer?.promoterId,
          'guest_name': guestName,
          'guest_phone': phone,
          'guest_email': profile.email,
          'party_size': partySize,
          'status': 'approved',
          'qr_expires_at': (offer?.validUntil ??
                  event.summary.startsAt.add(const Duration(hours: 4)))
              .toUtc()
              .toIso8601String(),
          'confirmed_at': DateTime.now().toUtc().toIso8601String(),
          'notes': notes,
          'created_by': profile.id,
        })
        .select('id')
        .single();

    return fetchReservationById(inserted['id'] as String);
  }

  Future<List<ReservationRecord>> fetchMyReservations() async {
    final user = currentUser;
    if (user == null) {
      return const [];
    }

    final rows = await _client
        .from('reservations')
        .select(
          'id, event_id, guest_name, party_size, status, qr_token, qr_expires_at, notes, '
          'event:events!reservations_event_id_fkey(id, title, starts_at, '
          'venue:venues!events_venue_id_fkey(name, city)), '
          'offer:event_offers!reservations_offer_id_fkey(title), '
          'promoter:promoters!reservations_promoter_id_fkey(display_name)',
        )
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return (rows as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(_mapReservation)
        .toList();
  }

  Future<ReservationRecord> fetchReservationById(String reservationId) async {
    final row = await _client
        .from('reservations')
        .select(
          'id, event_id, guest_name, party_size, status, qr_token, qr_expires_at, notes, '
          'event:events!reservations_event_id_fkey(id, title, starts_at, '
          'venue:venues!events_venue_id_fkey(name, city)), '
          'offer:event_offers!reservations_offer_id_fkey(title), '
          'promoter:promoters!reservations_promoter_id_fkey(display_name)',
        )
        .eq('id', reservationId)
        .single();

    return _mapReservation(row);
  }

  Future<PromoterDashboardData> fetchPromoterDashboard() async {
    final profile = await getCurrentProfile();
    final promoterId = await getCurrentPromoterId();

    if (profile == null || promoterId == null) {
      throw const AuthException('Profilo PR non disponibile');
    }

    final venueRows = await _client
        .from('venue_promoters')
        .select(
          'venue_id, venue:venues!venue_promoters_venue_id_fkey('
          'id, name, city, address_line, dress_code, price_band)',
        )
        .eq('promoter_id', promoterId)
        .eq('is_active', true);

    final venueMaps = (venueRows as List<dynamic>).cast<Map<String, dynamic>>();
    final venues = venueMaps
        .map((row) => VenueInfo.fromMap(row['venue'] as Map<String, dynamic>? ?? {}))
        .where((venue) => venue.id.isNotEmpty)
        .toList();
    final venueIds = venues.map((venue) => venue.id).toList();

    final eventRows = venueIds.isEmpty
        ? <dynamic>[]
        : await _client
            .from('events')
            .select(
              'id, venue_id, title, event_date, starts_at, description, music_tags, '
              'entry_policy, status, cover_image_url, '
              'venue:venues!events_venue_id_fkey(id, name, city, address_line, dress_code, price_band)',
            )
            .inFilter('venue_id', venueIds)
            .inFilter('status', ['published', 'live', 'completed'])
            .order('starts_at');

    final eventMaps = eventRows.cast<Map<String, dynamic>>();
    final eventIds = eventMaps.map((event) => event['id'] as String).toList();
    final radarByEventId = await _fetchRadarMap(eventIds);

    final reservationRows = eventIds.isEmpty
        ? <dynamic>[]
        : await _client
            .from('reservations')
            .select(
              'id, event_id, guest_name, party_size, status, qr_token, qr_expires_at, notes, '
              'event:events!reservations_event_id_fkey(id, title, starts_at, '
              'venue:venues!events_venue_id_fkey(name, city)), '
              'offer:event_offers!reservations_offer_id_fkey(title), '
              'promoter:promoters!reservations_promoter_id_fkey(display_name)',
            )
            .inFilter('event_id', eventIds)
            .order('created_at', ascending: false);

    final reservations = reservationRows
        .cast<Map<String, dynamic>>()
        .map(_mapReservation)
        .toList();

    final approvedCount =
        reservations.where((reservation) => reservation.status == 'approved').length;
    final checkedInCount =
        reservations.where((reservation) => reservation.status == 'checked_in').length;
    final requestedCount =
        reservations.where((reservation) => reservation.status == 'requested').length;

    return PromoterDashboardData(
      profile: profile,
      promoterId: promoterId,
      venues: venues,
      events: eventMaps
          .map((event) => _buildEventSummary(
                event,
                radar: radarByEventId[event['id'] as String],
              ))
          .toList(),
      reservations: reservations,
      stats: [
        DashboardStat(label: 'Approvati', value: '$approvedCount'),
        DashboardStat(label: 'Check-in', value: '$checkedInCount'),
        DashboardStat(label: 'In attesa', value: '$requestedCount'),
      ],
    );
  }

  Future<void> createManualReservation({
    required String eventId,
    String? offerId,
    required String guestName,
    required String phone,
    required int partySize,
  }) async {
    final profile = await getCurrentProfile();
    final promoterId = await getCurrentPromoterId();

    if (profile == null || promoterId == null) {
      throw const AuthException('Profilo PR non disponibile');
    }

    await _client.from('reservations').insert({
      'event_id': eventId,
      'offer_id': offerId,
      'promoter_id': promoterId,
      'guest_name': guestName,
      'guest_phone': phone,
      'party_size': partySize,
      'status': 'approved',
      'confirmed_at': DateTime.now().toUtc().toIso8601String(),
      'created_by': profile.id,
      'qr_expires_at':
          DateTime.now().toUtc().add(const Duration(hours: 8)).toIso8601String(),
    });
  }

  Future<void> createPromoterEvent({
    required String venueId,
    required String title,
    required DateTime startsAt,
    required String genre,
    String? description,
  }) async {
    final profile = await getCurrentProfile();
    final promoterId = await getCurrentPromoterId();

    if (profile == null || promoterId == null) {
      throw const AuthException('Profilo PR non disponibile');
    }

    await _client.from('events').insert({
      'venue_id': venueId,
      'title': title,
      'event_date': startsAt.toIso8601String().substring(0, 10),
      'starts_at': startsAt.toUtc().toIso8601String(),
      'ends_at': startsAt.toUtc().add(const Duration(hours: 6)).toIso8601String(),
      'description': description ?? 'Evento creato e gestito dal PR su NightRadar.',
      'music_tags': [genre],
      'status': 'published',
      'entry_policy': 'Lista NightRadar e nominativi condivisi con il locale.',
      'is_public': true,
      'created_by': profile.id,
    });
  }

  Future<void> updateReservationStatus({
    required String reservationId,
    required String status,
  }) {
    final payload = <String, dynamic>{'status': status};
    if (status == 'approved') {
      payload['confirmed_at'] = DateTime.now().toUtc().toIso8601String();
    }

    return _client
        .from('reservations')
        .update(payload)
        .eq('id', reservationId);
  }

  ReservationRecord _mapReservation(Map<String, dynamic> row) {
    final event = row['event'] as Map<String, dynamic>? ?? {};
    final venue =
        (event['venue'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final offer = row['offer'] as Map<String, dynamic>?;
    final promoter = row['promoter'] as Map<String, dynamic>?;

    return ReservationRecord(
      id: row['id'] as String,
      eventId: row['event_id'] as String,
      eventTitle: event['title'] as String? ?? 'Evento',
      venueName: venue['name'] as String? ?? 'Venue',
      city: venue['city'] as String?,
      startsAt: _parseDateTime(event['starts_at'] as String?) ?? DateTime.now(),
      guestName: row['guest_name'] as String? ?? 'Guest',
      partySize: row['party_size'] as int? ?? 1,
      status: row['status'] as String? ?? 'requested',
      qrToken: row['qr_token'] as String?,
      qrExpiresAt: _parseDateTime(row['qr_expires_at'] as String?),
      offerTitle: offer?['title'] as String?,
      promoterName: promoter?['display_name'] as String?,
      notes: row['notes'] as String?,
    );
  }

  EventSummary _buildEventSummary(
    Map<String, dynamic> row, {
    Map<String, dynamic>? radar,
    double? bestOfferPrice,
    int offerCount = 0,
  }) {
    final venue = VenueInfo.fromMap(row['venue'] as Map<String, dynamic>? ?? {});
    final eventDate = row['event_date'] as String?;

    return EventSummary(
      id: row['id'] as String,
      venueId: row['venue_id'] as String? ?? venue.id,
      title: row['title'] as String? ?? 'NightRadar Event',
      venueName: venue.name,
      city: venue.city,
      startsAt: _parseDateTime(row['starts_at'] as String?) ?? DateTime.now(),
      eventDate: eventDate == null ? null : DateTime.tryParse(eventDate),
      radarLabel: radar?['radar_label'] as String? ?? 'easy',
      radarScore: radar?['radar_score'] as num? ?? 0,
      description: row['description'] as String?,
      coverImageUrl: row['cover_image_url'] as String?,
      musicTags: ((row['music_tags'] as List<dynamic>?) ?? const [])
          .map((tag) => tag.toString())
          .toList(),
      entryPolicy: row['entry_policy'] as String?,
      bestOfferPrice: bestOfferPrice,
      offerCount: offerCount,
    );
  }

  Future<Map<String, Map<String, dynamic>>> _fetchRadarMap(
    List<String> eventIds,
  ) async {
    if (eventIds.isEmpty) {
      return const {};
    }

    final rows = await _client
        .from('event_radar_live')
        .select('event_id, radar_label, radar_score')
        .inFilter('event_id', eventIds);

    return {
      for (final row in (rows as List<dynamic>).cast<Map<String, dynamic>>())
        row['event_id'] as String: row,
    };
  }

  Future<Map<String, List<Map<String, dynamic>>>> _fetchOfferMap(
    List<String> eventIds,
  ) async {
    if (eventIds.isEmpty) {
      return const {};
    }

    final rows = await _client
        .from('event_offers')
        .select('event_id, price')
        .inFilter('event_id', eventIds)
        .eq('is_active', true);

    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final row in (rows as List<dynamic>).cast<Map<String, dynamic>>()) {
      final eventId = row['event_id'] as String;
      grouped.putIfAbsent(eventId, () => []);
      grouped[eventId]!.add(row);
    }

    return grouped;
  }

  DateTime? _parseDateTime(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value)?.toLocal();
  }
}
