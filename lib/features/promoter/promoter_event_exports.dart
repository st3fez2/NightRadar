import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/app_copy.dart';
import '../../core/public_link_config.dart';
import '../../shared/models.dart';
import 'guest_list_exporter.dart';

String buildPromoterEventPromoText({
  required AppCopy copy,
  required AppProfile profile,
  required EventSummary event,
  required List<EventOffer> offers,
}) {
  final formatter = DateFormat(
    copy.isEnglish ? 'EEE MMM d yyyy, HH:mm' : 'EEE d MMM yyyy, HH:mm',
    copy.dateLocale,
  );
  final publicUrl = PublicLinkConfig.fallbackUrl;
  final lines = <String>[
    event.title,
    '${event.venueName} - ${event.city}',
    copy.text(
      it: 'Data: ${formatter.format(event.startsAt)}',
      en: 'Date: ${formatter.format(event.startsAt)}',
    ),
    if (event.minimumAge != null)
      copy.text(
        it: 'Eta minima: ${copy.minimumAgeLabel(event.minimumAge)}',
        en: 'Minimum age: ${copy.minimumAgeLabel(event.minimumAge)}',
      ),
    if (event.promoCaption?.trim().isNotEmpty == true)
      event.promoCaption!.trim(),
    if (offers.isNotEmpty)
      copy.text(
        it: 'Liste attive: ${offers.map((offer) => offer.title).join(', ')}',
        en: 'Open lists: ${offers.map((offer) => offer.title).join(', ')}',
      ),
    copy.text(
      it: 'Scrivimi su NightRadar o via contatti PR.',
      en: 'Contact me on NightRadar or through promoter channels.',
    ),
    'PR ${profile.fullName}',
    publicUrl,
  ];
  return lines.where((line) => line.trim().isNotEmpty).join('\n');
}

String buildVenueDeliveryExport({
  required AppCopy copy,
  required AppProfile profile,
  required EventSummary event,
  required List<EventOffer> offers,
  required List<ReservationRecord> reservations,
  required List<PromoterContactRequest> contactRequests,
}) {
  final formatter = DateFormat(
    copy.isEnglish ? 'EEE MMM d yyyy, HH:mm' : 'EEE d MMM yyyy, HH:mm',
    copy.dateLocale,
  );
  final totalGuests = reservations.fold<int>(
    0,
    (sum, reservation) => sum + reservation.partySize,
  );
  final openLists = offers
      .where((offer) => offer.spotsLeft == null || offer.spotsLeft! > 0)
      .length;
  final baseList = buildGuestListExport(
    copy: copy,
    profile: profile,
    event: event,
    reservations: reservations,
  );

  final header = [
    copy.text(
      it: 'Invio operativo NightRadar al locale',
      en: 'NightRadar operational delivery to venue',
    ),
    event.title,
    '${event.venueName} - ${event.city}',
    copy.text(
      it: 'Data: ${formatter.format(event.startsAt)}',
      en: 'Date: ${formatter.format(event.startsAt)}',
    ),
    'PR: ${profile.fullName}',
    copy.text(it: 'Liste aperte: $openLists', en: 'Open lists: $openLists'),
    copy.text(
      it: 'Nominativi conferiti: ${reservations.length}',
      en: 'Delivered guest entries: ${reservations.length}',
    ),
    copy.text(
      it: 'Persone totali: $totalGuests',
      en: 'Total people: $totalGuests',
    ),
    if (contactRequests.isNotEmpty)
      copy.text(
        it: 'Richieste PR ancora in inbox: ${contactRequests.length}',
        en: 'Promoter inbox requests still open: ${contactRequests.length}',
      ),
    '',
    baseList,
  ];

  return header.join('\n').trim();
}

Future<Uint8List> buildVenueDeliveryPdf({
  required AppCopy copy,
  required AppProfile profile,
  required EventSummary event,
  required List<EventOffer> offers,
  required List<ReservationRecord> reservations,
  required List<PromoterContactRequest> contactRequests,
}) async {
  final doc = pw.Document();
  final formatter = DateFormat(
    copy.isEnglish ? 'EEE MMM d yyyy, HH:mm' : 'EEE d MMM yyyy, HH:mm',
    copy.dateLocale,
  );
  final totalGuests = reservations.fold<int>(
    0,
    (sum, reservation) => sum + reservation.partySize,
  );

  doc.addPage(
    pw.MultiPage(
      pageTheme: const pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(28),
      ),
      build: (context) => [
        pw.Text(
          'NightRadar',
          style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 6),
        pw.Text(event.title, style: pw.TextStyle(fontSize: 18)),
        pw.SizedBox(height: 4),
        pw.Text('${event.venueName} - ${event.city}'),
        pw.Text(
          copy.text(
            it: 'Data: ${formatter.format(event.startsAt)}',
            en: 'Date: ${formatter.format(event.startsAt)}',
          ),
        ),
        pw.Text('PR: ${profile.fullName}'),
        pw.SizedBox(height: 12),
        pw.Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _pdfBadge(
              copy.text(
                it: 'Liste: ${offers.length}',
                en: 'Lists: ${offers.length}',
              ),
            ),
            _pdfBadge(
              copy.text(
                it: 'Nominativi: ${reservations.length}',
                en: 'Entries: ${reservations.length}',
              ),
            ),
            _pdfBadge(
              copy.text(
                it: 'Persone: $totalGuests',
                en: 'People: $totalGuests',
              ),
            ),
            _pdfBadge(
              copy.text(
                it: 'Inbox: ${contactRequests.length}',
                en: 'Inbox: ${contactRequests.length}',
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 16),
        if (offers.isNotEmpty) ...[
          pw.Text(
            copy.text(
              it: 'Liste e tavoli attivi',
              en: 'Active lists and tables',
            ),
            style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          ...offers.map(
            (offer) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Text(
                '- ${offer.title} | ${copy.offerTypeLabel(offer.type)} | ${copy.priceAmount(offer.price)}',
              ),
            ),
          ),
          pw.SizedBox(height: 14),
        ],
        pw.Text(
          copy.text(it: 'Guest list finale', en: 'Final guest list'),
          style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        if (reservations.isEmpty)
          pw.Text(
            copy.text(
              it: 'Nessun nominativo inserito al momento.',
              en: 'No guest entries added yet.',
            ),
          )
        else
          ...reservations.asMap().entries.map((entry) {
            final reservation = entry.value;
            final index = entry.key + 1;
            final details = <String>[
              '$index. ${reservation.displayGuestName}',
              '${reservation.partySize} pax',
              reservation.status.toUpperCase(),
              copy.guestAccessLabel(reservation.guestAccessType),
              if (reservation.offerTitle?.trim().isNotEmpty == true)
                reservation.offerTitle!.trim(),
            ];
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(details.join(' - ')),
                  if (reservation.participantDetails.isNotEmpty)
                    ...reservation.participantDetails.map(
                      (participant) => pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 12, top: 2),
                        child: pw.Text(
                          [
                            participant.firstName,
                            if (participant.lastName?.trim().isNotEmpty == true)
                              participant.lastName!.trim(),
                            if (participant.phone?.trim().isNotEmpty == true)
                              participant.phone!.trim(),
                          ].join(' - '),
                        ),
                      ),
                    ),
                  if (reservation.guestEmail?.trim().isNotEmpty == true)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(left: 12, top: 2),
                      child: pw.Text(
                        copy.text(
                          it: 'Ricevuta: ${reservation.guestEmail!.trim()}',
                          en: 'Receipt: ${reservation.guestEmail!.trim()}',
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
      ],
    ),
  );

  return doc.save();
}

pw.Widget _pdfBadge(String label) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey400),
      borderRadius: pw.BorderRadius.circular(999),
    ),
    child: pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
  );
}
