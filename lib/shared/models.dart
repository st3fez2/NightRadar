enum AppRole {
  user('Utente'),
  promoter('PR'),
  venueAdmin('Locale'),
  doorStaff('Staff'),
  superAdmin('Admin');

  const AppRole(this.label);

  final String label;

  static AppRole fromValue(String? value) {
    return switch (value) {
      'promoter' => AppRole.promoter,
      'venue_admin' => AppRole.venueAdmin,
      'door_staff' => AppRole.doorStaff,
      'super_admin' => AppRole.superAdmin,
      _ => AppRole.user,
    };
  }
}

class AppProfile {
  AppProfile({
    required this.id,
    required this.fullName,
    required this.role,
    this.email,
    this.city,
  });

  final String id;
  final String fullName;
  final String? email;
  final String? city;
  final AppRole role;

  factory AppProfile.fromMap(Map<String, dynamic> map) {
    return AppProfile(
      id: map['id'] as String,
      fullName: map['full_name'] as String? ?? 'NightRadar User',
      email: map['email'] as String?,
      city: map['city'] as String?,
      role: AppRole.fromValue(map['role'] as String?),
    );
  }
}

class VenueInfo {
  VenueInfo({
    required this.id,
    required this.name,
    required this.city,
    this.addressLine,
    this.dressCode,
    this.priceBand,
  });

  final String id;
  final String name;
  final String city;
  final String? addressLine;
  final String? dressCode;
  final String? priceBand;

  factory VenueInfo.fromMap(Map<String, dynamic> map) {
    return VenueInfo(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Venue',
      city: map['city'] as String? ?? '',
      addressLine: map['address_line'] as String?,
      dressCode: map['dress_code'] as String?,
      priceBand: map['price_band'] as String?,
    );
  }
}

class EventSummary {
  EventSummary({
    required this.id,
    required this.venueId,
    required this.title,
    required this.venueName,
    required this.city,
    required this.startsAt,
    required this.radarLabel,
    required this.radarScore,
    this.eventDate,
    this.description,
    this.coverImageUrl,
    this.musicTags = const [],
    this.entryPolicy,
    this.bestOfferPrice,
    this.offerCount = 0,
  });

  final String id;
  final String venueId;
  final String title;
  final String venueName;
  final String city;
  final DateTime startsAt;
  final DateTime? eventDate;
  final String radarLabel;
  final num radarScore;
  final String? description;
  final String? coverImageUrl;
  final List<String> musicTags;
  final String? entryPolicy;
  final double? bestOfferPrice;
  final int offerCount;

  EventSummary copyWith({
    double? bestOfferPrice,
    int? offerCount,
    String? radarLabel,
    num? radarScore,
  }) {
    return EventSummary(
      id: id,
      venueId: venueId,
      title: title,
      venueName: venueName,
      city: city,
      startsAt: startsAt,
      eventDate: eventDate,
      radarLabel: radarLabel ?? this.radarLabel,
      radarScore: radarScore ?? this.radarScore,
      description: description,
      coverImageUrl: coverImageUrl,
      musicTags: musicTags,
      entryPolicy: entryPolicy,
      bestOfferPrice: bestOfferPrice ?? this.bestOfferPrice,
      offerCount: offerCount ?? this.offerCount,
    );
  }
}

class EventOffer {
  EventOffer({
    required this.id,
    required this.eventId,
    required this.title,
    required this.type,
    required this.price,
    this.description,
    this.promoterId,
    this.promoterName,
    this.promoterRating,
    this.validUntil,
    this.conditions,
    this.spotsLeft,
  });

  final String id;
  final String eventId;
  final String title;
  final String type;
  final double price;
  final String? description;
  final String? promoterId;
  final String? promoterName;
  final double? promoterRating;
  final DateTime? validUntil;
  final String? conditions;
  final int? spotsLeft;

  EventOffer copyWith({
    int? spotsLeft,
  }) {
    return EventOffer(
      id: id,
      eventId: eventId,
      title: title,
      type: type,
      price: price,
      description: description,
      promoterId: promoterId,
      promoterName: promoterName,
      promoterRating: promoterRating,
      validUntil: validUntil,
      conditions: conditions,
      spotsLeft: spotsLeft ?? this.spotsLeft,
    );
  }
}

class EventDetails {
  EventDetails({
    required this.summary,
    required this.venue,
    required this.offers,
    this.lineup,
    this.description,
  });

  final EventSummary summary;
  final VenueInfo venue;
  final List<EventOffer> offers;
  final String? lineup;
  final String? description;
}

class ReservationRecord {
  ReservationRecord({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.venueName,
    required this.startsAt,
    required this.guestName,
    required this.partySize,
    required this.status,
    this.city,
    this.offerTitle,
    this.promoterName,
    this.qrToken,
    this.qrExpiresAt,
    this.notes,
  });

  final String id;
  final String eventId;
  final String eventTitle;
  final String venueName;
  final DateTime startsAt;
  final String guestName;
  final int partySize;
  final String status;
  final String? city;
  final String? offerTitle;
  final String? promoterName;
  final String? qrToken;
  final DateTime? qrExpiresAt;
  final String? notes;
}

class DashboardStat {
  DashboardStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}

class PromoterDashboardData {
  PromoterDashboardData({
    required this.profile,
    required this.venues,
    required this.events,
    required this.reservations,
    required this.stats,
    required this.promoterId,
  });

  final AppProfile profile;
  final List<VenueInfo> venues;
  final List<EventSummary> events;
  final List<ReservationRecord> reservations;
  final List<DashboardStat> stats;
  final String promoterId;
}
