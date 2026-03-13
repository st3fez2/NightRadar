import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/app_providers.dart';
import '../../../core/widgets/brand_lockup.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/public_link_card.dart';
import '../../../shared/models.dart';

class UserHomeScreen extends ConsumerStatefulWidget {
  const UserHomeScreen({super.key});

  @override
  ConsumerState<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends ConsumerState<UserHomeScreen> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventFeedProvider);
    final reservationsAsync = ref.watch(myReservationsProvider);
    final profileAsync = ref.watch(currentProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const NightRadarLockup(
          label: 'NightRadar',
          caption: 'User mode',
          iconSize: 34,
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await ref.read(nightRadarRepositoryProvider).signOut();
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(eventFeedProvider);
          ref.invalidate(myReservationsProvider);
          await ref.read(eventFeedProvider.future);
        },
        child: ResponsivePage(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              NightRadarHero(
                title: profileAsync.value == null
                    ? 'La tua notte parte da qui'
                    : 'Ciao ${profileAsync.value!.fullName.split(' ').first}',
                subtitle:
                    'Mappa le serate della citta, confronta offerte e tieni pronto il QR.',
                trailing: const RadarChip(label: 'active'),
              ),
              const SizedBox(height: 18),
              const PublicLinkCard(
                title: 'Condividi NightRadar con il tuo gruppo',
                subtitle:
                    'La home utente tiene sempre visibile QR e link pubblico, cosi puoi girarli al volo ad amici e nuovi invitati.',
              ),
              const SizedBox(height: 18),
              eventsAsync.when(
                data: (events) {
                  final tags = {
                    for (final event in events) ...event.musicTags,
                  }.toList()..sort();
                  final visibleEvents = _filterEvents(events);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _FilterChip(
                              label: 'Tutto',
                              selected: _selectedFilter == 'all',
                              onTap: () =>
                                  setState(() => _selectedFilter = 'all'),
                            ),
                            for (final tag in tags)
                              _FilterChip(
                                label: tag,
                                selected: _selectedFilter == tag,
                                onTap: () =>
                                    setState(() => _selectedFilter = tag),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (visibleEvents.isEmpty)
                        const EmptyStateCard(
                          title: 'Nessuna serata per questo filtro',
                          message:
                              'Cambia genere o torna su "Tutto" per vedere le altre serate.',
                        )
                      else
                        ...visibleEvents.map(
                          (event) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _EventCard(
                              event: event,
                              onTap: () => context.push('/event/${event.id}'),
                            ),
                          ),
                        ),
                    ],
                  );
                },
                error: (error, stackTrace) => EmptyStateCard(
                  title: 'Impossibile caricare le serate',
                  message: error.toString(),
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'I miei pass',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              reservationsAsync.when(
                data: (reservations) {
                  if (reservations.isEmpty) {
                    return const EmptyStateCard(
                      title: 'Ancora nessun pass',
                      message:
                          'Quando prenoti una serata, il tuo QR apparira qui.',
                    );
                  }

                  return Column(
                    children: reservations
                        .take(4)
                        .map(
                          (reservation) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Card(
                              child: ListTile(
                                onTap: () =>
                                    context.push('/wallet/${reservation.id}'),
                                title: Text(reservation.eventTitle),
                                subtitle: Text(
                                  '${reservation.venueName}  ${DateFormat('EEE d MMM, HH:mm', 'it_IT').format(reservation.startsAt)}',
                                ),
                                trailing: RadarChip(label: reservation.status),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
                error: (error, stackTrace) => EmptyStateCard(
                  title: 'Wallet non disponibile',
                  message: error.toString(),
                ),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<EventSummary> _filterEvents(List<EventSummary> events) {
    if (_selectedFilter == 'all') {
      return events;
    }

    return events
        .where((event) => event.musicTags.contains(_selectedFilter))
        .toList();
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, required this.onTap});

  final EventSummary event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('EEE d MMM, HH:mm', 'it_IT');
    final compact = MediaQuery.sizeOf(context).width < 420;

    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: event.coverImageUrl == null
                    ? Container(color: const Color(0xFFEDE5DD))
                    : Image.network(event.coverImageUrl!, fit: BoxFit.cover),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      RadarChip(label: event.radarLabel),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('${event.venueName}  ${event.city}'),
                  const SizedBox(height: 4),
                  Text(formatter.format(event.startsAt)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final tag in event.musicTags.take(3))
                        Chip(label: Text(tag)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  compact
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.bestOfferPrice == null
                                  ? 'Offerte da aggiornare'
                                  : 'Da EUR ${event.bestOfferPrice!.toStringAsFixed(0)}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text('${event.offerCount} offerte'),
                          ],
                        )
                      : Row(
                          children: [
                            Text(
                              event.bestOfferPrice == null
                                  ? 'Offerte da aggiornare'
                                  : 'Da EUR ${event.bestOfferPrice!.toStringAsFixed(0)}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const Spacer(),
                            Text('${event.offerCount} offerte'),
                          ],
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}
