import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/app_providers.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../shared/models.dart';

class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({
    super.key,
    required this.eventId,
  });

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventDetailsProvider(eventId));

    return Scaffold(
      appBar: AppBar(),
      body: eventAsync.when(
        data: (event) => ResponsivePage(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
            if (event.summary.coverImageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    event.summary.coverImageUrl!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    event.summary.title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                RadarChip(label: event.summary.radarLabel),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${event.venue.name}  ${event.venue.city}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('EEEE d MMMM, HH:mm', 'it_IT')
                  .format(event.summary.startsAt),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Venue', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 10),
                    Text(event.venue.addressLine ?? event.venue.name),
                    if (event.venue.dressCode != null) ...[
                      const SizedBox(height: 8),
                      Text('Dress code: ${event.venue.dressCode}'),
                    ],
                    if (event.summary.entryPolicy != null) ...[
                      const SizedBox(height: 8),
                      Text('Policy: ${event.summary.entryPolicy}'),
                    ],
                    if (event.description != null) ...[
                      const SizedBox(height: 12),
                      Text(event.description!),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Offerte attive',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Text('${event.offers.length} disponibili'),
              ],
            ),
            const SizedBox(height: 12),
            if (event.offers.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text('Nessuna offerta attiva al momento'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => context.push(
                          '/event/$eventId/reserve',
                        ),
                        child: const Text('Richiedi accesso generico'),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...event.offers.map(
                (offer) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _OfferCard(
                    offer: offer,
                    onTap: () => context.push(
                      '/event/$eventId/reserve?offerId=${offer.id}',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: EmptyStateCard(
              title: 'Errore nel dettaglio evento',
              message: error.toString(),
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.offer,
    required this.onTap,
  });

  final EventOffer offer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    offer.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Text(
                  offer.price == 0
                      ? 'FREE'
                      : 'EUR ${offer.price.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            if (offer.promoterName != null) ...[
              const SizedBox(height: 8),
              Text(
                'PR ${offer.promoterName}  rating ${(offer.promoterRating ?? 0).toStringAsFixed(1)}',
              ),
            ],
            if (offer.description != null) ...[
              const SizedBox(height: 8),
              Text(offer.description!),
            ],
            if (offer.conditions != null) ...[
              const SizedBox(height: 8),
              Text(offer.conditions!),
            ],
            if (offer.spotsLeft != null) ...[
              const SizedBox(height: 8),
              Text('Posti residui: ${offer.spotsLeft}'),
            ],
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: onTap,
              child: const Text('Prenota con questa offerta'),
            ),
          ],
        ),
      ),
    );
  }
}
