import 'package:intl/intl.dart';

import '../../shared/models.dart';

String buildGuestListExport({
  required AppProfile profile,
  required EventSummary event,
  required List<ReservationRecord> reservations,
}) {
  final formatter = DateFormat('EEE d MMM yyyy, HH:mm', 'it_IT');
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
    ..writeln('Data: ${formatter.format(event.startsAt)}')
    ..writeln('PR: ${profile.fullName}')
    ..writeln('Nominativi: ${sortedReservations.length}')
    ..writeln('Persone: $totalGuests')
    ..writeln();

  if (sortedReservations.isEmpty) {
    buffer.writeln('Nessun nominativo inserito al momento.');
  } else {
    for (var index = 0; index < sortedReservations.length; index++) {
      final reservation = sortedReservations[index];
      final parts = <String>[
        '${index + 1}. ${reservation.guestName}',
        '${reservation.partySize} pax',
        reservation.status.toUpperCase(),
      ];

      if (reservation.offerTitle != null && reservation.offerTitle!.trim().isNotEmpty) {
        parts.add(reservation.offerTitle!.trim());
      }

      buffer.writeln(parts.join(' - '));

      if (reservation.notes != null && reservation.notes!.trim().isNotEmpty) {
        buffer.writeln('   Note: ${reservation.notes!.trim()}');
      }
    }
  }

  buffer
    ..writeln()
    ..write('Generata con NightRadar');

  return buffer.toString().trim();
}
