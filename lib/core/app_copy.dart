import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../shared/models.dart';

class AppCopy {
  AppCopy(this.locale);

  final Locale locale;

  bool get isEnglish => locale.languageCode == 'en';

  String get dateLocale => isEnglish ? 'en_US' : 'it_IT';

  String text({required String it, required String en}) {
    return isEnglish ? en : it;
  }

  String shortDateTime(DateTime value) {
    return DateFormat(
      isEnglish ? 'EEE MMM d, HH:mm' : 'EEE d MMM, HH:mm',
      dateLocale,
    ).format(value);
  }

  String mediumDateTime(DateTime value) {
    return DateFormat(
      isEnglish ? 'EEE MMM d yyyy, HH:mm' : 'EEE d MMM yyyy, HH:mm',
      dateLocale,
    ).format(value);
  }

  String longDateTime(DateTime value) {
    return DateFormat(
      isEnglish ? 'EEEE MMMM d, HH:mm' : 'EEEE d MMMM, HH:mm',
      dateLocale,
    ).format(value);
  }

  String priceAmount(num price) => 'EUR ${price.toStringAsFixed(0)}';

  String fromPrice(num price) {
    return text(
      it: 'Da ${priceAmount(price)}',
      en: 'From ${priceAmount(price)}',
    );
  }

  String unavailableOffersPrice() {
    return text(it: 'Offerte in aggiornamento', en: 'Offers updating');
  }

  String pendingOffersPrice() {
    return text(it: 'Offerte da aggiornare', en: 'Offers pending update');
  }

  String freeEntryLabel() {
    return text(it: 'Ingresso free', en: 'Free entry');
  }

  String offersCount(int count) {
    return text(it: '$count offerte', en: '$count offers');
  }

  String availableCount(int count) {
    return text(it: '$count disponibili', en: '$count available');
  }

  String peopleCount(int count) {
    return text(it: '$count persone', en: '$count people');
  }

  String paxCount(int count) {
    return '$count pax';
  }

  String guestEntriesCount(int count) {
    return text(it: '$count nominativi', en: '$count guest entries');
  }

  String confirmedCount(int count) {
    return text(it: '$count confermati', en: '$count confirmed');
  }

  String extraGuestEntries(int count) {
    return text(
      it: '+$count altri nominativi',
      en: '+$count more guest entries',
    );
  }

  String radarLabel(String value) {
    return switch (value) {
      'hot' => text(it: 'CALDA', en: 'HOT'),
      'near_full' => text(it: 'QUASI PIENA', en: 'NEAR FULL'),
      'active' => text(it: 'ATTIVA', en: 'ACTIVE'),
      'approved' => text(it: 'APPROVATA', en: 'APPROVED'),
      'checked_in' => text(it: 'ENTRATO', en: 'CHECKED IN'),
      'requested' => text(it: 'IN ATTESA', en: 'PENDING'),
      'cancelled' => text(it: 'ANNULLATA', en: 'CANCELLED'),
      _ => text(it: 'LIBERA', en: 'EASY'),
    };
  }

  String dashboardStatLabel(String rawLabel) {
    return switch (rawLabel.toLowerCase()) {
      'approvati' => text(it: 'Approvati', en: 'Approved'),
      'check-in' => text(it: 'Check-in', en: 'Check-ins'),
      'in attesa' => text(it: 'In attesa', en: 'Pending'),
      'richieste' => text(it: 'Richieste', en: 'Requests'),
      _ => rawLabel,
    };
  }

  String minimumAgeLabel(int? age) {
    if (age == null) {
      return text(it: 'Tutte le eta', en: 'All ages');
    }
    return '$age+';
  }

  String offerTypeLabel(String type) {
    return switch (type) {
      'guest_list_free' => text(it: 'Lista free', en: 'Free list'),
      'guest_list_reduced' => text(it: 'Lista ridotta', en: 'Reduced list'),
      'vip_pass' => text(it: 'Ingresso VIP', en: 'VIP entry'),
      'table' => text(it: 'Tavolo', en: 'Table'),
      'ticket' => text(it: 'Ticket', en: 'Ticket'),
      _ => type,
    };
  }

  String phoneRequirementLabel(PhoneRequirement requirement) {
    return switch (requirement) {
      PhoneRequirement.none => text(
        it: 'Nessun telefono',
        en: 'No phone needed',
      ),
      PhoneRequirement.lead => text(
        it: 'Telefono referente',
        en: 'Lead guest phone',
      ),
      PhoneRequirement.allParticipants => text(
        it: 'Telefono di tutti',
        en: 'Phone for everyone',
      ),
    };
  }

  String contactPreferenceLabel(ContactPreference preference) {
    return switch (preference) {
      ContactPreference.whatsapp => 'WhatsApp',
      ContactPreference.email => text(it: 'Email', en: 'Email'),
      ContactPreference.inbox => text(
        it: 'Inbox NightRadar',
        en: 'NightRadar inbox',
      ),
    };
  }

  String contactRequestStatusLabel(String status) {
    return switch (status) {
      'contacted' => text(it: 'Contattata', en: 'Contacted'),
      'closed' => text(it: 'Chiusa', en: 'Closed'),
      _ => text(it: 'Nuova', en: 'New'),
    };
  }

  String promoterReactionLabel(PromoterReactionType type) {
    return switch (type) {
      PromoterReactionType.heart => text(it: 'Cuori', en: 'Hearts'),
      PromoterReactionType.thumbsUp => text(it: 'Pollici su', en: 'Thumbs up'),
    };
  }

  String guestAccessLabel(GuestAccessType type) {
    return switch (type) {
      GuestAccessType.verifiedUser => text(
        it: 'Utente verificato',
        en: 'Verified user',
      ),
      GuestAccessType.anonymousGuest => text(
        it: 'Guest anonimo',
        en: 'Anonymous guest',
      ),
    };
  }
}

extension AppCopyBuildContext on BuildContext {
  AppCopy get copy => AppCopy(Localizations.localeOf(this));
}
