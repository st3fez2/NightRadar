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

enum PhoneRequirement {
  none('none'),
  lead('lead'),
  allParticipants('all_participants');

  const PhoneRequirement(this.value);

  final String value;

  static PhoneRequirement fromValue(String? value) {
    return switch (value) {
      'none' => PhoneRequirement.none,
      'all_participants' => PhoneRequirement.allParticipants,
      _ => PhoneRequirement.lead,
    };
  }
}

enum GuestAccessType {
  verifiedUser('verified_user'),
  anonymousGuest('anonymous_guest');

  const GuestAccessType(this.value);

  final String value;

  static GuestAccessType fromValue(String? value) {
    return switch (value) {
      'anonymous_guest' => GuestAccessType.anonymousGuest,
      _ => GuestAccessType.verifiedUser,
    };
  }
}

class AppProfile {
  AppProfile({
    required this.id,
    required this.fullName,
    required this.role,
    this.email,
    this.phone,
    this.city,
    this.avatarUrl,
    this.disclaimerAcceptedAt,
    this.privacyAcceptedAt,
    this.legalVersion,
  });

  final String id;
  final String fullName;
  final String? email;
  final String? phone;
  final String? city;
  final String? avatarUrl;
  final AppRole role;
  final DateTime? disclaimerAcceptedAt;
  final DateTime? privacyAcceptedAt;
  final String? legalVersion;

  factory AppProfile.fromMap(Map<String, dynamic> map) {
    return AppProfile(
      id: map['id'] as String,
      fullName: map['full_name'] as String? ?? 'NightRadar User',
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      city: map['city'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      role: AppRole.fromValue(map['role'] as String?),
      disclaimerAcceptedAt: _parseDateTime(
        map['disclaimer_accepted_at'] as String?,
      ),
      privacyAcceptedAt: _parseDateTime(map['privacy_accepted_at'] as String?),
      legalVersion: map['legal_version'] as String?,
    );
  }

  bool hasAcceptedLegalVersion(String version) {
    return disclaimerAcceptedAt != null &&
        privacyAcceptedAt != null &&
        legalVersion == version;
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
    this.status = 'draft',
    this.eventDate,
    this.endsAt,
    this.description,
    this.coverImageUrl,
    this.musicTags = const [],
    this.entryPolicy,
    this.minimumAge,
    this.bestOfferPrice,
    this.offerCount = 0,
    this.primaryPromoterId,
    this.primaryPromoterName,
    this.primaryPromoterRating,
    this.primaryPromoterVerified = false,
    this.likeCount = 0,
    this.venueDeliveryName,
    this.venueDeliveryPhone,
    this.venueDeliveryEmail,
    this.venueDeliveryTelegram,
    this.promoCaption,
  });

  final String id;
  final String venueId;
  final String title;
  final String venueName;
  final String city;
  final DateTime startsAt;
  final String status;
  final DateTime? eventDate;
  final DateTime? endsAt;
  final String radarLabel;
  final num radarScore;
  final String? description;
  final String? coverImageUrl;
  final List<String> musicTags;
  final String? entryPolicy;
  final int? minimumAge;
  final double? bestOfferPrice;
  final int offerCount;
  final String? primaryPromoterId;
  final String? primaryPromoterName;
  final double? primaryPromoterRating;
  final bool primaryPromoterVerified;
  final int likeCount;
  final String? venueDeliveryName;
  final String? venueDeliveryPhone;
  final String? venueDeliveryEmail;
  final String? venueDeliveryTelegram;
  final String? promoCaption;

  DateTime get effectiveEndsAt =>
      endsAt ?? startsAt.add(const Duration(hours: 6));

  bool get isClosed {
    return status == 'completed' ||
        status == 'cancelled' ||
        effectiveEndsAt.isBefore(DateTime.now());
  }

  bool get isLiveNow {
    final now = DateTime.now();
    return !isClosed && startsAt.isBefore(now) && effectiveEndsAt.isAfter(now);
  }

  bool get hasVenueDeliveryChannel =>
      venueDeliveryPhone?.trim().isNotEmpty == true ||
      venueDeliveryEmail?.trim().isNotEmpty == true ||
      venueDeliveryTelegram?.trim().isNotEmpty == true;

  EventSummary copyWith({
    double? bestOfferPrice,
    int? offerCount,
    String? radarLabel,
    num? radarScore,
    int? minimumAge,
    DateTime? endsAt,
    String? status,
    String? primaryPromoterId,
    String? primaryPromoterName,
    double? primaryPromoterRating,
    bool? primaryPromoterVerified,
    int? likeCount,
    String? venueDeliveryName,
    String? venueDeliveryPhone,
    String? venueDeliveryEmail,
    String? venueDeliveryTelegram,
    String? promoCaption,
  }) {
    return EventSummary(
      id: id,
      venueId: venueId,
      title: title,
      venueName: venueName,
      city: city,
      startsAt: startsAt,
      status: status ?? this.status,
      eventDate: eventDate,
      endsAt: endsAt ?? this.endsAt,
      radarLabel: radarLabel ?? this.radarLabel,
      radarScore: radarScore ?? this.radarScore,
      description: description,
      coverImageUrl: coverImageUrl,
      musicTags: musicTags,
      entryPolicy: entryPolicy,
      minimumAge: minimumAge ?? this.minimumAge,
      bestOfferPrice: bestOfferPrice ?? this.bestOfferPrice,
      offerCount: offerCount ?? this.offerCount,
      primaryPromoterId: primaryPromoterId ?? this.primaryPromoterId,
      primaryPromoterName: primaryPromoterName ?? this.primaryPromoterName,
      primaryPromoterRating:
          primaryPromoterRating ?? this.primaryPromoterRating,
      primaryPromoterVerified:
          primaryPromoterVerified ?? this.primaryPromoterVerified,
      likeCount: likeCount ?? this.likeCount,
      venueDeliveryName: venueDeliveryName ?? this.venueDeliveryName,
      venueDeliveryPhone: venueDeliveryPhone ?? this.venueDeliveryPhone,
      venueDeliveryEmail: venueDeliveryEmail ?? this.venueDeliveryEmail,
      venueDeliveryTelegram:
          venueDeliveryTelegram ?? this.venueDeliveryTelegram,
      promoCaption: promoCaption ?? this.promoCaption,
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
    this.capacityTotal,
    this.collectLastName = false,
    this.phoneRequirement = PhoneRequirement.lead,
    this.allowAnonymousEntry = false,
    this.requiresListName = false,
    this.description,
    this.promoterId,
    this.promoterName,
    this.promoterRating,
    this.promoterPhone,
    this.promoterEmail,
    this.promoterInstagramHandle,
    this.promoterTiktokHandle,
    this.promoterBio,
    this.promoterAvatarUrl,
    this.promoterVerified = false,
    this.reactions = const PromoterReactionSummary(),
    this.validUntil,
    this.conditions,
    this.tableGuestCapacity,
    this.showPublicAvailability = false,
    this.showQrOnEntry = true,
    this.showSecretCodeOnEntry = false,
    this.showListNameOnEntry = false,
    this.reservedGuests = 0,
    this.reservedEntries = 0,
    this.spotsLeft,
  });

  final String id;
  final String eventId;
  final String title;
  final String type;
  final double price;
  final int? capacityTotal;
  final bool collectLastName;
  final PhoneRequirement phoneRequirement;
  final bool allowAnonymousEntry;
  final bool requiresListName;
  final String? description;
  final String? promoterId;
  final String? promoterName;
  final double? promoterRating;
  final String? promoterPhone;
  final String? promoterEmail;
  final String? promoterInstagramHandle;
  final String? promoterTiktokHandle;
  final String? promoterBio;
  final String? promoterAvatarUrl;
  final bool promoterVerified;
  final PromoterReactionSummary reactions;
  final DateTime? validUntil;
  final String? conditions;
  final int? tableGuestCapacity;
  final bool showPublicAvailability;
  final bool showQrOnEntry;
  final bool showSecretCodeOnEntry;
  final bool showListNameOnEntry;
  final int reservedGuests;
  final int reservedEntries;
  final int? spotsLeft;

  bool get isTableOffer => type == 'table';

  EventOffer copyWith({
    int? spotsLeft,
    int? capacityTotal,
    bool? collectLastName,
    PhoneRequirement? phoneRequirement,
    bool? allowAnonymousEntry,
    bool? requiresListName,
    int? tableGuestCapacity,
    bool? showPublicAvailability,
    bool? showQrOnEntry,
    bool? showSecretCodeOnEntry,
    bool? showListNameOnEntry,
    int? reservedGuests,
    int? reservedEntries,
    PromoterReactionSummary? reactions,
  }) {
    return EventOffer(
      id: id,
      eventId: eventId,
      title: title,
      type: type,
      price: price,
      capacityTotal: capacityTotal ?? this.capacityTotal,
      collectLastName: collectLastName ?? this.collectLastName,
      phoneRequirement: phoneRequirement ?? this.phoneRequirement,
      allowAnonymousEntry: allowAnonymousEntry ?? this.allowAnonymousEntry,
      requiresListName: requiresListName ?? this.requiresListName,
      description: description,
      promoterId: promoterId,
      promoterName: promoterName,
      promoterRating: promoterRating,
      promoterPhone: promoterPhone,
      promoterEmail: promoterEmail,
      promoterInstagramHandle: promoterInstagramHandle,
      promoterTiktokHandle: promoterTiktokHandle,
      promoterBio: promoterBio,
      promoterAvatarUrl: promoterAvatarUrl,
      promoterVerified: promoterVerified,
      reactions: reactions ?? this.reactions,
      validUntil: validUntil,
      conditions: conditions,
      tableGuestCapacity: tableGuestCapacity ?? this.tableGuestCapacity,
      showPublicAvailability:
          showPublicAvailability ?? this.showPublicAvailability,
      showQrOnEntry: showQrOnEntry ?? this.showQrOnEntry,
      showSecretCodeOnEntry:
          showSecretCodeOnEntry ?? this.showSecretCodeOnEntry,
      showListNameOnEntry: showListNameOnEntry ?? this.showListNameOnEntry,
      reservedGuests: reservedGuests ?? this.reservedGuests,
      reservedEntries: reservedEntries ?? this.reservedEntries,
      spotsLeft: spotsLeft ?? this.spotsLeft,
    );
  }
}

class PromoterProfileCard {
  PromoterProfileCard({
    required this.id,
    required this.displayName,
    this.bio,
    this.avatarUrl,
    this.instagramHandle,
    this.tiktokHandle,
    this.rating = 0,
    this.isVerified = false,
    this.reactions = const PromoterReactionSummary(),
  });

  final String id;
  final String displayName;
  final String? bio;
  final String? avatarUrl;
  final String? instagramHandle;
  final String? tiktokHandle;
  final double rating;
  final bool isVerified;
  final PromoterReactionSummary reactions;

  PromoterProfileCard copyWith({
    String? displayName,
    String? bio,
    String? avatarUrl,
    String? instagramHandle,
    String? tiktokHandle,
    double? rating,
    bool? isVerified,
    PromoterReactionSummary? reactions,
  }) {
    return PromoterProfileCard(
      id: id,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      instagramHandle: instagramHandle ?? this.instagramHandle,
      tiktokHandle: tiktokHandle ?? this.tiktokHandle,
      rating: rating ?? this.rating,
      isVerified: isVerified ?? this.isVerified,
      reactions: reactions ?? this.reactions,
    );
  }
}

class PromoterContact {
  PromoterContact({
    required this.promoterId,
    required this.displayName,
    this.phone,
    this.email,
    this.instagramHandle,
    this.tiktokHandle,
    this.whatsappEnabled = false,
    this.inboxEnabled = true,
    this.emailEnabled = false,
  });

  final String? promoterId;
  final String? displayName;
  final String? phone;
  final String? email;
  final String? instagramHandle;
  final String? tiktokHandle;
  final bool whatsappEnabled;
  final bool inboxEnabled;
  final bool emailEnabled;

  bool get hasAnyChannel =>
      (whatsappEnabled && phone?.trim().isNotEmpty == true) ||
      (inboxEnabled && promoterId != null) ||
      (emailEnabled && email?.trim().isNotEmpty == true) ||
      instagramHandle?.trim().isNotEmpty == true ||
      tiktokHandle?.trim().isNotEmpty == true;
}

class ParticipantRecord {
  ParticipantRecord({required this.firstName, this.lastName, this.phone});

  final String firstName;
  final String? lastName;
  final String? phone;

  factory ParticipantRecord.fromMap(Map<String, dynamic> map) {
    return ParticipantRecord(
      firstName: map['first_name'] as String? ?? '',
      lastName: map['last_name'] as String?,
      phone: map['phone'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {'first_name': firstName, 'last_name': lastName, 'phone': phone};
  }
}

class EventDetails {
  EventDetails({
    required this.summary,
    required this.venue,
    required this.offers,
    this.promoterContact,
    this.lineup,
    this.description,
  });

  final EventSummary summary;
  final VenueInfo venue;
  final List<EventOffer> offers;
  final PromoterContact? promoterContact;
  final String? lineup;
  final String? description;
}

enum ContactPreference {
  whatsapp('whatsapp'),
  email('email'),
  inbox('inbox');

  const ContactPreference(this.value);

  final String value;

  static ContactPreference fromValue(String? value) {
    return switch (value) {
      'email' => ContactPreference.email,
      'inbox' => ContactPreference.inbox,
      _ => ContactPreference.whatsapp,
    };
  }
}

enum PromoterReactionType {
  thumbsUp('thumbs_up'),
  heart('heart');

  const PromoterReactionType(this.value);

  final String value;

  static PromoterReactionType fromValue(String? value) {
    return switch (value) {
      'heart' => PromoterReactionType.heart,
      _ => PromoterReactionType.thumbsUp,
    };
  }
}

class PromoterReactionSummary {
  const PromoterReactionSummary({
    this.thumbsUpCount = 0,
    this.heartCount = 0,
    this.viewerThumbsUp = false,
    this.viewerHeart = false,
  });

  final int thumbsUpCount;
  final int heartCount;
  final bool viewerThumbsUp;
  final bool viewerHeart;

  PromoterReactionSummary copyWith({
    int? thumbsUpCount,
    int? heartCount,
    bool? viewerThumbsUp,
    bool? viewerHeart,
  }) {
    return PromoterReactionSummary(
      thumbsUpCount: thumbsUpCount ?? this.thumbsUpCount,
      heartCount: heartCount ?? this.heartCount,
      viewerThumbsUp: viewerThumbsUp ?? this.viewerThumbsUp,
      viewerHeart: viewerHeart ?? this.viewerHeart,
    );
  }
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
    this.offerId,
    this.city,
    this.offerType,
    this.offerTitle,
    this.promoterName,
    this.guestLastName,
    this.guestPhone,
    this.guestEmail,
    this.listName,
    this.isAnonymousEntry = false,
    this.guestAccessType = GuestAccessType.verifiedUser,
    this.participantDetails = const [],
    this.qrToken,
    this.qrExpiresAt,
    this.entrySecretCode,
    this.showQrOnEntry = true,
    this.showSecretCodeOnEntry = false,
    this.showListNameOnEntry = false,
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
  final String? offerId;
  final String? city;
  final String? offerType;
  final String? offerTitle;
  final String? promoterName;
  final String? guestLastName;
  final String? guestPhone;
  final String? guestEmail;
  final String? listName;
  final bool isAnonymousEntry;
  final GuestAccessType guestAccessType;
  final List<ParticipantRecord> participantDetails;
  final String? qrToken;
  final DateTime? qrExpiresAt;
  final String? entrySecretCode;
  final bool showQrOnEntry;
  final bool showSecretCodeOnEntry;
  final bool showListNameOnEntry;
  final String? notes;

  bool get isVerifiedGuest => guestAccessType == GuestAccessType.verifiedUser;

  bool get canShowQrAtEntry => showQrOnEntry && qrToken != null;

  bool get canShowSecretCodeAtEntry =>
      showSecretCodeOnEntry &&
      entrySecretCode != null &&
      entrySecretCode!.trim().isNotEmpty;

  bool get canShowAssignedListNameAtEntry =>
      showListNameOnEntry && listName != null && listName!.trim().isNotEmpty;

  bool get hasAnyEntryCredential =>
      canShowQrAtEntry ||
      canShowSecretCodeAtEntry ||
      canShowAssignedListNameAtEntry;

  String get displayGuestName {
    if (isAnonymousEntry) {
      return listName?.trim().isNotEmpty == true
          ? listName!.trim()
          : 'Anonymous';
    }

    final suffix = guestLastName == null || guestLastName!.trim().isEmpty
        ? ''
        : ' ${guestLastName!.trim()}';
    return '${guestName.trim()}$suffix'.trim();
  }
}

class DashboardStat {
  DashboardStat({required this.label, required this.value});

  final String label;
  final String value;
}

class PromoterDashboardData {
  PromoterDashboardData({
    required this.profile,
    required this.promoterCard,
    required this.venues,
    required this.events,
    required this.offers,
    required this.contactRequests,
    required this.reservations,
    required this.stats,
    required this.promoterId,
  });

  final AppProfile profile;
  final PromoterProfileCard promoterCard;
  final List<VenueInfo> venues;
  final List<EventSummary> events;
  final List<EventOffer> offers;
  final List<PromoterContactRequest> contactRequests;
  final List<ReservationRecord> reservations;
  final List<DashboardStat> stats;
  final String promoterId;
}

class PromoterContactRequest {
  PromoterContactRequest({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.promoterId,
    required this.requesterName,
    required this.message,
    required this.partySize,
    required this.status,
    required this.createdAt,
    this.offerId,
    this.offerTitle,
    this.requesterProfileId,
    this.requesterEmail,
    this.requesterPhone,
    this.replyPreference = ContactPreference.whatsapp,
  });

  final String id;
  final String eventId;
  final String eventTitle;
  final String promoterId;
  final String requesterName;
  final String message;
  final int partySize;
  final String status;
  final DateTime createdAt;
  final String? offerId;
  final String? offerTitle;
  final String? requesterProfileId;
  final String? requesterEmail;
  final String? requesterPhone;
  final ContactPreference replyPreference;

  String get requesterContactLabel {
    if (requesterPhone?.trim().isNotEmpty == true &&
        requesterEmail?.trim().isNotEmpty == true) {
      return '${requesterPhone!.trim()}  ·  ${requesterEmail!.trim()}';
    }
    if (requesterPhone?.trim().isNotEmpty == true) {
      return requesterPhone!.trim();
    }
    if (requesterEmail?.trim().isNotEmpty == true) {
      return requesterEmail!.trim();
    }
    return '';
  }
}

DateTime? _parseDateTime(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }

  return DateTime.tryParse(value)?.toLocal();
}
