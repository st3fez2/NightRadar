import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_copy.dart';
import '../../core/app_flavor.dart';
import '../../core/app_providers.dart';
import '../../core/public_link_config.dart';
import '../../core/widgets/brand_lockup.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/flavor_notice_card.dart';
import '../../core/widgets/language_toggle.dart';
import '../../core/widgets/public_link_card.dart';
import '../../shared/models.dart';
import 'guest_list_exporter.dart';
import 'promoter_event_exports.dart';

class PromoterDashboardScreen extends ConsumerWidget {
  const PromoterDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copy = context.copy;
    final dashboardAsync = ref.watch(promoterDashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: NightRadarLockup(
          label: 'NightRadar PR',
          caption: copy.text(
            it: 'Controllo guest list',
            en: 'Guest list control',
          ),
          iconSize: 34,
        ),
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Center(child: LanguageToggle(compact: true)),
          ),
          IconButton(
            onPressed: () async {
              await ref.read(nightRadarRepositoryProvider).signOut();
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: dashboardAsync.when(
        data: (dashboard) {
          final reservationsByEvent = _groupReservationsByEvent(
            dashboard.reservations,
          );
          final offersByEvent = _groupOffersByEvent(dashboard.offers);
          final requestsByEvent = _groupRequestsByEvent(
            dashboard.contactRequests,
          );

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(promoterDashboardProvider);
              await ref.read(promoterDashboardProvider.future);
            },
            child: ResponsivePage(
              maxWidth: 860,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  NightRadarHero(
                    title: copy.text(
                      it: 'Ciao ${dashboard.profile.fullName.split(' ').first}',
                      en: 'Hi ${dashboard.profile.fullName.split(' ').first}',
                    ),
                    subtitle: copy.text(
                      it: 'Crea serate, chiudi le liste e gira al locale un messaggio gia pronto per WhatsApp o copia-incolla.',
                      en: 'Create nights, close lists, and send the venue a message already ready for WhatsApp or copy-paste.',
                    ),
                    trailing: const RadarChip(label: 'hot'),
                  ),
                  const SizedBox(height: 16),
                  PublicLinkCard(
                    title: copy.text(
                      it: 'Landing pubblica sempre pronta da girare',
                      en: 'Public landing always ready to share',
                    ),
                    subtitle: copy.text(
                      it: 'Il QR della main page resta disponibile anche nell area PR, cosi puoi condividere il progetto in un tocco mentre lavori sulle liste.',
                      en: 'The main page QR stays available in the promoter area too, so you can share the project in one tap while working on lists.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _PromoterIdentityCard(
                    promoterCard: dashboard.promoterCard,
                    onEdit: AppFlavorConfig.allowMutations
                        ? () => _openPromoterCardDialog(context, ref, dashboard)
                        : null,
                    onOpenInstagram:
                        dashboard.promoterCard.instagramHandle
                                ?.trim()
                                .isNotEmpty ==
                            true
                        ? () => _openSocialProfile(
                            context,
                            _instagramUrl(
                              dashboard.promoterCard.instagramHandle!,
                            ),
                          )
                        : null,
                    onOpenTikTok:
                        dashboard.promoterCard.tiktokHandle
                                ?.trim()
                                .isNotEmpty ==
                            true
                        ? () => _openSocialProfile(
                            context,
                            _tiktokUrl(dashboard.promoterCard.tiktokHandle!),
                          )
                        : null,
                  ),
                  if (AppFlavorConfig.isDemo) ...[
                    const SizedBox(height: 12),
                    const FlavorNoticeCard(compact: true),
                  ],
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final stat in dashboard.stats)
                        SizedBox(
                          width: 140,
                          child: MetricCard(
                            label: copy.dashboardStatLabel(stat.label),
                            value: stat.value,
                          ),
                        ),
                      SizedBox(
                        width: 140,
                        child: MetricCard(
                          label: copy.text(
                            it: 'Locali partner',
                            en: 'Partner venues',
                          ),
                          value: '${dashboard.venues.length}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ResponsiveActionRow(
                    children: [
                      ElevatedButton.icon(
                        onPressed:
                            !AppFlavorConfig.allowMutations ||
                                dashboard.venues.isEmpty
                            ? null
                            : () => _openCreateEventDialog(
                                context,
                                ref,
                                dashboard,
                              ),
                        icon: const Icon(Icons.add_circle_outline_rounded),
                        label: Text(
                          copy.text(it: 'Nuovo evento', en: 'New event'),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed:
                            !AppFlavorConfig.allowMutations ||
                                dashboard.events.isEmpty
                            ? null
                            : () => _openOfferDialog(context, ref, dashboard),
                        icon: const Icon(Icons.playlist_add_rounded),
                        label: Text(
                          copy.text(it: 'Nuova lista', en: 'New list'),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed:
                            !AppFlavorConfig.allowMutations ||
                                dashboard.events.isEmpty
                            ? null
                            : () => _openAddReservationDialog(
                                context,
                                ref,
                                dashboard,
                              ),
                        icon: const Icon(Icons.person_add_alt_1_rounded),
                        label: Text(
                          copy.text(
                            it: 'Nuovo nominativo',
                            en: 'New guest entry',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    copy.text(it: 'Locali collegati', en: 'Linked venues'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (dashboard.venues.isEmpty)
                    EmptyStateCard(
                      title: copy.text(
                        it: 'Nessun locale associato',
                        en: 'No linked venues',
                      ),
                      message: copy.text(
                        it: 'Collega il tuo profilo PR a un locale per poter creare serate e liste.',
                        en: 'Link your promoter profile to a venue so you can create nights and lists.',
                      ),
                    )
                  else
                    ...dashboard.venues.map(
                      (venue) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          child: ListTile(
                            leading: const Icon(Icons.location_on_outlined),
                            title: Text(venue.name),
                            subtitle: Text(
                              '${venue.city}  ${venue.addressLine ?? ''}',
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Text(
                    copy.text(it: 'Serate e liste', en: 'Events and lists'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (dashboard.events.isEmpty)
                    EmptyStateCard(
                      title: copy.text(
                        it: 'Nessuna serata ancora',
                        en: 'No events yet',
                      ),
                      message: copy.text(
                        it: 'Crea il tuo primo evento e inizia a raccogliere nominativi da condividere con locale o altri PR.',
                        en: 'Create your first event and start collecting guest entries to share with venues or other promoters.',
                      ),
                    )
                  else
                    ...dashboard.events.map(
                      (event) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _PromoterEventCard(
                          event: event,
                          offers: offersByEvent[event.id] ?? const [],
                          contactRequests:
                              requestsByEvent[event.id] ?? const [],
                          reservations:
                              reservationsByEvent[event.id] ?? const [],
                          onOpenEvent: () => context.push('/event/${event.id}'),
                          onCreateOffer: () => _openOfferDialog(
                            context,
                            ref,
                            dashboard,
                            initialEventId: event.id,
                          ),
                          onEditOffer: (offer) => _openOfferDialog(
                            context,
                            ref,
                            dashboard,
                            initialEventId: event.id,
                            initialOffer: offer,
                          ),
                          onArchiveOffer: (offer) async {
                            await ref
                                .read(nightRadarRepositoryProvider)
                                .archiveEventOffer(offer.id);
                            ref.invalidate(promoterDashboardProvider);
                          },
                          onAddReservation: () => _openAddReservationDialog(
                            context,
                            ref,
                            dashboard,
                            initialEventId: event.id,
                          ),
                          onCopyList: () => _copyGuestList(
                            context,
                            dashboard,
                            event,
                            reservationsByEvent[event.id] ?? const [],
                          ),
                          onShareWhatsApp: () => _shareGuestListOnWhatsApp(
                            context,
                            dashboard,
                            event,
                            reservationsByEvent[event.id] ?? const [],
                          ),
                          onShareTelegram: () => _shareGuestListOnTelegram(
                            context,
                            dashboard,
                            event,
                            reservationsByEvent[event.id] ?? const [],
                          ),
                          onDownloadPdf: () => _downloadGuestListPdf(
                            context,
                            dashboard,
                            event,
                            offersByEvent[event.id] ?? const [],
                            reservationsByEvent[event.id] ?? const [],
                            requestsByEvent[event.id] ?? const [],
                          ),
                          onSharePdf: () => _shareGuestListPdf(
                            context,
                            dashboard,
                            event,
                            offersByEvent[event.id] ?? const [],
                            reservationsByEvent[event.id] ?? const [],
                            requestsByEvent[event.id] ?? const [],
                          ),
                          onCopyPromo: () => _copyPromoText(
                            context,
                            dashboard,
                            event,
                            offersByEvent[event.id] ?? const [],
                          ),
                          onSharePromoWhatsApp: () => _sharePromoOnWhatsApp(
                            context,
                            dashboard,
                            event,
                            offersByEvent[event.id] ?? const [],
                          ),
                          onSharePromoTelegram: () => _sharePromoOnTelegram(
                            context,
                            dashboard,
                            event,
                            offersByEvent[event.id] ?? const [],
                          ),
                          onSendVenueWhatsApp:
                              event.venueDeliveryPhone?.trim().isNotEmpty ==
                                  true
                              ? () => _sendVenueExportOnWhatsApp(
                                  context,
                                  dashboard,
                                  event,
                                  offersByEvent[event.id] ?? const [],
                                  reservationsByEvent[event.id] ?? const [],
                                  requestsByEvent[event.id] ?? const [],
                                )
                              : null,
                          onSendVenueTelegram:
                              event.venueDeliveryTelegram?.trim().isNotEmpty ==
                                  true
                              ? () => _sendVenueExportOnTelegram(
                                  context,
                                  dashboard,
                                  event,
                                  offersByEvent[event.id] ?? const [],
                                  reservationsByEvent[event.id] ?? const [],
                                  requestsByEvent[event.id] ?? const [],
                                )
                              : null,
                          onSendVenueEmail:
                              event.venueDeliveryEmail?.trim().isNotEmpty ==
                                  true
                              ? () => _sendVenueExportByEmail(
                                  context,
                                  dashboard,
                                  event,
                                  offersByEvent[event.id] ?? const [],
                                  reservationsByEvent[event.id] ?? const [],
                                  requestsByEvent[event.id] ?? const [],
                                )
                              : null,
                          onEditReservation: (reservation) =>
                              _openAddReservationDialog(
                                context,
                                ref,
                                dashboard,
                                initialEventId: event.id,
                                initialReservation: reservation,
                              ),
                          onCancelReservation: (reservation) async {
                            await ref
                                .read(nightRadarRepositoryProvider)
                                .cancelManualReservation(reservation.id);
                            ref.invalidate(promoterDashboardProvider);
                          },
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Text(
                    copy.text(it: 'Inbox PR', en: 'Promoter inbox'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (dashboard.contactRequests.isEmpty)
                    EmptyStateCard(
                      title: copy.text(
                        it: 'Nessuna richiesta in arrivo',
                        en: 'No incoming requests',
                      ),
                      message: copy.text(
                        it: 'Quando utenti o ospiti ti scrivono dall evento, le richieste compaiono qui con risposta rapida.',
                        en: 'When users or guests contact you from the event, requests appear here with quick reply actions.',
                      ),
                    )
                  else
                    ...dashboard.contactRequests
                        .take(12)
                        .map(
                          (request) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ContactRequestCard(
                              request: request,
                              onReplyWhatsApp:
                                  request.requesterPhone?.trim().isNotEmpty ==
                                      true
                                  ? () =>
                                        _openRequesterWhatsApp(context, request)
                                  : null,
                              onReplyEmail:
                                  request.requesterEmail?.trim().isNotEmpty ==
                                      true
                                  ? () => _openRequesterEmail(context, request)
                                  : null,
                              onMarkContacted: AppFlavorConfig.allowMutations
                                  ? () async {
                                      await ref
                                          .read(nightRadarRepositoryProvider)
                                          .updatePromoterContactRequestStatus(
                                            requestId: request.id,
                                            status: 'contacted',
                                          );
                                      ref.invalidate(promoterDashboardProvider);
                                    }
                                  : null,
                              onClose: AppFlavorConfig.allowMutations
                                  ? () async {
                                      await ref
                                          .read(nightRadarRepositoryProvider)
                                          .updatePromoterContactRequestStatus(
                                            requestId: request.id,
                                            status: 'closed',
                                          );
                                      ref.invalidate(promoterDashboardProvider);
                                    }
                                  : null,
                            ),
                          ),
                        ),
                  const SizedBox(height: 20),
                  Text(
                    copy.text(
                      it: 'Nominativi recenti',
                      en: 'Recent guest entries',
                    ),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (dashboard.reservations.isEmpty)
                    EmptyStateCard(
                      title: copy.text(
                        it: 'Nessun nominativo ancora',
                        en: 'No guest entries yet',
                      ),
                      message: copy.text(
                        it: 'Quando aggiungi una guest list o arrivano prenotazioni utente, la vedi qui.',
                        en: 'When you add a guest list or user reservations come in, you will see them here.',
                      ),
                    )
                  else
                    ...dashboard.reservations
                        .take(12)
                        .map(
                          (reservation) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Card(
                              child: ListTile(
                                title: Text(reservation.displayGuestName),
                                subtitle: Text(
                                  '${reservation.eventTitle}  ·  ${reservation.partySize} pax  ·  ${copy.guestAccessLabel(reservation.guestAccessType)}',
                                ),
                                trailing: RadarChip(label: reservation.status),
                              ),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          );
        },
        error: (error, stackTrace) => Center(
          child: EmptyStateCard(
            title: copy.text(
              it: 'Dashboard PR non disponibile',
              en: 'Promoter dashboard unavailable',
            ),
            message: error.toString(),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Map<String, List<ReservationRecord>> _groupReservationsByEvent(
    List<ReservationRecord> reservations,
  ) {
    final grouped = <String, List<ReservationRecord>>{};
    for (final reservation in reservations) {
      grouped.putIfAbsent(reservation.eventId, () => []);
      grouped[reservation.eventId]!.add(reservation);
    }
    return grouped;
  }

  Map<String, List<EventOffer>> _groupOffersByEvent(List<EventOffer> offers) {
    final grouped = <String, List<EventOffer>>{};
    for (final offer in offers) {
      grouped.putIfAbsent(offer.eventId, () => []);
      grouped[offer.eventId]!.add(offer);
    }
    return grouped;
  }

  Map<String, List<PromoterContactRequest>> _groupRequestsByEvent(
    List<PromoterContactRequest> requests,
  ) {
    final grouped = <String, List<PromoterContactRequest>>{};
    for (final request in requests) {
      grouped.putIfAbsent(request.eventId, () => []);
      grouped[request.eventId]!.add(request);
    }
    return grouped;
  }

  Future<void> _copyGuestList(
    BuildContext context,
    PromoterDashboardData data,
    EventSummary event,
    List<ReservationRecord> reservations,
  ) async {
    final copy = context.copy;
    final export = buildGuestListExport(
      copy: copy,
      profile: data.profile,
      event: event,
      reservations: reservations,
    );

    await Clipboard.setData(ClipboardData(text: export));

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          copy.text(
            it: 'Lista ${event.title} copiata negli appunti',
            en: '${event.title} list copied to clipboard',
          ),
        ),
      ),
    );
  }

  Future<void> _shareGuestListOnWhatsApp(
    BuildContext context,
    PromoterDashboardData data,
    EventSummary event,
    List<ReservationRecord> reservations,
  ) async {
    final copy = context.copy;
    final export = buildGuestListExport(
      copy: copy,
      profile: data.profile,
      event: event,
      reservations: reservations,
    );
    final encoded = Uri.encodeComponent(export);
    final whatsappUri = Uri.parse('whatsapp://send?text=$encoded');
    final webUri = Uri.parse('https://wa.me/?text=$encoded');

    final openedApp = await launchUrl(
      whatsappUri,
      mode: LaunchMode.externalApplication,
    );
    final openedWeb = openedApp
        ? true
        : await launchUrl(webUri, mode: LaunchMode.externalApplication);

    if (openedWeb || !context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          copy.text(
            it: 'Impossibile aprire WhatsApp su questo dispositivo',
            en: 'Unable to open WhatsApp on this device',
          ),
        ),
      ),
    );
  }

  Future<void> _shareGuestListOnTelegram(
    BuildContext context,
    PromoterDashboardData data,
    EventSummary event,
    List<ReservationRecord> reservations,
  ) {
    final copy = context.copy;
    final export = buildGuestListExport(
      copy: copy,
      profile: data.profile,
      event: event,
      reservations: reservations,
    );
    return _openTelegramShare(context, export);
  }

  Future<void> _copyPromoText(
    BuildContext context,
    PromoterDashboardData data,
    EventSummary event,
    List<EventOffer> offers,
  ) async {
    final copy = context.copy;
    final promo = buildPromoterEventPromoText(
      copy: copy,
      profile: data.profile,
      event: event,
      offers: offers,
    );
    await Clipboard.setData(ClipboardData(text: promo));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          copy.text(
            it: 'Testo promo copiato per social e chat',
            en: 'Promo text copied for social and chats',
          ),
        ),
      ),
    );
  }

  Future<void> _sharePromoOnWhatsApp(
    BuildContext context,
    PromoterDashboardData data,
    EventSummary event,
    List<EventOffer> offers,
  ) async {
    final copy = context.copy;
    final promo = buildPromoterEventPromoText(
      copy: copy,
      profile: data.profile,
      event: event,
      offers: offers,
    );
    await _openWhatsAppShare(context, promo);
  }

  Future<void> _sharePromoOnTelegram(
    BuildContext context,
    PromoterDashboardData data,
    EventSummary event,
    List<EventOffer> offers,
  ) async {
    final copy = context.copy;
    final promo = buildPromoterEventPromoText(
      copy: copy,
      profile: data.profile,
      event: event,
      offers: offers,
    );
    await _openTelegramShare(context, promo);
  }

  Future<void> _sendVenueExportOnWhatsApp(
    BuildContext context,
    PromoterDashboardData data,
    EventSummary event,
    List<EventOffer> offers,
    List<ReservationRecord> reservations,
    List<PromoterContactRequest> contactRequests,
  ) async {
    final copy = context.copy;
    final export = buildVenueDeliveryExport(
      copy: copy,
      profile: data.profile,
      event: event,
      offers: offers,
      reservations: reservations,
      contactRequests: contactRequests,
    );
    final cleanPhone = event.venueDeliveryPhone!.replaceAll(
      RegExp(r'[^0-9+]'),
      '',
    );
    final encoded = Uri.encodeComponent(export);
    final whatsappUri = Uri.parse(
      'whatsapp://send?phone=$cleanPhone&text=$encoded',
    );
    final webUri = Uri.parse('https://wa.me/$cleanPhone?text=$encoded');
    await _openShareUri(
      context,
      primaryUri: whatsappUri,
      fallbackUri: webUri,
      unableMessage: copy.text(
        it: 'Impossibile aprire WhatsApp su questo dispositivo',
        en: 'Unable to open WhatsApp on this device',
      ),
    );
  }

  Future<void> _sendVenueExportOnTelegram(
    BuildContext context,
    PromoterDashboardData data,
    EventSummary event,
    List<EventOffer> offers,
    List<ReservationRecord> reservations,
    List<PromoterContactRequest> contactRequests,
  ) async {
    final copy = context.copy;
    final export = buildVenueDeliveryExport(
      copy: copy,
      profile: data.profile,
      event: event,
      offers: offers,
      reservations: reservations,
      contactRequests: contactRequests,
    );
    final contact = event.venueDeliveryTelegram!.trim();
    final handle = contact.startsWith('@') ? contact.substring(1) : contact;
    final encoded = Uri.encodeComponent(export);
    final telegramUri = Uri.parse('tg://resolve?domain=$handle&text=$encoded');
    final webUri = Uri.parse('https://t.me/$handle?text=$encoded');
    await _openShareUri(
      context,
      primaryUri: telegramUri,
      fallbackUri: webUri,
      unableMessage: copy.text(
        it: 'Impossibile aprire Telegram su questo dispositivo',
        en: 'Unable to open Telegram on this device',
      ),
    );
  }

  Future<void> _sendVenueExportByEmail(
    BuildContext context,
    PromoterDashboardData data,
    EventSummary event,
    List<EventOffer> offers,
    List<ReservationRecord> reservations,
    List<PromoterContactRequest> contactRequests,
  ) async {
    final copy = context.copy;
    final export = buildVenueDeliveryExport(
      copy: copy,
      profile: data.profile,
      event: event,
      offers: offers,
      reservations: reservations,
      contactRequests: contactRequests,
    );
    final uri = Uri(
      scheme: 'mailto',
      path: event.venueDeliveryEmail,
      queryParameters: {
        'subject': copy.text(
          it: 'Lista finale ${event.title}',
          en: 'Final list ${event.title}',
        ),
        'body': export,
      },
    );
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (opened || !context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          copy.text(
            it: 'Impossibile aprire l app email su questo dispositivo',
            en: 'Unable to open the email app on this device',
          ),
        ),
      ),
    );
  }

  Future<void> _downloadGuestListPdf(
    BuildContext context,
    PromoterDashboardData data,
    EventSummary event,
    List<EventOffer> offers,
    List<ReservationRecord> reservations,
    List<PromoterContactRequest> contactRequests,
  ) async {
    final copy = context.copy;
    final bytes = await buildVenueDeliveryPdf(
      copy: copy,
      profile: data.profile,
      event: event,
      offers: offers,
      reservations: reservations,
      contactRequests: contactRequests,
    );
    await FileSaver.instance.saveFile(
      name: 'nightradar-${_slugify(event.title)}-guest-list',
      bytes: bytes,
      fileExtension: 'pdf',
      mimeType: MimeType.pdf,
    );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          copy.text(it: 'PDF lista scaricato', en: 'Guest list PDF downloaded'),
        ),
      ),
    );
  }

  Future<void> _shareGuestListPdf(
    BuildContext context,
    PromoterDashboardData data,
    EventSummary event,
    List<EventOffer> offers,
    List<ReservationRecord> reservations,
    List<PromoterContactRequest> contactRequests,
  ) async {
    final copy = context.copy;
    final box = context.findRenderObject() as RenderBox?;
    final bytes = await buildVenueDeliveryPdf(
      copy: copy,
      profile: data.profile,
      event: event,
      offers: offers,
      reservations: reservations,
      contactRequests: contactRequests,
    );
    await SharePlus.instance.share(
      ShareParams(
        title: event.title,
        subject: event.title,
        text: buildVenueDeliveryExport(
          copy: copy,
          profile: data.profile,
          event: event,
          offers: offers,
          reservations: reservations,
          contactRequests: contactRequests,
        ),
        files: [
          XFile.fromData(
            bytes,
            mimeType: 'application/pdf',
            name: 'nightradar-${_slugify(event.title)}-guest-list.pdf',
          ),
        ],
        fileNameOverrides: [
          'nightradar-${_slugify(event.title)}-guest-list.pdf',
        ],
        downloadFallbackEnabled: true,
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  Future<void> _openWhatsAppShare(BuildContext context, String text) {
    final copy = context.copy;
    final encoded = Uri.encodeComponent(text);
    return _openShareUri(
      context,
      primaryUri: Uri.parse('whatsapp://send?text=$encoded'),
      fallbackUri: Uri.parse('https://wa.me/?text=$encoded'),
      unableMessage: copy.text(
        it: 'Impossibile aprire WhatsApp su questo dispositivo',
        en: 'Unable to open WhatsApp on this device',
      ),
    );
  }

  Future<void> _openTelegramShare(BuildContext context, String text) {
    final copy = context.copy;
    final encoded = Uri.encodeComponent(text);
    return _openShareUri(
      context,
      primaryUri: Uri.parse('tg://msg?text=$encoded'),
      fallbackUri: Uri.parse(
        'https://t.me/share/url?url=${Uri.encodeComponent(PublicLinkConfig.fallbackUrl)}&text=$encoded',
      ),
      unableMessage: copy.text(
        it: 'Impossibile aprire Telegram su questo dispositivo',
        en: 'Unable to open Telegram on this device',
      ),
    );
  }

  Future<void> _openShareUri(
    BuildContext context, {
    required Uri primaryUri,
    required Uri fallbackUri,
    required String unableMessage,
  }) async {
    final openedPrimary = await launchUrl(
      primaryUri,
      mode: LaunchMode.externalApplication,
    );
    final openedFallback = openedPrimary
        ? true
        : await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
    if (openedFallback || !context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(unableMessage)));
  }

  String _slugify(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  Future<void> _openRequesterWhatsApp(
    BuildContext context,
    PromoterContactRequest request,
  ) async {
    final copy = context.copy;
    final phone = request.requesterPhone?.replaceAll(RegExp(r'[^0-9+]'), '');
    if (phone == null || phone.isEmpty) {
      return;
    }

    final text = Uri.encodeComponent(
      copy.text(
        it: 'Ciao ${request.requesterName}, ti scrivo per ${request.eventTitle} su NightRadar.',
        en: 'Hi ${request.requesterName}, I am contacting you about ${request.eventTitle} on NightRadar.',
      ),
    );
    final whatsappUri = Uri.parse('whatsapp://send?phone=$phone&text=$text');
    final webUri = Uri.parse('https://wa.me/$phone?text=$text');
    final openedApp = await launchUrl(
      whatsappUri,
      mode: LaunchMode.externalApplication,
    );
    final openedWeb = openedApp
        ? true
        : await launchUrl(webUri, mode: LaunchMode.externalApplication);

    if (openedWeb || !context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          copy.text(
            it: 'Impossibile aprire WhatsApp su questo dispositivo',
            en: 'Unable to open WhatsApp on this device',
          ),
        ),
      ),
    );
  }

  Future<void> _openRequesterEmail(
    BuildContext context,
    PromoterContactRequest request,
  ) async {
    final copy = context.copy;
    final email = request.requesterEmail;
    if (email == null || email.trim().isEmpty) {
      return;
    }

    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': copy.text(
          it: 'NightRadar - ${request.eventTitle}',
          en: 'NightRadar - ${request.eventTitle}',
        ),
        'body': copy.text(
          it: 'Ciao ${request.requesterName}, ti scrivo per la tua richiesta su ${request.eventTitle}.',
          en: 'Hi ${request.requesterName}, I am writing about your request for ${request.eventTitle}.',
        ),
      },
    );
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (opened || !context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          copy.text(
            it: 'Impossibile aprire l app email su questo dispositivo',
            en: 'Unable to open the email app on this device',
          ),
        ),
      ),
    );
  }

  Future<void> _openSocialProfile(BuildContext context, String url) async {
    final copy = context.copy;
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (opened || !context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          copy.text(
            it: 'Impossibile aprire il profilo social su questo dispositivo',
            en: 'Unable to open the social profile on this device',
          ),
        ),
      ),
    );
  }

  String _instagramUrl(String handleOrUrl) {
    final normalized = handleOrUrl.trim();
    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      return normalized;
    }
    final handle = normalized.startsWith('@')
        ? normalized.substring(1)
        : normalized;
    return 'https://instagram.com/$handle';
  }

  String _tiktokUrl(String handleOrUrl) {
    final normalized = handleOrUrl.trim();
    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      return normalized;
    }
    final handle = normalized.startsWith('@') ? normalized : '@$normalized';
    return 'https://www.tiktok.com/$handle';
  }

  Future<void> _openCreateEventDialog(
    BuildContext context,
    WidgetRef ref,
    PromoterDashboardData data,
  ) async {
    final copy = context.copy;
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final genreController = TextEditingController(text: 'house');
    final descriptionController = TextEditingController();
    final contactPhoneController = TextEditingController(
      text: data.profile.phone ?? '',
    );
    final contactEmailController = TextEditingController(
      text: data.profile.email ?? '',
    );
    final venueDeliveryNameController = TextEditingController();
    final venueDeliveryPhoneController = TextEditingController();
    final venueDeliveryEmailController = TextEditingController();
    final venueDeliveryTelegramController = TextEditingController();
    final promoCaptionController = TextEditingController();
    DateTime startsAt = DateTime.now().add(const Duration(days: 7, hours: 3));
    int? minimumAge;
    var selectedVenueId = data.venues.first.id;
    var allowWhatsAppRequests = data.profile.phone?.trim().isNotEmpty == true;
    var allowInboxRequests = true;
    var allowEmailRequests = data.profile.email?.trim().isNotEmpty == true;
    var isSaving = false;
    String? errorText;
    final messenger = ScaffoldMessenger.of(context);

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                copy.text(it: 'Nuovo evento PR', en: 'New promoter event'),
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: selectedVenueId,
                        decoration: InputDecoration(
                          labelText: copy.text(it: 'Locale', en: 'Venue'),
                        ),
                        items: data.venues
                            .map(
                              (venue) => DropdownMenuItem(
                                value: venue.id,
                                child: Text(venue.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedVenueId = value ?? selectedVenueId;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: copy.text(
                            it: 'Titolo evento',
                            en: 'Event title',
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().length < 3) {
                            return copy.text(
                              it: 'Inserisci un titolo',
                              en: 'Enter a title',
                            );
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: genreController,
                        decoration: InputDecoration(
                          labelText: copy.text(it: 'Genere', en: 'Genre'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descriptionController,
                        decoration: InputDecoration(
                          labelText: copy.text(
                            it: 'Descrizione breve',
                            en: 'Short description',
                          ),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int?>(
                        initialValue: minimumAge,
                        decoration: InputDecoration(
                          labelText: copy.text(
                            it: 'Eta minima',
                            en: 'Minimum age',
                          ),
                        ),
                        items: [
                          DropdownMenuItem<int?>(
                            value: null,
                            child: Text(
                              copy.text(it: 'Nessun limite', en: 'No limit'),
                            ),
                          ),
                          const DropdownMenuItem(value: 16, child: Text('16+')),
                          const DropdownMenuItem(value: 18, child: Text('18+')),
                          const DropdownMenuItem(value: 21, child: Text('21+')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            minimumAge = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          copy.text(it: 'Inizio evento', en: 'Event start'),
                        ),
                        subtitle: Text(copy.mediumDateTime(startsAt)),
                        trailing: IconButton(
                          icon: const Icon(Icons.calendar_month_rounded),
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                              initialDate: startsAt,
                            );
                            if (date == null || !context.mounted) {
                              return;
                            }
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(startsAt),
                            );
                            if (time == null) {
                              return;
                            }
                            setState(() {
                              startsAt = DateTime(
                                date.year,
                                date.month,
                                date.day,
                                time.hour,
                                time.minute,
                              );
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: contactPhoneController,
                        decoration: InputDecoration(
                          labelText: copy.text(
                            it: 'Telefono WhatsApp PR',
                            en: 'Promoter WhatsApp phone',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: contactEmailController,
                        decoration: InputDecoration(
                          labelText: copy.text(
                            it: 'Email PR',
                            en: 'Promoter email',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: venueDeliveryNameController,
                        decoration: InputDecoration(
                          labelText: copy.text(
                            it: 'Referente locale',
                            en: 'Venue contact name',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: venueDeliveryPhoneController,
                        decoration: InputDecoration(
                          labelText: copy.text(
                            it: 'WhatsApp locale',
                            en: 'Venue WhatsApp phone',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: venueDeliveryTelegramController,
                        decoration: InputDecoration(
                          labelText: copy.text(
                            it: 'Telegram locale',
                            en: 'Venue Telegram',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: venueDeliveryEmailController,
                        decoration: InputDecoration(
                          labelText: copy.text(
                            it: 'Email locale',
                            en: 'Venue email',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: promoCaptionController,
                        decoration: InputDecoration(
                          labelText: copy.text(
                            it: 'Caption promo social',
                            en: 'Social promo caption',
                          ),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: allowWhatsAppRequests,
                        onChanged: (value) {
                          setState(() {
                            allowWhatsAppRequests = value;
                          });
                        },
                        title: Text(
                          copy.text(
                            it: 'Contatto diretto via WhatsApp',
                            en: 'Direct WhatsApp contact',
                          ),
                        ),
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: allowInboxRequests,
                        onChanged: (value) {
                          setState(() {
                            allowInboxRequests = value;
                          });
                        },
                        title: Text(
                          copy.text(
                            it: 'Richieste in inbox NightRadar',
                            en: 'NightRadar inbox requests',
                          ),
                        ),
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: allowEmailRequests,
                        onChanged: (value) {
                          setState(() {
                            allowEmailRequests = value;
                          });
                        },
                        title: Text(
                          copy.text(
                            it: 'Notifica via email al PR',
                            en: 'Email notification to the promoter',
                          ),
                        ),
                      ),
                      if (errorText != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          errorText!,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: Text(copy.text(it: 'Annulla', en: 'Cancel')),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          setState(() {
                            isSaving = true;
                            errorText = null;
                          });

                          try {
                            if (allowWhatsAppRequests &&
                                contactPhoneController.text.trim().isEmpty) {
                              throw copy.text(
                                it: 'Inserisci un numero WhatsApp del PR',
                                en: 'Enter a promoter WhatsApp number',
                              );
                            }
                            if (allowEmailRequests &&
                                contactEmailController.text.trim().isEmpty) {
                              throw copy.text(
                                it: 'Inserisci una mail del PR',
                                en: 'Enter a promoter email',
                              );
                            }
                            await ref
                                .read(nightRadarRepositoryProvider)
                                .createPromoterEvent(
                                  venueId: selectedVenueId,
                                  title: titleController.text.trim(),
                                  startsAt: startsAt,
                                  genre: genreController.text.trim().isEmpty
                                      ? 'commerciale'
                                      : genreController.text.trim(),
                                  description:
                                      descriptionController.text.trim().isEmpty
                                      ? null
                                      : descriptionController.text.trim(),
                                  minimumAge: minimumAge,
                                  contactPhone:
                                      contactPhoneController.text.trim().isEmpty
                                      ? null
                                      : contactPhoneController.text.trim(),
                                  contactEmail:
                                      contactEmailController.text.trim().isEmpty
                                      ? null
                                      : contactEmailController.text.trim(),
                                  venueDeliveryName:
                                      venueDeliveryNameController.text
                                          .trim()
                                          .isEmpty
                                      ? null
                                      : venueDeliveryNameController.text.trim(),
                                  venueDeliveryPhone:
                                      venueDeliveryPhoneController.text
                                          .trim()
                                          .isEmpty
                                      ? null
                                      : venueDeliveryPhoneController.text
                                            .trim(),
                                  venueDeliveryEmail:
                                      venueDeliveryEmailController.text
                                          .trim()
                                          .isEmpty
                                      ? null
                                      : venueDeliveryEmailController.text
                                            .trim(),
                                  venueDeliveryTelegram:
                                      venueDeliveryTelegramController.text
                                          .trim()
                                          .isEmpty
                                      ? null
                                      : venueDeliveryTelegramController.text
                                            .trim(),
                                  promoCaption:
                                      promoCaptionController.text.trim().isEmpty
                                      ? null
                                      : promoCaptionController.text.trim(),
                                  allowWhatsAppRequests: allowWhatsAppRequests,
                                  allowInboxRequests: allowInboxRequests,
                                  allowEmailRequests: allowEmailRequests,
                                );

                            ref.invalidate(promoterDashboardProvider);
                            ref.invalidate(eventFeedProvider);

                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  copy.text(
                                    it: 'Evento creato e pubblicato',
                                    en: 'Event created and published',
                                  ),
                                ),
                              ),
                            );
                          } catch (error) {
                            if (context.mounted) {
                              setState(() {
                                errorText = error.toString();
                              });
                            }
                          } finally {
                            if (context.mounted) {
                              setState(() {
                                isSaving = false;
                              });
                            }
                          }
                        },
                  child: Text(
                    isSaving
                        ? copy.text(it: 'Pubblico...', en: 'Publishing...')
                        : copy.text(it: 'Pubblica', en: 'Publish'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openPromoterCardDialog(
    BuildContext context,
    WidgetRef ref,
    PromoterDashboardData data,
  ) async {
    final copy = context.copy;
    final formKey = GlobalKey<FormState>();
    final displayNameController = TextEditingController(
      text: data.promoterCard.displayName,
    );
    final bioController = TextEditingController(
      text: data.promoterCard.bio ?? '',
    );
    final avatarController = TextEditingController(
      text: data.promoterCard.avatarUrl ?? '',
    );
    final instagramController = TextEditingController(
      text: data.promoterCard.instagramHandle ?? '',
    );
    final tiktokController = TextEditingController(
      text: data.promoterCard.tiktokHandle ?? '',
    );
    var isSaving = false;
    String? errorText;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(copy.text(it: 'Scheda PR', en: 'Promoter card')),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: displayNameController,
                        decoration: InputDecoration(
                          labelText: copy.text(
                            it: 'Nome PR',
                            en: 'Promoter name',
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().length < 2) {
                            return copy.text(
                              it: 'Inserisci il nome della scheda',
                              en: 'Enter the display name',
                            );
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: bioController,
                        decoration: InputDecoration(
                          labelText: copy.text(it: 'Bio', en: 'Bio'),
                        ),
                        maxLines: 4,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: avatarController,
                        decoration: InputDecoration(
                          labelText: copy.text(
                            it: 'URL foto profilo',
                            en: 'Profile photo URL',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: instagramController,
                        decoration: const InputDecoration(
                          labelText: 'Instagram',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: tiktokController,
                        decoration: const InputDecoration(labelText: 'TikTok'),
                      ),
                      if (errorText != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          errorText!,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: Text(copy.text(it: 'Annulla', en: 'Cancel')),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          setState(() {
                            isSaving = true;
                            errorText = null;
                          });

                          try {
                            await ref
                                .read(nightRadarRepositoryProvider)
                                .updatePromoterCard(
                                  displayName: displayNameController.text
                                      .trim(),
                                  bio: bioController.text.trim().isEmpty
                                      ? null
                                      : bioController.text.trim(),
                                  avatarUrl:
                                      avatarController.text.trim().isEmpty
                                      ? null
                                      : avatarController.text.trim(),
                                  instagramHandle:
                                      instagramController.text.trim().isEmpty
                                      ? null
                                      : instagramController.text.trim(),
                                  tiktokHandle:
                                      tiktokController.text.trim().isEmpty
                                      ? null
                                      : tiktokController.text.trim(),
                                );

                            ref.invalidate(promoterDashboardProvider);
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          } catch (error) {
                            if (context.mounted) {
                              setState(() {
                                errorText = error.toString();
                              });
                            }
                          } finally {
                            if (context.mounted) {
                              setState(() {
                                isSaving = false;
                              });
                            }
                          }
                        },
                  child: Text(
                    isSaving
                        ? copy.text(it: 'Salvo...', en: 'Saving...')
                        : copy.text(it: 'Salva', en: 'Save'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openAddReservationDialog(
    BuildContext context,
    WidgetRef ref,
    PromoterDashboardData data, {
    String? initialEventId,
    ReservationRecord? initialReservation,
  }) async {
    final copy = context.copy;
    final formKey = GlobalKey<FormState>();
    final offersByEvent = _groupOffersByEvent(data.offers);
    final guestController = TextEditingController(
      text: initialReservation?.isAnonymousEntry == true
          ? ''
          : initialReservation?.guestName ?? '',
    );
    final lastNameController = TextEditingController(
      text: initialReservation?.guestLastName ?? '',
    );
    final phoneController = TextEditingController(
      text: initialReservation?.guestPhone ?? '',
    );
    final listNameController = TextEditingController(
      text: initialReservation?.listName ?? '',
    );
    final notesController = TextEditingController(
      text: initialReservation?.notes ?? '',
    );
    final participantsController = TextEditingController(
      text: _participantsToMultiline(
        initialReservation?.participantDetails ?? const [],
      ),
    );
    var selectedEventId =
        initialReservation?.eventId ??
        initialEventId ??
        (data.events.isNotEmpty ? data.events.first.id : '');
    var selectedOfferId =
        initialReservation?.offerId ??
        ((offersByEvent[selectedEventId]?.isNotEmpty ?? false)
            ? offersByEvent[selectedEventId]!.first.id
            : null);
    var partySize = initialReservation?.partySize ?? 2;
    var anonymousEntry = initialReservation?.isAnonymousEntry ?? false;
    var isSaving = false;
    String? errorText;
    final messenger = ScaffoldMessenger.of(context);

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                initialReservation == null
                    ? copy.text(it: 'Nuovo nominativo', en: 'New guest entry')
                    : copy.text(
                        it: 'Modifica nominativo',
                        en: 'Edit guest entry',
                      ),
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: selectedEventId.isEmpty
                            ? null
                            : selectedEventId,
                        decoration: InputDecoration(
                          labelText: copy.text(it: 'Evento', en: 'Event'),
                        ),
                        items: data.events
                            .map(
                              (event) => DropdownMenuItem(
                                value: event.id,
                                child: Text(event.title),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedEventId = value ?? '';
                            final eventOffers =
                                offersByEvent[selectedEventId] ?? const [];
                            selectedOfferId = eventOffers.isEmpty
                                ? null
                                : eventOffers.first.id;
                            anonymousEntry = false;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedOfferId,
                        decoration: InputDecoration(
                          labelText: copy.text(it: 'Lista', en: 'List'),
                        ),
                        items: [
                          for (final offer
                              in offersByEvent[selectedEventId] ?? const [])
                            DropdownMenuItem(
                              value: offer.id,
                              child: Text(
                                '${offer.title} · ${copy.offerTypeLabel(offer.type)}',
                              ),
                            ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedOfferId = value;
                            anonymousEntry = false;
                          });
                        },
                      ),
                      if (_selectedOfferFor(
                            offersByEvent,
                            selectedEventId,
                            selectedOfferId,
                          ) !=
                          null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3EBE3),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE0D2C4)),
                          ),
                          child: Text(
                            _offerRulesSummary(
                              copy,
                              _selectedOfferFor(
                                offersByEvent,
                                selectedEventId,
                                selectedOfferId,
                              )!,
                            ),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      if (_selectedOfferFor(
                            offersByEvent,
                            selectedEventId,
                            selectedOfferId,
                          )?.allowAnonymousEntry ==
                          true)
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: anonymousEntry,
                          onChanged: (value) {
                            setState(() {
                              anonymousEntry = value;
                            });
                          },
                          title: Text(
                            copy.text(
                              it: 'Voce anonima',
                              en: 'Anonymous entry',
                            ),
                          ),
                        ),
                      if (_selectedOfferFor(
                            offersByEvent,
                            selectedEventId,
                            selectedOfferId,
                          )?.requiresListName ==
                          true) ...[
                        TextFormField(
                          controller: listNameController,
                          decoration: InputDecoration(
                            labelText: copy.text(
                              it: 'Nome lista o tavolo',
                              en: 'List or table name',
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().length < 2) {
                              return copy.text(
                                it: 'Inserisci il nome lista o tavolo',
                                en: 'Enter the list or table name',
                              );
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (!anonymousEntry) ...[
                        TextFormField(
                          controller: guestController,
                          decoration: InputDecoration(
                            labelText: copy.text(
                              it: 'Nome referente',
                              en: 'Lead guest name',
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().length < 2) {
                              return copy.text(
                                it: 'Inserisci il nome',
                                en: 'Enter the name',
                              );
                            }
                            return null;
                          },
                        ),
                        if (_selectedOfferFor(
                              offersByEvent,
                              selectedEventId,
                              selectedOfferId,
                            )?.collectLastName ==
                            true) ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: lastNameController,
                            decoration: InputDecoration(
                              labelText: copy.text(
                                it: 'Cognome referente',
                                en: 'Lead guest last name',
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().length < 2) {
                                return copy.text(
                                  it: 'Inserisci il cognome',
                                  en: 'Enter the last name',
                                );
                              }
                              return null;
                            },
                          ),
                        ],
                        if (_selectedOfferFor(
                              offersByEvent,
                              selectedEventId,
                              selectedOfferId,
                            )?.phoneRequirement ==
                            PhoneRequirement.lead) ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: phoneController,
                            decoration: InputDecoration(
                              labelText: copy.text(it: 'Telefono', en: 'Phone'),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return copy.text(
                                  it: 'Inserisci il telefono',
                                  en: 'Enter the phone number',
                                );
                              }
                              return null;
                            },
                          ),
                        ],
                      ],
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        initialValue: partySize,
                        decoration: InputDecoration(
                          labelText: copy.text(it: 'Persone', en: 'People'),
                        ),
                        items: List.generate(
                          10,
                          (index) => DropdownMenuItem(
                            value: index + 1,
                            child: Text(copy.peopleCount(index + 1)),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            partySize = value ?? 1;
                          });
                        },
                      ),
                      if (!anonymousEntry &&
                          _selectedOfferFor(
                                offersByEvent,
                                selectedEventId,
                                selectedOfferId,
                              )?.phoneRequirement ==
                              PhoneRequirement.allParticipants) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: participantsController,
                          decoration: InputDecoration(
                            labelText: copy.text(
                              it: 'Partecipanti',
                              en: 'Participants',
                            ),
                            helperText: copy.text(
                              it: 'Una riga per persona: Nome | Cognome | Telefono.',
                              en: 'One line per person: First name | Last name | Phone.',
                            ),
                          ),
                          maxLines: 6,
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: notesController,
                        decoration: InputDecoration(
                          labelText: copy.text(it: 'Note', en: 'Notes'),
                        ),
                        maxLines: 3,
                      ),
                      if (errorText != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          errorText!,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: Text(copy.text(it: 'Annulla', en: 'Cancel')),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }
                          setState(() {
                            isSaving = true;
                            errorText = null;
                          });
                          try {
                            final selectedOffer = _selectedOfferFor(
                              offersByEvent,
                              selectedEventId,
                              selectedOfferId,
                            );
                            final participants =
                                selectedOffer?.phoneRequirement ==
                                    PhoneRequirement.allParticipants
                                ? _parseParticipants(
                                    participantsController.text,
                                    requireLastName:
                                        selectedOffer?.collectLastName ?? false,
                                    requirePhone: true,
                                  )
                                : const <ParticipantRecord>[];
                            if (selectedOffer?.phoneRequirement ==
                                    PhoneRequirement.allParticipants &&
                                participants.length != partySize) {
                              throw FormatException(
                                copy.text(
                                  it: 'Inserisci $partySize righe partecipanti, una per persona.',
                                  en: 'Enter $partySize participant rows, one per person.',
                                ),
                              );
                            }

                            final repository = ref.read(
                              nightRadarRepositoryProvider,
                            );

                            if (initialReservation == null) {
                              await repository.createManualReservation(
                                eventId: selectedEventId,
                                offerId: selectedOfferId,
                                guestName: anonymousEntry
                                    ? 'Anonymous'
                                    : guestController.text.trim(),
                                guestLastName: anonymousEntry
                                    ? null
                                    : _nullIfBlank(lastNameController.text),
                                phone:
                                    anonymousEntry ||
                                        selectedOffer?.phoneRequirement !=
                                            PhoneRequirement.lead
                                    ? null
                                    : _nullIfBlank(phoneController.text),
                                partySize: partySize,
                                listName: _nullIfBlank(listNameController.text),
                                isAnonymousEntry: anonymousEntry,
                                participantDetails: participants,
                                notes: _nullIfBlank(notesController.text),
                              );
                            } else {
                              await repository.updateManualReservation(
                                reservationId: initialReservation.id,
                                guestName: anonymousEntry
                                    ? 'Anonymous'
                                    : guestController.text.trim(),
                                guestLastName: anonymousEntry
                                    ? null
                                    : _nullIfBlank(lastNameController.text),
                                phone:
                                    anonymousEntry ||
                                        selectedOffer?.phoneRequirement !=
                                            PhoneRequirement.lead
                                    ? null
                                    : _nullIfBlank(phoneController.text),
                                partySize: partySize,
                                listName: _nullIfBlank(listNameController.text),
                                isAnonymousEntry: anonymousEntry,
                                participantDetails: participants,
                                notes: _nullIfBlank(notesController.text),
                              );
                            }
                            ref.invalidate(promoterDashboardProvider);
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  initialReservation == null
                                      ? copy.text(
                                          it: 'Nominativo aggiunto alla lista',
                                          en: 'Guest entry added to the list',
                                        )
                                      : copy.text(
                                          it: 'Nominativo aggiornato',
                                          en: 'Guest entry updated',
                                        ),
                                ),
                              ),
                            );
                          } catch (error) {
                            if (context.mounted) {
                              setState(() {
                                errorText = error.toString();
                              });
                            }
                          } finally {
                            if (context.mounted) {
                              setState(() {
                                isSaving = false;
                              });
                            }
                          }
                        },
                  child: Text(
                    isSaving
                        ? copy.text(it: 'Salvo...', en: 'Saving...')
                        : copy.text(it: 'Salva', en: 'Save'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openOfferDialog(
    BuildContext context,
    WidgetRef ref,
    PromoterDashboardData data, {
    String? initialEventId,
    EventOffer? initialOffer,
  }) async {
    final copy = context.copy;
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(
      text: initialOffer?.title ?? '',
    );
    final priceController = TextEditingController(
      text: initialOffer == null ? '0' : initialOffer.price.toStringAsFixed(0),
    );
    final capacityController = TextEditingController(
      text: initialOffer?.capacityTotal?.toString() ?? '',
    );
    final tableGuestCapacityController = TextEditingController(
      text: initialOffer?.tableGuestCapacity?.toString() ?? '',
    );
    final descriptionController = TextEditingController(
      text: initialOffer?.description ?? '',
    );
    final conditionsController = TextEditingController(
      text: initialOffer?.conditions ?? '',
    );
    var selectedEventId =
        initialOffer?.eventId ?? initialEventId ?? data.events.first.id;
    var selectedType = initialOffer?.type ?? 'guest_list_reduced';
    var collectLastName = initialOffer?.collectLastName ?? false;
    var phoneRequirement =
        initialOffer?.phoneRequirement ?? PhoneRequirement.lead;
    var allowAnonymousEntry = initialOffer?.allowAnonymousEntry ?? false;
    var requiresListName = initialOffer?.requiresListName ?? false;
    var showPublicAvailability = initialOffer?.showPublicAvailability ?? false;
    var showQrOnEntry = initialOffer?.showQrOnEntry ?? true;
    var showSecretCodeOnEntry = initialOffer?.showSecretCodeOnEntry ?? false;
    var showListNameOnEntry = initialOffer?.showListNameOnEntry ?? false;
    var isSaving = false;
    String? errorText;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            initialOffer == null
                ? copy.text(it: 'Nuova lista', en: 'New list')
                : copy.text(it: 'Modifica lista', en: 'Edit list'),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedEventId,
                    decoration: InputDecoration(
                      labelText: copy.text(it: 'Evento', en: 'Event'),
                    ),
                    items: data.events
                        .map(
                          (event) => DropdownMenuItem(
                            value: event.id,
                            child: Text(event.title),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedEventId = value ?? selectedEventId;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    decoration: InputDecoration(
                      labelText: copy.text(it: 'Tipo lista', en: 'List type'),
                    ),
                    items:
                        const [
                              'guest_list_free',
                              'guest_list_reduced',
                              'vip_pass',
                              'table',
                            ]
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(copy.offerTypeLabel(type)),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedType = value ?? selectedType;
                        if (selectedType != 'table') {
                          tableGuestCapacityController.clear();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: copy.text(it: 'Nome lista', en: 'List name'),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().length < 2) {
                        return copy.text(
                          it: 'Inserisci il nome lista',
                          en: 'Enter the list name',
                        );
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: priceController,
                    decoration: InputDecoration(
                      labelText: copy.text(it: 'Prezzo', en: 'Price'),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: capacityController,
                    decoration: InputDecoration(
                      labelText: copy.text(
                        it: selectedType == 'table'
                            ? 'Numero tavoli gestibili'
                            : 'Numero ospiti in lista',
                        en: selectedType == 'table'
                            ? 'Managed tables count'
                            : 'Guest-list capacity',
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  if (selectedType == 'table') ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: tableGuestCapacityController,
                      decoration: InputDecoration(
                        labelText: copy.text(
                          it: 'Persone per tavolo',
                          en: 'People per table',
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                  const SizedBox(height: 12),
                  DropdownButtonFormField<PhoneRequirement>(
                    initialValue: phoneRequirement,
                    decoration: InputDecoration(
                      labelText: copy.text(
                        it: 'Regola telefono',
                        en: 'Phone rule',
                      ),
                    ),
                    items: PhoneRequirement.values
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(copy.phoneRequirementLabel(value)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        phoneRequirement = value ?? phoneRequirement;
                      });
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: collectLastName,
                    onChanged: (value) {
                      setState(() {
                        collectLastName = value;
                      });
                    },
                    title: Text(
                      copy.text(
                        it: 'Richiedi anche cognome',
                        en: 'Require last name too',
                      ),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: allowAnonymousEntry,
                    onChanged: (value) {
                      setState(() {
                        allowAnonymousEntry = value;
                      });
                    },
                    title: Text(
                      copy.text(
                        it: 'Consenti voce anonima',
                        en: 'Allow anonymous entry',
                      ),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: requiresListName,
                    onChanged: (value) {
                      setState(() {
                        requiresListName = value;
                      });
                    },
                    title: Text(
                      copy.text(
                        it: 'Usa nome lista o tavolo',
                        en: 'Use list or table name',
                      ),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: showPublicAvailability,
                    onChanged: (value) {
                      setState(() {
                        showPublicAvailability = value;
                      });
                    },
                    title: Text(
                      copy.text(
                        it: selectedType == 'table'
                            ? 'Mostra tavoli residui agli utenti'
                            : 'Mostra disponibilita residua agli utenti',
                        en: selectedType == 'table'
                            ? 'Show remaining tables to users'
                            : 'Show remaining availability to users',
                      ),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: showQrOnEntry,
                    onChanged: (value) {
                      setState(() {
                        showQrOnEntry = value;
                      });
                    },
                    title: Text(
                      copy.text(
                        it: 'Mostra QR all ingresso',
                        en: 'Show QR at the entrance',
                      ),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: showSecretCodeOnEntry,
                    onChanged: (value) {
                      setState(() {
                        showSecretCodeOnEntry = value;
                      });
                    },
                    title: Text(
                      copy.text(
                        it: 'Mostra codice segreto',
                        en: 'Show secret code',
                      ),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: showListNameOnEntry,
                    onChanged: (value) {
                      setState(() {
                        showListNameOnEntry = value;
                      });
                    },
                    title: Text(
                      copy.text(
                        it: 'Mostra nome lista o tavolo',
                        en: 'Show list or table name',
                      ),
                    ),
                  ),
                  TextFormField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: copy.text(
                        it: 'Descrizione',
                        en: 'Description',
                      ),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: conditionsController,
                    decoration: InputDecoration(
                      labelText: copy.text(
                        it: 'Condizioni o note',
                        en: 'Conditions or notes',
                      ),
                    ),
                    maxLines: 2,
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorText!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.of(context).pop(),
              child: Text(copy.text(it: 'Annulla', en: 'Cancel')),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) {
                        return;
                      }
                      setState(() {
                        isSaving = true;
                        errorText = null;
                      });
                      if (!showQrOnEntry &&
                          !showSecretCodeOnEntry &&
                          !showListNameOnEntry) {
                        setState(() {
                          isSaving = false;
                          errorText = copy.text(
                            it: 'Seleziona almeno un elemento visibile all ingresso: QR, codice o nome lista.',
                            en: 'Select at least one entrance credential: QR, code, or list name.',
                          );
                        });
                        return;
                      }
                      try {
                        final repository = ref.read(
                          nightRadarRepositoryProvider,
                        );
                        if (initialOffer == null) {
                          await repository.createEventOffer(
                            eventId: selectedEventId,
                            title: titleController.text.trim(),
                            type: selectedType,
                            price: double.tryParse(priceController.text) ?? 0,
                            capacityTotal: int.tryParse(
                              capacityController.text,
                            ),
                            tableGuestCapacity: int.tryParse(
                              tableGuestCapacityController.text,
                            ),
                            description: _nullIfBlank(
                              descriptionController.text,
                            ),
                            conditions: _nullIfBlank(conditionsController.text),
                            collectLastName: collectLastName,
                            phoneRequirement: phoneRequirement,
                            allowAnonymousEntry: allowAnonymousEntry,
                            requiresListName: requiresListName,
                            showPublicAvailability: showPublicAvailability,
                            showQrOnEntry: showQrOnEntry,
                            showSecretCodeOnEntry: showSecretCodeOnEntry,
                            showListNameOnEntry: showListNameOnEntry,
                          );
                        } else {
                          await repository.updateEventOffer(
                            offerId: initialOffer.id,
                            title: titleController.text.trim(),
                            type: selectedType,
                            price: double.tryParse(priceController.text) ?? 0,
                            capacityTotal: int.tryParse(
                              capacityController.text,
                            ),
                            tableGuestCapacity: int.tryParse(
                              tableGuestCapacityController.text,
                            ),
                            description: _nullIfBlank(
                              descriptionController.text,
                            ),
                            conditions: _nullIfBlank(conditionsController.text),
                            collectLastName: collectLastName,
                            phoneRequirement: phoneRequirement,
                            allowAnonymousEntry: allowAnonymousEntry,
                            requiresListName: requiresListName,
                            showPublicAvailability: showPublicAvailability,
                            showQrOnEntry: showQrOnEntry,
                            showSecretCodeOnEntry: showSecretCodeOnEntry,
                            showListNameOnEntry: showListNameOnEntry,
                          );
                        }
                        ref.invalidate(promoterDashboardProvider);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      } catch (error) {
                        setState(() {
                          errorText = error.toString();
                        });
                      } finally {
                        if (context.mounted) {
                          setState(() {
                            isSaving = false;
                          });
                        }
                      }
                    },
              child: Text(copy.text(it: 'Salva lista', en: 'Save list')),
            ),
          ],
        ),
      ),
    );
  }

  EventOffer? _selectedOfferFor(
    Map<String, List<EventOffer>> offersByEvent,
    String eventId,
    String? offerId,
  ) {
    if (offerId == null) {
      return null;
    }

    for (final offer in offersByEvent[eventId] ?? const <EventOffer>[]) {
      if (offer.id == offerId) {
        return offer;
      }
    }

    return null;
  }

  List<ParticipantRecord> _parseParticipants(
    String raw, {
    required bool requireLastName,
    required bool requirePhone,
  }) {
    final lines = raw
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    return lines.map((line) {
      final parts = line.split('|').map((part) => part.trim()).toList();
      final firstName = parts.isNotEmpty ? parts[0] : '';
      final lastName = parts.length > 1 && parts[1].isNotEmpty
          ? parts[1]
          : null;
      final phone = parts.length > 2 && parts[2].isNotEmpty ? parts[2] : null;

      if (firstName.length < 2) {
        throw const FormatException('Missing first name');
      }
      if (requireLastName && (lastName == null || lastName.length < 2)) {
        throw const FormatException('Missing last name');
      }
      if (requirePhone && (phone == null || phone.isEmpty)) {
        throw const FormatException('Missing phone');
      }

      return ParticipantRecord(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      );
    }).toList();
  }

  String _participantsToMultiline(List<ParticipantRecord> participants) {
    return participants
        .map(
          (participant) => [
            participant.firstName,
            participant.lastName ?? '',
            participant.phone ?? '',
          ].join(' | '),
        )
        .join('\n');
  }

  String _offerRulesSummary(AppCopy copy, EventOffer offer) {
    final tokens = <String>[
      copy.offerTypeLabel(offer.type),
      copy.phoneRequirementLabel(offer.phoneRequirement),
    ];
    if (offer.collectLastName) {
      tokens.add(copy.text(it: 'cognome richiesto', en: 'last name required'));
    }
    if (offer.requiresListName) {
      tokens.add(copy.text(it: 'nome lista/tavolo', en: 'list/table name'));
    }
    if (offer.allowAnonymousEntry) {
      tokens.add(copy.text(it: 'anonimo consentito', en: 'anonymous allowed'));
    }
    return tokens.join(' · ');
  }

  String? _nullIfBlank(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _PromoterEventCard extends StatelessWidget {
  const _PromoterEventCard({
    required this.event,
    required this.offers,
    required this.contactRequests,
    required this.reservations,
    required this.onOpenEvent,
    required this.onCreateOffer,
    required this.onEditOffer,
    required this.onArchiveOffer,
    required this.onAddReservation,
    required this.onCopyList,
    required this.onShareWhatsApp,
    required this.onShareTelegram,
    required this.onDownloadPdf,
    required this.onSharePdf,
    required this.onCopyPromo,
    required this.onSharePromoWhatsApp,
    required this.onSharePromoTelegram,
    this.onSendVenueWhatsApp,
    this.onSendVenueTelegram,
    this.onSendVenueEmail,
    required this.onEditReservation,
    required this.onCancelReservation,
  });

  final EventSummary event;
  final List<EventOffer> offers;
  final List<PromoterContactRequest> contactRequests;
  final List<ReservationRecord> reservations;
  final VoidCallback onOpenEvent;
  final VoidCallback onCreateOffer;
  final ValueChanged<EventOffer> onEditOffer;
  final ValueChanged<EventOffer> onArchiveOffer;
  final VoidCallback onAddReservation;
  final VoidCallback onCopyList;
  final VoidCallback onShareWhatsApp;
  final VoidCallback onShareTelegram;
  final VoidCallback onDownloadPdf;
  final VoidCallback onSharePdf;
  final VoidCallback onCopyPromo;
  final VoidCallback onSharePromoWhatsApp;
  final VoidCallback onSharePromoTelegram;
  final VoidCallback? onSendVenueWhatsApp;
  final VoidCallback? onSendVenueTelegram;
  final VoidCallback? onSendVenueEmail;
  final ValueChanged<ReservationRecord> onEditReservation;
  final ValueChanged<ReservationRecord> onCancelReservation;

  @override
  Widget build(BuildContext context) {
    final copy = context.copy;
    final canOperate = AppFlavorConfig.allowMutations && !event.isClosed;
    final totalGuests = reservations.fold<int>(
      0,
      (sum, reservation) => sum + reservation.partySize,
    );
    final confirmedCount = reservations
        .where(
          (reservation) =>
              reservation.status == 'approved' ||
              reservation.status == 'checked_in',
        )
        .length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Text('${event.venueName}  ${event.city}'),
                      const SizedBox(height: 4),
                      Text(copy.shortDateTime(event.startsAt)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(
                            avatar: Icon(
                              event.isClosed
                                  ? Icons.lock_clock_outlined
                                  : event.isLiveNow
                                  ? Icons.bolt_rounded
                                  : Icons.event_available_outlined,
                              size: 16,
                            ),
                            label: Text(_eventLifecycleLabel(copy, event)),
                          ),
                          if (event.likeCount > 0)
                            Chip(
                              avatar: const Icon(
                                Icons.favorite_rounded,
                                size: 16,
                              ),
                              label: Text('${event.likeCount}'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                RadarChip(label: event.radarLabel),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(copy.guestEntriesCount(reservations.length))),
                Chip(label: Text(copy.paxCount(totalGuests))),
                Chip(label: Text(copy.confirmedCount(confirmedCount))),
                if (event.minimumAge != null)
                  Chip(label: Text(copy.minimumAgeLabel(event.minimumAge))),
                Chip(
                  label: Text(
                    copy.text(
                      it: '${offers.length} liste',
                      en: '${offers.length} lists',
                    ),
                  ),
                ),
                if (contactRequests.isNotEmpty)
                  Chip(
                    label: Text(
                      copy.text(
                        it: '${contactRequests.length} richieste',
                        en: '${contactRequests.length} requests',
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton.icon(
                  onPressed: onOpenEvent,
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: Text(copy.text(it: 'Apri', en: 'Open')),
                ),
                OutlinedButton.icon(
                  onPressed: canOperate ? onCreateOffer : null,
                  icon: const Icon(Icons.playlist_add_rounded),
                  label: Text(copy.text(it: 'Lista', en: 'List')),
                ),
                OutlinedButton.icon(
                  onPressed: canOperate ? onAddReservation : null,
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: Text(copy.text(it: 'Aggiungi', en: 'Add')),
                ),
                OutlinedButton.icon(
                  onPressed: onCopyList,
                  icon: const Icon(Icons.content_copy_rounded),
                  label: Text(copy.text(it: 'Copia lista', en: 'Copy list')),
                ),
                ElevatedButton.icon(
                  onPressed: onShareWhatsApp,
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('WhatsApp'),
                ),
                OutlinedButton.icon(
                  onPressed: onShareTelegram,
                  icon: const Icon(Icons.send_outlined),
                  label: const Text('Telegram'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              copy.text(it: 'Promo e social', en: 'Promo and social'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onCopyPromo,
                  icon: const Icon(Icons.campaign_outlined),
                  label: Text(copy.text(it: 'Copia promo', en: 'Copy promo')),
                ),
                OutlinedButton.icon(
                  onPressed: onSharePromoWhatsApp,
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: const Text('WhatsApp'),
                ),
                OutlinedButton.icon(
                  onPressed: onSharePromoTelegram,
                  icon: const Icon(Icons.send_outlined),
                  label: const Text('Telegram'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              copy.text(it: 'Invio al locale', en: 'Venue delivery'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (event.hasVenueDeliveryChannel ||
                event.venueDeliveryName?.trim().isNotEmpty == true)
              Text(
                [
                  if (event.venueDeliveryName?.trim().isNotEmpty == true)
                    event.venueDeliveryName!.trim(),
                  if (event.venueDeliveryPhone?.trim().isNotEmpty == true)
                    'WA ${event.venueDeliveryPhone!.trim()}',
                  if (event.venueDeliveryTelegram?.trim().isNotEmpty == true)
                    'TG ${event.venueDeliveryTelegram!.trim()}',
                  if (event.venueDeliveryEmail?.trim().isNotEmpty == true)
                    event.venueDeliveryEmail!.trim(),
                ].join('  ·  '),
              )
            else
              Text(
                copy.text(
                  it: 'Nessun contatto locale impostato: puoi comunque copiare o scaricare il materiale finale.',
                  en: 'No venue contact set yet: you can still copy or download the final material.',
                ),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onCopyList,
                  icon: const Icon(Icons.content_copy_rounded),
                  label: Text(copy.text(it: 'Copia', en: 'Copy')),
                ),
                OutlinedButton.icon(
                  onPressed: onDownloadPdf,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('PDF'),
                ),
                OutlinedButton.icon(
                  onPressed: onSharePdf,
                  icon: const Icon(Icons.ios_share_rounded),
                  label: Text(copy.text(it: 'Condividi PDF', en: 'Share PDF')),
                ),
                if (onSendVenueWhatsApp != null)
                  ElevatedButton.icon(
                    onPressed: onSendVenueWhatsApp,
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('WhatsApp'),
                  ),
                if (onSendVenueTelegram != null)
                  OutlinedButton.icon(
                    onPressed: onSendVenueTelegram,
                    icon: const Icon(Icons.send_outlined),
                    label: const Text('Telegram'),
                  ),
                if (onSendVenueEmail != null)
                  OutlinedButton.icon(
                    onPressed: onSendVenueEmail,
                    icon: const Icon(Icons.mail_outline_rounded),
                    label: Text(copy.text(it: 'Email', en: 'Email')),
                  ),
              ],
            ),
            if (offers.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                event.isClosed
                    ? copy.text(it: 'Liste chiuse', en: 'Closed lists')
                    : copy.text(it: 'Liste aperte', en: 'Open lists'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...offers.map(
                (offer) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F1EB),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                offer.title,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            Chip(label: Text(copy.offerTypeLabel(offer.type))),
                            if (canOperate)
                              IconButton(
                                onPressed: () => onEditOffer(offer),
                                icon: const Icon(Icons.edit_outlined),
                                visualDensity: VisualDensity.compact,
                              ),
                            if (canOperate)
                              IconButton(
                                onPressed: () => onArchiveOffer(offer),
                                icon: const Icon(Icons.archive_outlined),
                                visualDensity: VisualDensity.compact,
                              ),
                          ],
                        ),
                        Text(
                          _PromoterEventCard._offerSummary(copy, offer),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            if (reservations.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                copy.text(it: 'Anteprima lista', en: 'List preview'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...reservations
                  .take(4)
                  .map(
                    (reservation) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  reservation.displayGuestName,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  copy.guestAccessLabel(
                                    reservation.guestAccessType,
                                  ),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Text(copy.paxCount(reservation.partySize)),
                          if (canOperate) ...[
                            IconButton(
                              onPressed: () => onEditReservation(reservation),
                              icon: const Icon(Icons.edit_outlined),
                              visualDensity: VisualDensity.compact,
                            ),
                            IconButton(
                              onPressed: () => onCancelReservation(reservation),
                              icon: const Icon(Icons.close_rounded),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
              if (reservations.length > 4)
                Text(copy.extraGuestEntries(reservations.length - 4)),
            ],
          ],
        ),
      ),
    );
  }

  static String _offerSummary(AppCopy copy, EventOffer offer) {
    final parts = <String>[copy.phoneRequirementLabel(offer.phoneRequirement)];
    if (offer.isTableOffer) {
      if (offer.capacityTotal != null) {
        parts.add(
          copy.text(
            it: '${offer.capacityTotal} tavoli',
            en: '${offer.capacityTotal} tables',
          ),
        );
      }
      if (offer.spotsLeft != null) {
        parts.add(
          copy.text(
            it: '${offer.spotsLeft} residui',
            en: '${offer.spotsLeft} left',
          ),
        );
      }
      if (offer.tableGuestCapacity != null) {
        parts.add(
          copy.text(
            it: '${offer.tableGuestCapacity} pax per tavolo',
            en: '${offer.tableGuestCapacity} people per table',
          ),
        );
      }
      if (offer.reservedEntries > 0) {
        parts.add(
          copy.text(
            it: '${offer.reservedEntries} tavoli prenotati',
            en: '${offer.reservedEntries} tables booked',
          ),
        );
      }
    } else {
      if (offer.capacityTotal != null) {
        parts.add(
          copy.text(
            it: '${offer.capacityTotal} posti',
            en: '${offer.capacityTotal} spots',
          ),
        );
      }
      if (offer.spotsLeft != null) {
        parts.add(
          copy.text(
            it: '${offer.spotsLeft} residui',
            en: '${offer.spotsLeft} left',
          ),
        );
      }
      if (offer.reservedGuests > 0) {
        parts.add(
          copy.text(
            it: '${offer.reservedGuests} ospiti prenotati',
            en: '${offer.reservedGuests} guests booked',
          ),
        );
      }
    }
    if (offer.collectLastName) {
      parts.add(copy.text(it: 'cognome', en: 'last name'));
    }
    if (offer.requiresListName) {
      parts.add(copy.text(it: 'nome lista/tavolo', en: 'list/table name'));
    }
    if (offer.allowAnonymousEntry) {
      parts.add(copy.text(it: 'anonimo', en: 'anonymous'));
    }
    if (offer.showPublicAvailability) {
      parts.add(copy.text(it: 'residuo pubblico', en: 'public availability'));
    }
    final entryParts = <String>[];
    if (offer.showQrOnEntry) {
      entryParts.add('QR');
    }
    if (offer.showSecretCodeOnEntry) {
      entryParts.add(copy.text(it: 'codice', en: 'code'));
    }
    if (offer.showListNameOnEntry) {
      entryParts.add(copy.text(it: 'nome lista', en: 'list name'));
    }
    if (entryParts.isNotEmpty) {
      parts.add(
        copy.text(
          it: 'ingresso ${entryParts.join('/')}',
          en: 'entry ${entryParts.join('/')}',
        ),
      );
    }
    return parts.join(' · ');
  }

  static String _eventLifecycleLabel(AppCopy copy, EventSummary event) {
    if (event.isClosed) {
      return copy.text(it: 'Chiuso', en: 'Closed');
    }
    if (event.isLiveNow) {
      return copy.text(it: 'Live ora', en: 'Live now');
    }
    return copy.text(it: 'Programmato', en: 'Scheduled');
  }
}

class _PromoterIdentityCard extends StatelessWidget {
  const _PromoterIdentityCard({
    required this.promoterCard,
    this.onEdit,
    this.onOpenInstagram,
    this.onOpenTikTok,
  });

  final PromoterProfileCard promoterCard;
  final VoidCallback? onEdit;
  final VoidCallback? onOpenInstagram;
  final VoidCallback? onOpenTikTok;

  @override
  Widget build(BuildContext context) {
    final copy = context.copy;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PromoterAvatarPreview(
              avatarUrl: promoterCard.avatarUrl,
              label: promoterCard.displayName,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        promoterCard.displayName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Chip(
                        label: Text(
                          'Rating ${promoterCard.rating.toStringAsFixed(1)}',
                        ),
                      ),
                      if (promoterCard.isVerified)
                        Chip(
                          label: Text(
                            copy.text(it: 'Verificato', en: 'Verified'),
                          ),
                        ),
                      Chip(
                        avatar: const Icon(
                          Icons.thumb_up_alt_rounded,
                          size: 16,
                        ),
                        label: Text('${promoterCard.reactions.thumbsUpCount}'),
                      ),
                      Chip(
                        avatar: const Icon(Icons.favorite_rounded, size: 16),
                        label: Text('${promoterCard.reactions.heartCount}'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    promoterCard.bio?.trim().isNotEmpty == true
                        ? promoterCard.bio!
                        : copy.text(
                            it: 'Questa e la tua scheda PR pubblica: personalizzala per risaltare sugli eventi condivisi con altri PR.',
                            en: 'This is your public promoter card: customize it to stand out on events shared with other promoters.',
                          ),
                  ),
                  if (promoterCard.instagramHandle?.trim().isNotEmpty == true ||
                      promoterCard.tiktokHandle?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (promoterCard.instagramHandle?.trim().isNotEmpty ==
                            true)
                          ActionChip(
                            avatar: const Icon(
                              Icons.camera_alt_outlined,
                              size: 16,
                            ),
                            label: Text(promoterCard.instagramHandle!),
                            onPressed: onOpenInstagram,
                          ),
                        if (promoterCard.tiktokHandle?.trim().isNotEmpty ==
                            true)
                          ActionChip(
                            avatar: const Icon(
                              Icons.music_note_rounded,
                              size: 16,
                            ),
                            label: Text(promoterCard.tiktokHandle!),
                            onPressed: onOpenTikTok,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (onEdit != null) ...[
              const SizedBox(width: 12),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ContactRequestCard extends StatelessWidget {
  const _ContactRequestCard({
    required this.request,
    this.onReplyWhatsApp,
    this.onReplyEmail,
    this.onMarkContacted,
    this.onClose,
  });

  final PromoterContactRequest request;
  final VoidCallback? onReplyWhatsApp;
  final VoidCallback? onReplyEmail;
  final VoidCallback? onMarkContacted;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final copy = context.copy;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.requesterName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(request.eventTitle),
                      if (request.offerTitle?.trim().isNotEmpty == true)
                        Text(
                          '${copy.text(it: 'Offerta', en: 'Offer')}: ${request.offerTitle}',
                        ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(copy.contactRequestStatusLabel(request.status)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${copy.peopleCount(request.partySize)}  ·  ${copy.contactPreferenceLabel(request.replyPreference)}',
            ),
            if (request.requesterContactLabel.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(request.requesterContactLabel),
            ],
            const SizedBox(height: 10),
            Text(request.message),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (onReplyWhatsApp != null)
                  OutlinedButton.icon(
                    onPressed: onReplyWhatsApp,
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                    label: const Text('WhatsApp'),
                  ),
                if (onReplyEmail != null)
                  OutlinedButton.icon(
                    onPressed: onReplyEmail,
                    icon: const Icon(Icons.mail_outline_rounded),
                    label: Text(copy.text(it: 'Email', en: 'Email')),
                  ),
                if (onMarkContacted != null)
                  TextButton(
                    onPressed: onMarkContacted,
                    child: Text(
                      copy.text(it: 'Segna contattata', en: 'Mark contacted'),
                    ),
                  ),
                if (onClose != null)
                  TextButton(
                    onPressed: onClose,
                    child: Text(copy.text(it: 'Chiudi', en: 'Close')),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoterAvatarPreview extends StatelessWidget {
  const _PromoterAvatarPreview({required this.avatarUrl, required this.label});

  final String? avatarUrl;
  final String label;

  @override
  Widget build(BuildContext context) {
    if (avatarUrl?.trim().isNotEmpty == true) {
      return CircleAvatar(
        radius: 30,
        backgroundImage: NetworkImage(avatarUrl!),
      );
    }

    final initial = label.trim().isEmpty
        ? 'P'
        : label.trim().substring(0, 1).toUpperCase();

    return CircleAvatar(
      radius: 30,
      backgroundColor: const Color(0xFFE85D3F),
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
