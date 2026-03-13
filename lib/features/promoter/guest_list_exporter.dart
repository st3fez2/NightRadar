import 'package:intl/intl.dart';

import '../../core/app_copy.dart';
import '../../shared/models.dart';

String buildGuestListExport({
  required AppCopy copy,
  required AppProfile profile,
  required EventSummary event,
  required List<ReservationRecord> reservations,
}) {
  final formatter = DateFormat(
    copy.isEnglish ? 'EEE MMM d yyyy, HH:mm' : 'EEE d MMM yyyy, HH:mm',
    copy.dateLocale,
  );
  final sortedReservations = [...reservations]
    ..sort(
      (left, right) => left.guestName.toLowerCase().compareTo(
            right.guestName.toLowerCase(),
          ),
    );
  final totalGuests = sortedReservations.fold<int>(
    0,
    (sum, reservation) => sum + reservation.partySize,
  );

  final buffer = StringBuffer()
    ..writeln('Night Radar')
    ..writeln(event.title)
    ..writeln('${event.venueName} - ${event.city}')
    ..writeln(
      copy.text(
        it: 'Data: ${formatter.format(event.startsAt)}',
        en: 'Date: ${formatter.format(event.startsAt)}',
      ),
    )
    ..writeln('PR: ${profile.fullName}')
    ..writeln(
      copy.text(
        it: 'Nominativi: ${sortedReservations.length}',
        en: 'Guest entries: ${sortedReservations.length}',
      ),
    )
    ..writeln(copy.text(it: 'Persone: $totalGuests', en: 'People: $totalGuests'))
    ..writeln();

  if (sortedReservations.isEmpty) {
    buffer.writeln(
      copy.text(
        it: 'Nessun nominativo inserito al momento.',
        en: 'No guest entries added yet.',
      ),
    );
  } else {
    for (var index = 0; index < sortedReservations.length; index++) {
      final reservation = sortedReservations[index];
      final parts = <String>[
        '${index + 1}. ${reservation.displayGuestName}',
        '${reservation.partySize} pax',
        reservation.status.toUpperCase(),
      ];

      if (reservation.offerTitle != null && reservation.offerTitle!.trim().isNotEmpty) {
        parts.add(reservation.offerTitle!.trim());
      }

      if (reservation.listName != null && reservation.listName!.trim().isNotEmpty) {
        parts.add(
          copy.text(
            it: 'Lista ${reservation.listName!.trim()}',
            en: 'List ${reservation.listName!.trim()}',
          ),
        );
      }

      buffer.writeln(parts.join(' - '));

      if (reservation.participantDetails.isNotEmpty) {
        for (final participant in reservation.participantDetails) {
          final detail = [
            participant.firstName,
            if (participant.lastName != null && participant.lastName!.trim().isNotEmpty)
              participant.lastName!.trim(),
            if (participant.phone != null && participant.phone!.trim().isNotEmpty)
              participant.phone!.trim(),
          ].join(' - ');
          buffer.writeln('   - $detail');
        }
      }

      if (reservation.notes != null && reservation.notes!.trim().isNotEmpty) {
        buffer.writeln(
          copy.text(
            it: '   Note: ${reservation.notes!.trim()}',
            en: '   Notes: ${reservation.notes!.trim()}',
          ),
        );
      }
    }
  }

  buffer
    ..writeln()
    ..write(copy.text(it: 'Generata con NightRadar', en: 'Generated with NightRadar'));

  return buffer.toString().trim();
}
