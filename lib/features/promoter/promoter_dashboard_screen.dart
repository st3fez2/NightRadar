import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_providers.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/public_link_card.dart';
import '../../shared/models.dart';
import 'guest_list_exporter.dart';

class PromoterDashboardScreen extends ConsumerWidget {
  const PromoterDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(promoterDashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('NightRadar PR'),
        actions: [
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
                    title:
                        'Ciao ${dashboard.profile.fullName.split(' ').first}',
                    subtitle:
                        'Crea serate, chiudi le liste e gira al locale un messaggio gia pronto per WhatsApp o copia-incolla.',
                    trailing: const RadarChip(label: 'hot'),
                  ),
                  const SizedBox(height: 16),
                  const PublicLinkCard(
                    title: 'Landing pubblica sempre pronta da girare',
                    subtitle:
                        'Il QR della main page resta disponibile anche nell area PR, cosi puoi condividere il progetto in un tocco mentre lavori sulle liste.',
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final stat in dashboard.stats)
                        SizedBox(
                          width: 140,
                          child: MetricCard(
                            label: stat.label,
                            value: stat.value,
                          ),
                        ),
                      SizedBox(
                        width: 140,
                        child: MetricCard(
                          label: 'Locali partner',
                          value: '${dashboard.venues.length}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ResponsiveActionRow(
                    children: [
                      ElevatedButton.icon(
                        onPressed: dashboard.venues.isEmpty
                            ? null
                            : () => _openCreateEventDialog(
                                context,
                                ref,
                                dashboard,
                              ),
                        icon: const Icon(Icons.add_circle_outline_rounded),
                        label: const Text('Nuovo evento'),
                      ),
                      OutlinedButton.icon(
                        onPressed: dashboard.events.isEmpty
                            ? null
                            : () => _openAddReservationDialog(
                                context,
                                ref,
                                dashboard,
                              ),
                        icon: const Icon(Icons.person_add_alt_1_rounded),
                        label: const Text('Nuovo nominativo'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Locali collegati',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (dashboard.venues.isEmpty)
                    const EmptyStateCard(
                      title: 'Nessun locale associato',
                      message:
                          'Collega il tuo profilo PR a un locale per poter creare serate e liste.',
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
                    'Serate e liste',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (dashboard.events.isEmpty)
                    const EmptyStateCard(
                      title: 'Nessuna serata ancora',
                      message:
                          'Crea il tuo primo evento e inizia a raccogliere nominativi da condividere con locale o altri PR.',
                    )
                  else
                    ...dashboard.events.map(
                      (event) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _PromoterEventCard(
                          event: event,
                          reservations:
                              reservationsByEvent[event.id] ?? const [],
                          onOpenEvent: () => context.push('/event/${event.id}'),
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
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Text(
                    'Nominativi recenti',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (dashboard.reservations.isEmpty)
                    const EmptyStateCard(
                      title: 'Nessun nominativo ancora',
                      message:
                          'Quando aggiungi una guest list o arrivano prenotazioni utente, la vedi qui.',
                    )
                  else
                    ...dashboard.reservations
                        .take(12)
                        .map(
                          (reservation) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Card(
                              child: ListTile(
                                title: Text(reservation.guestName),
                                subtitle: Text(
                                  '${reservation.eventTitle}  ·  ${reservation.partySize} pax',
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
            title: 'Dashboard PR non disponibile',
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

  Future<void> _copyGuestList(
    BuildContext context,
    PromoterDashboardData data,
    EventSummary event,
    List<ReservationRecord> reservations,
  ) async {
    final export = buildGuestListExport(
      profile: data.profile,
      event: event,
      reservations: reservations,
    );

    await Clipboard.setData(ClipboardData(text: export));

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Lista ${event.title} copiata negli appunti')),
    );
  }

  Future<void> _shareGuestListOnWhatsApp(
    BuildContext context,
    PromoterDashboardData data,
    EventSummary event,
    List<ReservationRecord> reservations,
  ) async {
    final export = buildGuestListExport(
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
      const SnackBar(
        content: Text('Impossibile aprire WhatsApp su questo dispositivo'),
      ),
    );
  }

  Future<void> _openCreateEventDialog(
    BuildContext context,
    WidgetRef ref,
    PromoterDashboardData data,
  ) async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final genreController = TextEditingController(text: 'house');
    final descriptionController = TextEditingController();
    DateTime startsAt = DateTime.now().add(const Duration(days: 7, hours: 3));
    var selectedVenueId = data.venues.first.id;
    var isSaving = false;
    String? errorText;
    final messenger = ScaffoldMessenger.of(context);

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Nuovo evento PR'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: selectedVenueId,
                        decoration: const InputDecoration(labelText: 'Locale'),
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
                        decoration: const InputDecoration(
                          labelText: 'Titolo evento',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().length < 3) {
                            return 'Inserisci un titolo';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: genreController,
                        decoration: const InputDecoration(labelText: 'Genere'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Descrizione breve',
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Inizio evento'),
                        subtitle: Text(
                          DateFormat(
                            'EEE d MMM yyyy, HH:mm',
                            'it_IT',
                          ).format(startsAt),
                        ),
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
                  child: const Text('Annulla'),
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
                                );

                            ref.invalidate(promoterDashboardProvider);
                            ref.invalidate(eventFeedProvider);

                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Evento creato e pubblicato'),
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
                  child: Text(isSaving ? 'Pubblico...' : 'Pubblica'),
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
  }) async {
    final formKey = GlobalKey<FormState>();
    final guestController = TextEditingController();
    final phoneController = TextEditingController();
    var selectedEventId =
        initialEventId ?? (data.events.isNotEmpty ? data.events.first.id : '');
    var partySize = 2;
    var isSaving = false;
    String? errorText;
    final messenger = ScaffoldMessenger.of(context);

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Nuovo nominativo'),
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
                        decoration: const InputDecoration(labelText: 'Evento'),
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
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: guestController,
                        decoration: const InputDecoration(
                          labelText: 'Nome referente',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().length < 2) {
                            return 'Inserisci il nome';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Telefono',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Inserisci il telefono';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        initialValue: partySize,
                        decoration: const InputDecoration(labelText: 'Persone'),
                        items: List.generate(
                          10,
                          (index) => DropdownMenuItem(
                            value: index + 1,
                            child: Text('${index + 1} persone'),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            partySize = value ?? 1;
                          });
                        },
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
                  child: const Text('Annulla'),
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
                                .createManualReservation(
                                  eventId: selectedEventId,
                                  guestName: guestController.text.trim(),
                                  phone: phoneController.text.trim(),
                                  partySize: partySize,
                                );
                            ref.invalidate(promoterDashboardProvider);
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Nominativo aggiunto alla lista'),
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
                  child: Text(isSaving ? 'Salvo...' : 'Salva'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _PromoterEventCard extends StatelessWidget {
  const _PromoterEventCard({
    required this.event,
    required this.reservations,
    required this.onOpenEvent,
    required this.onAddReservation,
    required this.onCopyList,
    required this.onShareWhatsApp,
  });

  final EventSummary event;
  final List<ReservationRecord> reservations;
  final VoidCallback onOpenEvent;
  final VoidCallback onAddReservation;
  final VoidCallback onCopyList;
  final VoidCallback onShareWhatsApp;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('EEE d MMM, HH:mm', 'it_IT');
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
                      Text(formatter.format(event.startsAt)),
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
                Chip(label: Text('${reservations.length} nominativi')),
                Chip(label: Text('$totalGuests pax')),
                Chip(label: Text('$confirmedCount confermati')),
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
                  label: const Text('Apri'),
                ),
                OutlinedButton.icon(
                  onPressed: onAddReservation,
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text('Aggiungi'),
                ),
                OutlinedButton.icon(
                  onPressed: onCopyList,
                  icon: const Icon(Icons.content_copy_rounded),
                  label: const Text('Copia lista'),
                ),
                ElevatedButton.icon(
                  onPressed: onShareWhatsApp,
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('WhatsApp'),
                ),
              ],
            ),
            if (reservations.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Anteprima lista',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...reservations
                  .take(4)
                  .map(
                    (reservation) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              reservation.guestName,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                          Text('${reservation.partySize} pax'),
                        ],
                      ),
                    ),
                  ),
              if (reservations.length > 4)
                Text('+${reservations.length - 4} altri nominativi'),
            ],
          ],
        ),
      ),
    );
  }
}
