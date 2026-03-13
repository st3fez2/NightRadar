import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/app_flavor.dart';
import '../../../shared/legal_constants.dart';
import '../../../shared/models.dart';

class NightRadarRepository {
  NightRadarRepository(this._client);

  final SupabaseClient _client;
  static const _feedOfferSelect =
      'event_id, price, promoter_id, promoter:promoters!event_offers_promoter_id_fkey('
      'id, display_name, rating, is_verified)';
  static const _eventOfferSelect =
      'id, event_id, promoter_id, type, title, description, price, capacity_total, valid_until, '
      'conditions, collect_last_name, phone_requirement, allow_anonymous_entry, '
      'table_guest_capacity, show_public_availability, '
      'show_qr_on_entry, show_secret_code_on_entry, show_list_name_on_entry, '
      'requires_list_name, promoter:promoters!event_offers_promoter_id_fkey('
      'id, display_name, rating, bio, is_verified, avatar_url, public_phone, public_email, '
      'instagram_handle, tiktok_handle)';
  static const _reservationSelect =
      'id, event_id, offer_id, guest_name, guest_last_name, guest_phone, '
      'guest_email, list_name, is_anonymous_entry, participant_details, '
      'guest_access_type, party_size, status, qr_token, qr_expires_at, '
      'entry_secret_code, notes, '
      'event:events!reservations_event_id_fkey(id, title, starts_at, '
      'venue:venues!events_venue_id_fkey(name, city)), '
      'offer:event_offers!reservations_offer_id_fkey('
      'id, title, type, show_qr_on_entry, show_secret_code_on_entry, show_list_name_on_entry'
      '), '
      'promoter:promoters!reservations_promoter_id_fkey(display_name)';
  static const _contactRequestSelect =
      'id, event_id, promoter_id, offer_id, requester_profile_id, requester_name, '
      'requester_email, requester_phone, party_size, message, reply_preference, '
      'status, created_at, event:events!promoter_contact_requests_event_id_fkey('
      'id, title), offer:event_offers!promoter_contact_requests_offer_id_fkey('
      'id, title)';

  User? get currentUser => _client.auth.currentUser;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signInWithGoogle({String? redirectTo}) async {
    _ensureMutationsAllowed(
      'La demo non consente nuovi accessi Google. Usa gli account demo.',
    );

    final launched = await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirectTo,
    );

    if (!launched) {
      throw const AuthException('Impossibile aprire il login Google');
    }
  }

  Future<AuthResponse> signInAnonymously() {
    _ensureMutationsAllowed(
      'La demo non consente accessi guest. Usa la versione attiva.',
    );

    return _client.auth.signInAnonymously(
      data: {'full_name': 'NightRadar Guest'},
    );
  }

  Future<AuthResponse> signUp({
    required String fullName,
    required String email,
    required String password,
  }) {
    _ensureMutationsAllowed(
      'La registrazione completa e disponibile solo nella versione attiva.',
    );

    final acceptedAt = DateTime.now().toUtc().toIso8601String();

    return _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'disclaimer_accepted_at': acceptedAt,
        'privacy_accepted_at': acceptedAt,
        'legal_version': nightRadarLegalVersion,
      },
    );
  }

  Future<void> resendSignupEmail({required String email}) {
    return _client.auth.resend(email: email, type: OtpType.signup);
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<void> acceptLegalPolicies({
    required DateTime acceptedAt,
    required String version,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw const AuthException('Utente non autenticato');
    }

    final acceptedAtIso = acceptedAt.toUtc().toIso8601String();

    await _client
        .from('profiles')
        .update({
          'disclaimer_accepted_at': acceptedAtIso,
          'privacy_accepted_at': acceptedAtIso,
          'legal_version': version,
        })
        .eq('id', user.id);
  }

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
          'id, venue_id, title, event_date, starts_at, ends_at, description, music_tags, '
          'entry_policy, status, cover_image_url, minimum_age, contact_promoter_id, '
          'venue_delivery_name, venue_delivery_phone, venue_delivery_email, venue_delivery_telegram, promo_caption, '
          'contact_promoter:promoters!events_contact_promoter_id_fkey('
          'id, display_name, rating, is_verified), '
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
    final likeCountsByEventId = await _fetchEventLikeCounts(eventIds);

    final now = DateTime.now();
    return eventMaps
        .map((event) {
          final id = event['id'] as String;
          var base = _buildEventSummary(
            event,
            radar: radarByEventId[id],
          ).copyWith(likeCount: likeCountsByEventId[id] ?? 0);
          final offers = offersByEventId[id] ?? const <Map<String, dynamic>>[];

          if (offers.isEmpty) {
            return base;
          }

          final cheapest = offers
              .map((offer) => (offer['price'] as num?)?.toDouble() ?? 0)
              .reduce(min);
          final leadPromoter = _selectFeedPromoter(offers);

          base = base.copyWith(
            bestOfferPrice: cheapest,
            offerCount: offers.length,
          );
          if (leadPromoter == null) {
            return base;
          }

          return base.copyWith(
            primaryPromoterId: leadPromoter['id'] as String?,
            primaryPromoterName: leadPromoter['display_name'] as String?,
            primaryPromoterRating:
                (leadPromoter['rating'] as num?)?.toDouble() ?? 0,
            primaryPromoterVerified:
                leadPromoter['is_verified'] as bool? ?? false,
          );
        })
        .where((event) => event.effectiveEndsAt.isAfter(now))
        .toList();
  }

  Future<EventDetails> fetchEventDetails(String eventId) async {
    final eventRow = await _client
        .from('events')
        .select(
          'id, venue_id, title, event_date, starts_at, ends_at, description, lineup, '
          'music_tags, entry_policy, status, cover_image_url, minimum_age, '
          'contact_promoter_id, contact_name, contact_phone, contact_email, '
          'venue_delivery_name, venue_delivery_phone, venue_delivery_email, venue_delivery_telegram, promo_caption, '
          'allow_whatsapp_requests, allow_inbox_requests, allow_email_requests, '
          'contact_promoter:promoters!events_contact_promoter_id_fkey('
          'id, display_name, public_phone, public_email, instagram_handle, tiktok_handle), '
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
        .select(_eventOfferSelect)
        .eq('event_id', eventId)
        .eq('is_active', true)
        .order('price');

    final availabilityRows = await _client
        .from('event_offer_availability')
        .select('offer_id, spots_left, reserved_guests, reserved_entries')
        .eq('event_id', eventId);

    final availabilityByOffer = {
      for (final row
          in (availabilityRows as List<dynamic>).cast<Map<String, dynamic>>())
        row['offer_id'] as String: row,
    };

    final offers = (offerRows as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(
          (offer) =>
              _mapOffer(offer, availabilityByOffer[offer['id'] as String]),
        )
        .toList();
    final offersWithReactions = await _attachReactionSummaries(offers);

    final summary =
        _buildEventSummary(
          eventRow,
          radar: radarRows,
          bestOfferPrice: offersWithReactions.isEmpty
              ? null
              : offersWithReactions.map((offer) => offer.price).reduce(min),
          offerCount: offersWithReactions.length,
        ).copyWith(
          likeCount: (await _fetchEventLikeCounts([eventId]))[eventId] ?? 0,
        );

    return EventDetails(
      summary: summary,
      venue: VenueInfo.fromMap(
        eventRow['venue'] as Map<String, dynamic>? ?? {},
      ),
      offers: offersWithReactions,
      promoterContact: _buildPromoterContact(eventRow, offersWithReactions),
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
    String? guestLastName,
    String? receiptEmail,
    String? listName,
    bool isAnonymousEntry = false,
    List<ParticipantRecord> participantDetails = const [],
    String? notes,
  }) async {
    _ensureMutationsAllowed(
      'Le prenotazioni sono bloccate nella demo. Usa la versione attiva.',
    );

    final user = currentUser;
    final profile = await _waitForCurrentProfile();
    if (profile == null) {
      throw const AuthException('Utente non autenticato');
    }

    if (offer != null) {
      _validateOfferCapacity(offer: offer, partySize: partySize);
    }

    final inserted = await _client
        .from('reservations')
        .insert({
          'event_id': event.summary.id,
          'offer_id': offer?.id,
          'user_id': profile.id,
          'promoter_id': offer?.promoterId,
          'guest_name': guestName,
          'guest_last_name': guestLastName,
          'guest_phone': phone,
          'guest_email': receiptEmail ?? profile.email,
          'list_name': listName,
          'is_anonymous_entry': isAnonymousEntry,
          'guest_access_type': user?.isAnonymous == true
              ? GuestAccessType.anonymousGuest.value
              : GuestAccessType.verifiedUser.value,
          'participant_details': participantDetails
              .map((participant) => participant.toMap())
              .toList(),
          'party_size': partySize,
          'status': 'approved',
          'qr_expires_at':
              (offer?.validUntil ??
                      event.summary.startsAt.add(const Duration(hours: 4)))
                  .toUtc()
                  .toIso8601String(),
          'confirmed_at': DateTime.now().toUtc().toIso8601String(),
          'notes': notes,
          'created_by': profile.id,
        })
        .select('id')
        .single();

    final reservation = await fetchReservationById(inserted['id'] as String);
    final email = reservation.guestEmail?.trim();
    if (email != null && email.isNotEmpty) {
      try {
        await _client.functions.invoke(
          'send-reservation-receipt-email',
          body: {
            'toEmail': email,
            'guestName': reservation.displayGuestName,
            'eventTitle': reservation.eventTitle,
            'venueName': reservation.venueName,
            'city': reservation.city,
            'startsAt': reservation.startsAt.toUtc().toIso8601String(),
            'offerTitle': reservation.offerTitle,
            'partySize': reservation.partySize,
            'listName': reservation.listName,
            'qrToken': reservation.canShowQrAtEntry
                ? reservation.qrToken
                : null,
            'entrySecretCode': reservation.canShowSecretCodeAtEntry
                ? reservation.entrySecretCode
                : null,
            'showAssignedListName': reservation.canShowAssignedListNameAtEntry,
            'guestAccessType': reservation.guestAccessType.value,
          },
        );
      } catch (_) {}
    }

    return reservation;
  }

  Future<List<ReservationRecord>> fetchMyReservations() async {
    final user = currentUser;
    if (user == null) {
      return const [];
    }

    final rows = await _client
        .from('reservations')
        .select(_reservationSelect)
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
        .select(_reservationSelect)
        .eq('id', reservationId)
        .single();

    return _mapReservation(row);
  }

  Future<PromoterDashboardData> fetchPromoterDashboard() async {
    await _syncPromoterEventLifecycle();
    final profile = await getCurrentProfile();
    final promoterId = await getCurrentPromoterId();

    if (profile == null || promoterId == null) {
      throw const AuthException('Profilo PR non disponibile');
    }

    final promoterRow = await _client
        .from('promoters')
        .select(
          'id, display_name, bio, rating, is_verified, avatar_url, instagram_handle, tiktok_handle',
        )
        .eq('id', promoterId)
        .single();
    final reactionByPromoterId = await _fetchPromoterReactionSummaries([
      promoterId,
    ]);
    final promoterCard = _mapPromoterCard(promoterRow).copyWith(
      reactions:
          reactionByPromoterId[promoterId] ?? const PromoterReactionSummary(),
    );

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
        .map(
          (row) =>
              VenueInfo.fromMap(row['venue'] as Map<String, dynamic>? ?? {}),
        )
        .where((venue) => venue.id.isNotEmpty)
        .toList();
    final venueIds = venues.map((venue) => venue.id).toList();

    final eventRows = venueIds.isEmpty
        ? <dynamic>[]
        : await _client
              .from('events')
              .select(
                'id, venue_id, title, event_date, starts_at, ends_at, description, music_tags, '
                'entry_policy, status, cover_image_url, minimum_age, '
                'venue_delivery_name, venue_delivery_phone, venue_delivery_email, venue_delivery_telegram, promo_caption, '
                'venue:venues!events_venue_id_fkey(id, name, city, address_line, dress_code, price_band)',
              )
              .inFilter('venue_id', venueIds)
              .inFilter('status', ['published', 'live', 'completed'])
              .order('starts_at');

    final eventMaps = eventRows.cast<Map<String, dynamic>>();
    final eventIds = eventMaps.map((event) => event['id'] as String).toList();
    final radarByEventId = await _fetchRadarMap(eventIds);
    final offersByEventId = await _fetchOffersByEventId(eventIds);

    final reservationRows = eventIds.isEmpty
        ? <dynamic>[]
        : await _client
              .from('reservations')
              .select(_reservationSelect)
              .inFilter('event_id', eventIds)
              .order('created_at', ascending: false);

    final reservations = reservationRows
        .cast<Map<String, dynamic>>()
        .map(_mapReservation)
        .toList();
    final contactRequestRows = await _client
        .from('promoter_contact_requests')
        .select(_contactRequestSelect)
        .eq('promoter_id', promoterId)
        .order('created_at', ascending: false);
    final contactRequests = (contactRequestRows as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(_mapContactRequest)
        .toList();

    final approvedCount = reservations
        .where((reservation) => reservation.status == 'approved')
        .length;
    final checkedInCount = reservations
        .where((reservation) => reservation.status == 'checked_in')
        .length;
    final requestedCount = reservations
        .where((reservation) => reservation.status == 'requested')
        .length;
    final newContactRequestCount = contactRequests
        .where((request) => request.status == 'new')
        .length;

    return PromoterDashboardData(
      profile: profile,
      promoterCard: promoterCard,
      promoterId: promoterId,
      venues: venues,
      events: eventMaps
          .map(
            (event) => _buildEventSummary(
              event,
              radar: radarByEventId[event['id'] as String],
            ),
          )
          .toList(),
      offers: [
        for (final eventId in eventIds)
          ...(offersByEventId[eventId] ?? const []),
      ],
      contactRequests: contactRequests,
      reservations: reservations,
      stats: [
        DashboardStat(label: 'Approvati', value: '$approvedCount'),
        DashboardStat(label: 'Check-in', value: '$checkedInCount'),
        DashboardStat(label: 'In attesa', value: '$requestedCount'),
        DashboardStat(label: 'Richieste', value: '$newContactRequestCount'),
      ],
    );
  }

  Future<void> createManualReservation({
    required String eventId,
    String? offerId,
    required String guestName,
    String? guestLastName,
    String? phone,
    required int partySize,
    String? listName,
    bool isAnonymousEntry = false,
    List<ParticipantRecord> participantDetails = const [],
    String? notes,
  }) async {
    _ensureMutationsAllowed(
      'La demo non consente di aggiungere nominativi alla lista.',
    );

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
      'guest_last_name': guestLastName,
      'guest_phone': phone,
      'list_name': listName,
      'is_anonymous_entry': isAnonymousEntry,
      'guest_access_type': GuestAccessType.anonymousGuest.value,
      'participant_details': participantDetails
          .map((participant) => participant.toMap())
          .toList(),
      'party_size': partySize,
      'status': 'approved',
      'confirmed_at': DateTime.now().toUtc().toIso8601String(),
      'created_by': profile.id,
      'notes': notes,
      'qr_expires_at': DateTime.now()
          .toUtc()
          .add(const Duration(hours: 8))
          .toIso8601String(),
    });
  }

  Future<void> updateManualReservation({
    required String reservationId,
    required String guestName,
    String? guestLastName,
    String? phone,
    required int partySize,
    String? listName,
    bool isAnonymousEntry = false,
    List<ParticipantRecord> participantDetails = const [],
    String? notes,
  }) {
    _ensureMutationsAllowed(
      'La demo non consente di modificare i nominativi della lista.',
    );

    return _client
        .from('reservations')
        .update({
          'guest_name': guestName,
          'guest_last_name': guestLastName,
          'guest_phone': phone,
          'list_name': listName,
          'is_anonymous_entry': isAnonymousEntry,
          'participant_details': participantDetails
              .map((participant) => participant.toMap())
              .toList(),
          'party_size': partySize,
          'notes': notes,
        })
        .eq('id', reservationId);
  }

  Future<void> cancelManualReservation(String reservationId) {
    return updateReservationStatus(
      reservationId: reservationId,
      status: 'cancelled',
    );
  }

  Future<void> createPromoterEvent({
    required String venueId,
    required String title,
    required DateTime startsAt,
    required String genre,
    String? description,
    int? minimumAge,
    String? contactPhone,
    String? contactEmail,
    String? venueDeliveryName,
    String? venueDeliveryPhone,
    String? venueDeliveryEmail,
    String? venueDeliveryTelegram,
    String? promoCaption,
    bool allowWhatsAppRequests = false,
    bool allowInboxRequests = true,
    bool allowEmailRequests = false,
  }) async {
    _ensureMutationsAllowed('La demo non consente di pubblicare nuovi eventi.');

    final profile = await getCurrentProfile();
    final promoterId = await getCurrentPromoterId();

    if (profile == null || promoterId == null) {
      throw const AuthException('Profilo PR non disponibile');
    }

    await _client.rpc(
      'promoter_create_event',
      params: {
        'p_venue_id': venueId,
        'p_title': title,
        'p_starts_at': startsAt.toUtc().toIso8601String(),
        'p_genre': genre,
        'p_description': description,
        'p_minimum_age': minimumAge,
        'p_contact_phone': contactPhone,
        'p_contact_email': contactEmail,
        'p_venue_delivery_name': venueDeliveryName,
        'p_venue_delivery_phone': venueDeliveryPhone,
        'p_venue_delivery_email': venueDeliveryEmail,
        'p_venue_delivery_telegram': venueDeliveryTelegram,
        'p_promo_caption': promoCaption,
        'p_allow_whatsapp_requests': allowWhatsAppRequests,
        'p_allow_inbox_requests': allowInboxRequests,
        'p_allow_email_requests': allowEmailRequests,
      },
    );
  }

  Future<void> updatePromoterCard({
    required String displayName,
    String? bio,
    String? avatarUrl,
    String? instagramHandle,
    String? tiktokHandle,
  }) async {
    _ensureMutationsAllowed(
      'La demo non consente di personalizzare la scheda PR.',
    );

    final profile = await getCurrentProfile();
    final promoterId = await getCurrentPromoterId();

    if (profile == null || promoterId == null) {
      throw const AuthException('Profilo PR non disponibile');
    }

    await _client
        .from('promoters')
        .update({
          'display_name': displayName,
          'bio': bio,
          'avatar_url': avatarUrl,
          'instagram_handle': instagramHandle,
          'tiktok_handle': tiktokHandle,
        })
        .eq('id', promoterId);

    await _client
        .from('profiles')
        .update({'avatar_url': avatarUrl})
        .eq('id', profile.id);
  }

  Future<void> togglePromoterReaction({
    required String promoterId,
    required PromoterReactionType reactionType,
  }) async {
    _ensureMutationsAllowed('La demo non consente di lasciare reazioni ai PR.');

    final profile = await getCurrentProfile();
    if (profile == null) {
      throw const AuthException('Accedi per lasciare una reazione al PR');
    }

    final existing = await _client
        .from('promoter_reactions')
        .select('id')
        .eq('promoter_id', promoterId)
        .eq('profile_id', profile.id)
        .eq('reaction_type', reactionType.value)
        .maybeSingle();

    if (existing != null) {
      await _client
          .from('promoter_reactions')
          .delete()
          .eq('id', existing['id'] as String);
      return;
    }

    await _client.from('promoter_reactions').insert({
      'promoter_id': promoterId,
      'profile_id': profile.id,
      'reaction_type': reactionType.value,
    });
  }

  Future<void> createEventOffer({
    required String eventId,
    required String title,
    required String type,
    required double price,
    int? capacityTotal,
    int? tableGuestCapacity,
    String? description,
    String? conditions,
    DateTime? validUntil,
    bool collectLastName = false,
    PhoneRequirement phoneRequirement = PhoneRequirement.lead,
    bool allowAnonymousEntry = false,
    bool requiresListName = false,
    bool showPublicAvailability = false,
    bool showQrOnEntry = true,
    bool showSecretCodeOnEntry = false,
    bool showListNameOnEntry = false,
  }) async {
    _ensureMutationsAllowed('La demo non consente di aprire nuove liste.');

    final profile = await getCurrentProfile();
    final promoterId = await getCurrentPromoterId();

    if (profile == null || promoterId == null) {
      throw const AuthException('Profilo PR non disponibile');
    }

    await _client.rpc(
      'promoter_upsert_event_offer_v3',
      params: {
        'p_event_id': eventId,
        'p_title': title,
        'p_type': type,
        'p_price': price,
        'p_capacity_total': capacityTotal,
        'p_table_guest_capacity': tableGuestCapacity,
        'p_description': description,
        'p_conditions': conditions,
        'p_valid_until': validUntil?.toUtc().toIso8601String(),
        'p_collect_last_name': collectLastName,
        'p_phone_requirement': phoneRequirement.value,
        'p_allow_anonymous_entry': allowAnonymousEntry,
        'p_requires_list_name': requiresListName,
        'p_show_public_availability': showPublicAvailability,
        'p_show_qr_on_entry': showQrOnEntry,
        'p_show_secret_code_on_entry': showSecretCodeOnEntry,
        'p_show_list_name_on_entry': showListNameOnEntry,
      },
    );
  }

  Future<void> updateEventOffer({
    required String offerId,
    required String title,
    required String type,
    required double price,
    int? capacityTotal,
    int? tableGuestCapacity,
    String? description,
    String? conditions,
    DateTime? validUntil,
    bool collectLastName = false,
    PhoneRequirement phoneRequirement = PhoneRequirement.lead,
    bool allowAnonymousEntry = false,
    bool requiresListName = false,
    bool showPublicAvailability = false,
    bool showQrOnEntry = true,
    bool showSecretCodeOnEntry = false,
    bool showListNameOnEntry = false,
  }) {
    _ensureMutationsAllowed('La demo non consente di modificare le liste.');

    return _client.rpc(
      'promoter_upsert_event_offer_v3',
      params: {
        'p_offer_id': offerId,
        'p_title': title,
        'p_type': type,
        'p_price': price,
        'p_capacity_total': capacityTotal,
        'p_table_guest_capacity': tableGuestCapacity,
        'p_description': description,
        'p_conditions': conditions,
        'p_valid_until': validUntil?.toUtc().toIso8601String(),
        'p_collect_last_name': collectLastName,
        'p_phone_requirement': phoneRequirement.value,
        'p_allow_anonymous_entry': allowAnonymousEntry,
        'p_requires_list_name': requiresListName,
        'p_show_public_availability': showPublicAvailability,
        'p_show_qr_on_entry': showQrOnEntry,
        'p_show_secret_code_on_entry': showSecretCodeOnEntry,
        'p_show_list_name_on_entry': showListNameOnEntry,
      },
    );
  }

  Future<void> archiveEventOffer(String offerId) {
    _ensureMutationsAllowed('La demo non consente di chiudere le liste.');

    return _client.rpc(
      'promoter_archive_event_offer',
      params: {'p_offer_id': offerId},
    );
  }

  Future<void> updateReservationStatus({
    required String reservationId,
    required String status,
  }) {
    _ensureMutationsAllowed(
      'La demo non consente di aggiornare lo stato delle prenotazioni.',
    );

    final payload = <String, dynamic>{'status': status};
    if (status == 'approved') {
      payload['confirmed_at'] = DateTime.now().toUtc().toIso8601String();
    }

    return _client.from('reservations').update(payload).eq('id', reservationId);
  }

  Future<void> createPromoterAccessRequest({
    required String fullName,
    required String email,
    String? city,
    String? phone,
    String? instagramHandle,
    String? experienceNote,
  }) async {
    final user = currentUser;

    await _client.from('promoter_access_requests').insert({
      'requester_profile_id': user?.id,
      'full_name': fullName,
      'email': email,
      'city': city,
      'phone': phone,
      'instagram_handle': instagramHandle,
      'experience_note': experienceNote,
    });
  }

  Future<String?> createPromoterContactRequest({
    required EventDetails event,
    String? offerId,
    required String requesterName,
    String? requesterEmail,
    String? requesterPhone,
    required int partySize,
    required String message,
    ContactPreference replyPreference = ContactPreference.whatsapp,
  }) async {
    _ensureMutationsAllowed('La demo non consente di inviare richieste ai PR.');

    final profile = await getCurrentProfile();
    EventOffer? selectedOffer;
    if (offerId != null) {
      for (final offer in event.offers) {
        if (offer.id == offerId) {
          selectedOffer = offer;
          break;
        }
      }
    }
    final promoterId =
        selectedOffer?.promoterId ?? event.promoterContact?.promoterId;
    final promoterName =
        selectedOffer?.promoterName ?? event.promoterContact?.displayName;
    final promoterEmail =
        selectedOffer?.promoterEmail ?? event.promoterContact?.email;

    if (promoterId == null) {
      throw const AuthException('PR non disponibile per questo evento');
    }

    await _client.from('promoter_contact_requests').insert({
      'event_id': event.summary.id,
      'promoter_id': promoterId,
      'offer_id': offerId,
      'requester_profile_id': profile?.id,
      'requester_name': requesterName,
      'requester_email': requesterEmail,
      'requester_phone': requesterPhone,
      'party_size': partySize,
      'message': message,
      'reply_preference': replyPreference.value,
    });

    if (promoterEmail == null || promoterEmail.trim().isEmpty) {
      return null;
    }

    try {
      await _client.functions.invoke(
        'send-promoter-request-email',
        body: {
          'toEmail': promoterEmail,
          'promoterName': promoterName,
          'eventTitle': event.summary.title,
          'offerTitle': selectedOffer?.title,
          'requesterName': requesterName,
          'requesterEmail': requesterEmail,
          'requesterPhone': requesterPhone,
          'partySize': partySize,
          'message': message,
          'replyPreference': replyPreference.value,
        },
      );
    } catch (_) {
      return 'email_failed';
    }

    return null;
  }

  Future<void> updatePromoterContactRequestStatus({
    required String requestId,
    required String status,
  }) {
    _ensureMutationsAllowed(
      'La demo non consente di aggiornare le richieste ai PR.',
    );

    return _client
        .from('promoter_contact_requests')
        .update({'status': status})
        .eq('id', requestId);
  }

  Future<void> toggleEventLike({
    required String eventId,
    required String viewerToken,
  }) async {
    await _client.functions.invoke(
      'toggle-event-like',
      body: {'eventId': eventId, 'viewerToken': viewerToken},
    );
  }

  ReservationRecord _mapReservation(Map<String, dynamic> row) {
    final event = row['event'] as Map<String, dynamic>? ?? {};
    final venue =
        (event['venue'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final offer = row['offer'] as Map<String, dynamic>?;
    final promoter = row['promoter'] as Map<String, dynamic>?;
    final participantRows =
        (row['participant_details'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>();

    return ReservationRecord(
      id: row['id'] as String,
      eventId: row['event_id'] as String,
      eventTitle: event['title'] as String? ?? 'Evento',
      venueName: venue['name'] as String? ?? 'Venue',
      city: venue['city'] as String?,
      startsAt: _parseDateTime(event['starts_at'] as String?) ?? DateTime.now(),
      guestName: row['guest_name'] as String? ?? 'Guest',
      guestLastName: row['guest_last_name'] as String?,
      guestPhone: row['guest_phone'] as String?,
      listName: row['list_name'] as String?,
      isAnonymousEntry: row['is_anonymous_entry'] as bool? ?? false,
      participantDetails: participantRows
          .map(ParticipantRecord.fromMap)
          .toList(),
      partySize: row['party_size'] as int? ?? 1,
      status: row['status'] as String? ?? 'requested',
      offerId: offer?['id'] as String?,
      offerType: offer?['type'] as String?,
      qrToken: row['qr_token'] as String?,
      qrExpiresAt: _parseDateTime(row['qr_expires_at'] as String?),
      entrySecretCode: row['entry_secret_code'] as String?,
      offerTitle: offer?['title'] as String?,
      promoterName: promoter?['display_name'] as String?,
      guestEmail: row['guest_email'] as String?,
      guestAccessType: GuestAccessType.fromValue(
        row['guest_access_type'] as String?,
      ),
      showQrOnEntry: offer?['show_qr_on_entry'] as bool? ?? true,
      showSecretCodeOnEntry:
          offer?['show_secret_code_on_entry'] as bool? ?? false,
      showListNameOnEntry: offer?['show_list_name_on_entry'] as bool? ?? false,
      notes: row['notes'] as String?,
    );
  }

  EventOffer _mapOffer(
    Map<String, dynamic> row,
    Map<String, dynamic>? availabilityRow,
  ) {
    final promoter = row['promoter'] as Map<String, dynamic>?;

    return EventOffer(
      id: row['id'] as String,
      eventId: row['event_id'] as String,
      promoterId: row['promoter_id'] as String?,
      title: row['title'] as String? ?? 'Offerta',
      type: row['type'] as String? ?? 'guest_list_reduced',
      description: row['description'] as String?,
      price: (row['price'] as num?)?.toDouble() ?? 0,
      capacityTotal: row['capacity_total'] as int?,
      validUntil: _parseDateTime(row['valid_until'] as String?),
      conditions: row['conditions'] as String?,
      collectLastName: row['collect_last_name'] as bool? ?? false,
      phoneRequirement: PhoneRequirement.fromValue(
        row['phone_requirement'] as String?,
      ),
      allowAnonymousEntry: row['allow_anonymous_entry'] as bool? ?? false,
      tableGuestCapacity: row['table_guest_capacity'] as int?,
      showPublicAvailability: row['show_public_availability'] as bool? ?? false,
      showQrOnEntry: row['show_qr_on_entry'] as bool? ?? true,
      showSecretCodeOnEntry: row['show_secret_code_on_entry'] as bool? ?? false,
      showListNameOnEntry: row['show_list_name_on_entry'] as bool? ?? false,
      requiresListName: row['requires_list_name'] as bool? ?? false,
      promoterName: promoter?['display_name'] as String?,
      promoterRating: (promoter?['rating'] as num?)?.toDouble() ?? 0,
      promoterPhone: promoter?['public_phone'] as String?,
      promoterEmail: promoter?['public_email'] as String?,
      promoterInstagramHandle: promoter?['instagram_handle'] as String?,
      promoterTiktokHandle: promoter?['tiktok_handle'] as String?,
      promoterBio: promoter?['bio'] as String?,
      promoterAvatarUrl: promoter?['avatar_url'] as String?,
      promoterVerified: promoter?['is_verified'] as bool? ?? false,
      reactions: const PromoterReactionSummary(),
      reservedGuests: availabilityRow?['reserved_guests'] as int? ?? 0,
      reservedEntries: availabilityRow?['reserved_entries'] as int? ?? 0,
      spotsLeft: availabilityRow?['spots_left'] as int?,
    );
  }

  EventSummary _buildEventSummary(
    Map<String, dynamic> row, {
    Map<String, dynamic>? radar,
    double? bestOfferPrice,
    int offerCount = 0,
  }) {
    final venue = VenueInfo.fromMap(
      row['venue'] as Map<String, dynamic>? ?? {},
    );
    final eventDate = row['event_date'] as String?;
    final contactPromoter =
        row['contact_promoter'] as Map<String, dynamic>? ?? const {};

    return EventSummary(
      id: row['id'] as String,
      venueId: row['venue_id'] as String? ?? venue.id,
      title: row['title'] as String? ?? 'NightRadar Event',
      venueName: venue.name,
      city: venue.city,
      startsAt: _parseDateTime(row['starts_at'] as String?) ?? DateTime.now(),
      endsAt: _parseDateTime(row['ends_at'] as String?),
      status: row['status'] as String? ?? 'draft',
      eventDate: eventDate == null ? null : DateTime.tryParse(eventDate),
      radarLabel: radar?['radar_label'] as String? ?? 'easy',
      radarScore: radar?['radar_score'] as num? ?? 0,
      description: row['description'] as String?,
      coverImageUrl: row['cover_image_url'] as String?,
      musicTags: ((row['music_tags'] as List<dynamic>?) ?? const [])
          .map((tag) => tag.toString())
          .toList(),
      entryPolicy: row['entry_policy'] as String?,
      minimumAge: row['minimum_age'] as int?,
      bestOfferPrice: bestOfferPrice,
      offerCount: offerCount,
      primaryPromoterId: contactPromoter['id'] as String?,
      primaryPromoterName: contactPromoter['display_name'] as String?,
      primaryPromoterRating:
          (contactPromoter['rating'] as num?)?.toDouble() ?? 0,
      primaryPromoterVerified: contactPromoter['is_verified'] as bool? ?? false,
      venueDeliveryName: row['venue_delivery_name'] as String?,
      venueDeliveryPhone: row['venue_delivery_phone'] as String?,
      venueDeliveryEmail: row['venue_delivery_email'] as String?,
      venueDeliveryTelegram: row['venue_delivery_telegram'] as String?,
      promoCaption: row['promo_caption'] as String?,
    );
  }

  Future<void> _syncPromoterEventLifecycle() async {
    try {
      await _client.rpc('close_expired_events');
    } catch (_) {}
    try {
      await _client.rpc('purge_old_events');
    } catch (_) {}
  }

  PromoterContact? _buildPromoterContact(
    Map<String, dynamic> row,
    List<EventOffer> offers,
  ) {
    final explicitPromoterId = row['contact_promoter_id'] as String?;
    final explicitName = row['contact_name'] as String?;
    final explicitPhone = row['contact_phone'] as String?;
    final explicitEmail = row['contact_email'] as String?;
    final explicitPromoter = row['contact_promoter'] as Map<String, dynamic>?;
    EventOffer? fallbackOffer;
    for (final offer in offers) {
      final hasPromoterIdentity = offer.promoterId != null;
      final hasContact =
          offer.promoterPhone?.trim().isNotEmpty == true ||
          offer.promoterEmail?.trim().isNotEmpty == true ||
          offer.promoterName?.trim().isNotEmpty == true;
      if (hasPromoterIdentity && hasContact) {
        fallbackOffer = offer;
        break;
      }
    }

    final promoterId = explicitPromoterId ?? fallbackOffer?.promoterId;
    final displayName = explicitName ?? fallbackOffer?.promoterName;
    final phone = explicitPhone ?? fallbackOffer?.promoterPhone;
    final email = explicitEmail ?? fallbackOffer?.promoterEmail;
    final instagramHandle =
        explicitPromoter?['instagram_handle'] as String? ??
        fallbackOffer?.promoterInstagramHandle;
    final tiktokHandle =
        explicitPromoter?['tiktok_handle'] as String? ??
        fallbackOffer?.promoterTiktokHandle;
    final whatsappEnabled = explicitPromoterId != null
        ? row['allow_whatsapp_requests'] as bool? ?? false
        : phone?.trim().isNotEmpty == true;
    final inboxEnabled = explicitPromoterId != null
        ? row['allow_inbox_requests'] as bool? ?? true
        : promoterId != null;
    final emailEnabled = explicitPromoterId != null
        ? row['allow_email_requests'] as bool? ?? false
        : email?.trim().isNotEmpty == true;

    if (promoterId == null &&
        phone?.trim().isNotEmpty != true &&
        email?.trim().isNotEmpty != true) {
      return null;
    }

    final contact = PromoterContact(
      promoterId: promoterId,
      displayName: displayName,
      phone: phone,
      email: email,
      instagramHandle: instagramHandle,
      tiktokHandle: tiktokHandle,
      whatsappEnabled: whatsappEnabled,
      inboxEnabled: inboxEnabled,
      emailEnabled: emailEnabled,
    );

    return contact.hasAnyChannel ? contact : null;
  }

  PromoterProfileCard _mapPromoterCard(Map<String, dynamic> row) {
    return PromoterProfileCard(
      id: row['id'] as String,
      displayName: row['display_name'] as String? ?? 'PR',
      bio: row['bio'] as String?,
      avatarUrl: row['avatar_url'] as String?,
      instagramHandle: row['instagram_handle'] as String?,
      tiktokHandle: row['tiktok_handle'] as String?,
      rating: (row['rating'] as num?)?.toDouble() ?? 0,
      isVerified: row['is_verified'] as bool? ?? false,
      reactions: const PromoterReactionSummary(),
    );
  }

  PromoterContactRequest _mapContactRequest(Map<String, dynamic> row) {
    final event = row['event'] as Map<String, dynamic>? ?? const {};
    final offer = row['offer'] as Map<String, dynamic>?;
    return PromoterContactRequest(
      id: row['id'] as String,
      eventId: row['event_id'] as String,
      eventTitle: event['title'] as String? ?? 'Evento',
      promoterId: row['promoter_id'] as String,
      requesterName: row['requester_name'] as String? ?? 'Guest',
      requesterEmail: row['requester_email'] as String?,
      requesterPhone: row['requester_phone'] as String?,
      requesterProfileId: row['requester_profile_id'] as String?,
      offerId: row['offer_id'] as String?,
      offerTitle: offer?['title'] as String?,
      partySize: row['party_size'] as int? ?? 1,
      message: row['message'] as String? ?? '',
      status: row['status'] as String? ?? 'new',
      createdAt: _parseDateTime(row['created_at'] as String?) ?? DateTime.now(),
      replyPreference: ContactPreference.fromValue(
        row['reply_preference'] as String?,
      ),
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
        .select(_feedOfferSelect)
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

  Future<Map<String, int>> _fetchEventLikeCounts(List<String> eventIds) async {
    if (eventIds.isEmpty) {
      return const {};
    }

    final rows = await _client
        .from('event_like_totals')
        .select('event_id, like_count')
        .inFilter('event_id', eventIds);

    return {
      for (final row in (rows as List<dynamic>).cast<Map<String, dynamic>>())
        row['event_id'] as String: row['like_count'] as int? ?? 0,
    };
  }

  Map<String, dynamic>? _selectFeedPromoter(List<Map<String, dynamic>> offers) {
    Map<String, dynamic>? winner;
    for (final offer in offers) {
      final promoter = offer['promoter'] as Map<String, dynamic>?;
      if (promoter == null) {
        continue;
      }

      if (winner == null) {
        winner = promoter;
        continue;
      }

      final winnerVerified = winner['is_verified'] as bool? ?? false;
      final promoterVerified = promoter['is_verified'] as bool? ?? false;
      if (promoterVerified && !winnerVerified) {
        winner = promoter;
        continue;
      }

      final winnerRating = (winner['rating'] as num?)?.toDouble() ?? 0;
      final promoterRating = (promoter['rating'] as num?)?.toDouble() ?? 0;
      if (promoterRating > winnerRating) {
        winner = promoter;
      }
    }

    return winner;
  }

  Future<Map<String, List<EventOffer>>> _fetchOffersByEventId(
    List<String> eventIds,
  ) async {
    if (eventIds.isEmpty) {
      return const {};
    }

    final rows = await _client
        .from('event_offers')
        .select(_eventOfferSelect)
        .inFilter('event_id', eventIds)
        .eq('is_active', true)
        .order('price');

    final availabilityRows = await _client
        .from('event_offer_availability')
        .select('offer_id, spots_left, reserved_guests, reserved_entries')
        .inFilter('event_id', eventIds);

    final availabilityByOffer = {
      for (final row
          in (availabilityRows as List<dynamic>).cast<Map<String, dynamic>>())
        row['offer_id'] as String: row,
    };

    final grouped = <String, List<EventOffer>>{};
    for (final row in (rows as List<dynamic>).cast<Map<String, dynamic>>()) {
      final offer = _mapOffer(row, availabilityByOffer[row['id'] as String]);
      grouped.putIfAbsent(offer.eventId, () => []);
      grouped[offer.eventId]!.add(offer);
    }

    final allOffers = [for (final offers in grouped.values) ...offers];
    final offersWithReactions = await _attachReactionSummaries(allOffers);
    final regrouped = <String, List<EventOffer>>{};
    for (final offer in offersWithReactions) {
      regrouped.putIfAbsent(offer.eventId, () => []);
      regrouped[offer.eventId]!.add(offer);
    }

    return regrouped;
  }

  Future<List<EventOffer>> _attachReactionSummaries(
    List<EventOffer> offers,
  ) async {
    if (offers.isEmpty) {
      return offers;
    }

    final promoterIds = {
      for (final offer in offers)
        if (offer.promoterId != null) offer.promoterId!,
    }.toList();

    if (promoterIds.isEmpty) {
      return offers;
    }

    final reactionsByPromoterId = await _fetchPromoterReactionSummaries(
      promoterIds,
    );
    return offers
        .map(
          (offer) => offer.promoterId == null
              ? offer
              : offer.copyWith(
                  reactions:
                      reactionsByPromoterId[offer.promoterId!] ??
                      const PromoterReactionSummary(),
                ),
        )
        .toList();
  }

  Future<Map<String, PromoterReactionSummary>> _fetchPromoterReactionSummaries(
    List<String> promoterIds,
  ) async {
    if (promoterIds.isEmpty) {
      return const {};
    }

    final totalsRows = await _client
        .from('promoter_reaction_totals')
        .select('promoter_id, thumbs_up_count, heart_count')
        .inFilter('promoter_id', promoterIds);

    final byPromoterId = <String, PromoterReactionSummary>{
      for (final promoterId in promoterIds)
        promoterId: const PromoterReactionSummary(),
    };

    for (final row
        in (totalsRows as List<dynamic>).cast<Map<String, dynamic>>()) {
      final promoterId = row['promoter_id'] as String? ?? '';
      if (promoterId.isEmpty) {
        continue;
      }
      byPromoterId[promoterId] = PromoterReactionSummary(
        thumbsUpCount: row['thumbs_up_count'] as int? ?? 0,
        heartCount: row['heart_count'] as int? ?? 0,
      );
    }

    final profile = await getCurrentProfile();
    if (profile == null) {
      return byPromoterId;
    }

    final viewerRows = await _client
        .from('promoter_reactions')
        .select('promoter_id, reaction_type')
        .eq('profile_id', profile.id)
        .inFilter('promoter_id', promoterIds);

    for (final row
        in (viewerRows as List<dynamic>).cast<Map<String, dynamic>>()) {
      final promoterId = row['promoter_id'] as String? ?? '';
      if (promoterId.isEmpty) {
        continue;
      }
      final current =
          byPromoterId[promoterId] ?? const PromoterReactionSummary();
      final type = PromoterReactionType.fromValue(
        row['reaction_type'] as String?,
      );
      byPromoterId[promoterId] = switch (type) {
        PromoterReactionType.heart => current.copyWith(viewerHeart: true),
        PromoterReactionType.thumbsUp => current.copyWith(viewerThumbsUp: true),
      };
    }

    return byPromoterId;
  }

  DateTime? _parseDateTime(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value)?.toLocal();
  }

  Future<AppProfile?> _waitForCurrentProfile() async {
    for (var attempt = 0; attempt < 5; attempt++) {
      final profile = await getCurrentProfile();
      if (profile != null) {
        return profile;
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    return null;
  }

  void _ensureMutationsAllowed(String message) {
    if (!AppFlavorConfig.allowMutations) {
      throw AuthException(message);
    }
  }

  void _validateOfferCapacity({
    required EventOffer offer,
    required int partySize,
  }) {
    if (offer.isTableOffer) {
      if (offer.spotsLeft != null && offer.spotsLeft! <= 0) {
        throw const AuthException('Nessun tavolo disponibile al momento');
      }
      if (offer.tableGuestCapacity != null &&
          partySize > offer.tableGuestCapacity!) {
        throw AuthException(
          'Questo tavolo accetta al massimo ${offer.tableGuestCapacity} persone',
        );
      }
      return;
    }

    if (offer.spotsLeft != null && partySize > offer.spotsLeft!) {
      throw const AuthException(
        'Disponibilita residua insufficiente per questa richiesta',
      );
    }
  }
}
