import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/app_providers.dart';
import '../../core/widgets/brand_lockup.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/public_link_card.dart';
import '../../shared/models.dart';

class PublicHomeScreen extends ConsumerWidget {
  const PublicHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventFeedProvider);
    final profileAsync = ref.watch(currentProfileProvider);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF6EFE7), Color(0xFFECE5DC)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: -80,
              left: -60,
              child: _GlowOrb(color: Color(0x26E85D3F), size: 220),
            ),
            const Positioned(
              top: 120,
              right: -70,
              child: _GlowOrb(color: Color(0x22186B5B), size: 210),
            ),
            SafeArea(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(eventFeedProvider);
                  ref.invalidate(currentProfileProvider);
                  await ref.read(eventFeedProvider.future);
                },
                child: ResponsivePage(
                  maxWidth: 1120,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final stacked = constraints.maxWidth < 940;
                          final loadedEvents = eventsAsync.valueOrNull;
                          final firstEvent =
                              loadedEvents == null || loadedEvents.isEmpty
                              ? null
                              : loadedEvents.first;

                          if (stacked) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _PublicHero(
                                  profileAsync: profileAsync,
                                  onPrimaryTap: () => context.go('/app'),
                                  onSecondaryTap: firstEvent == null
                                      ? null
                                      : () => context.push(
                                          '/event/${firstEvent.id}',
                                        ),
                                  eventCount: loadedEvents?.length ?? 0,
                                ),
                                const SizedBox(height: 16),
                                const PublicLinkCard(
                                  title: 'Main page con QR sempre pronto',
                                  subtitle:
                                      'Questo e il link pubblico ufficiale da condividere, scaricare o aprire su Android, iPhone e web.',
                                ),
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 6,
                                child: _PublicHero(
                                  profileAsync: profileAsync,
                                  onPrimaryTap: () => context.go('/app'),
                                  onSecondaryTap: firstEvent == null
                                      ? null
                                      : () => context.push(
                                          '/event/${firstEvent.id}',
                                        ),
                                  eventCount: loadedEvents?.length ?? 0,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                flex: 5,
                                child: PublicLinkCard(
                                  title: 'Main page con QR sempre pronto',
                                  subtitle:
                                      'Condividi il sito live, scarica il QR o apri subito la versione pubblica mobile-first del progetto.',
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: const [
                          _ValueCard(
                            title: 'Per i PR',
                            description:
                                'Crei eventi, chiudi le liste, esporti in testo puro e giri tutto su WhatsApp senza passaggi inutili.',
                            accent: Color(0xFFE85D3F),
                            icon: Icons.campaign_rounded,
                          ),
                          _ValueCard(
                            title: 'Per gli utenti',
                            description:
                                'Scopri serate, confronti offerte e tieni il QR personale sempre a portata di mano.',
                            accent: Color(0xFF186B5B),
                            icon: Icons.qr_code_2_rounded,
                          ),
                          _ValueCard(
                            title: 'Per il locale',
                            description:
                                'Riceve solo la lista finale pronta, senza dashboard dedicata e senza attriti operativi.',
                            accent: Color(0xFF18130F),
                            icon: Icons.inventory_2_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Serate live in evidenza',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Landing pubblica ottimizzata per mobile: accesso rapido, look piu deciso e CTA chiare per utenti e PR.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      eventsAsync.when(
                        data: (events) {
                          if (events.isEmpty) {
                            return const EmptyStateCard(
                              title: 'Nessuna serata pubblica al momento',
                              message:
                                  'La landing resta pronta con QR e link pubblico, ma non ci sono eventi attivi da mostrare adesso.',
                            );
                          }

                          final highlights = events.take(3).toList();
                          return Column(
                            children: [
                              for (
                                var index = 0;
                                index < highlights.length;
                                index++
                              ) ...[
                                _LandingEventCard(
                                  event: highlights[index],
                                  onTap: () => context.push(
                                    '/event/${highlights[index].id}',
                                  ),
                                ),
                                if (index != highlights.length - 1)
                                  const SizedBox(height: 12),
                              ],
                            ],
                          );
                        },
                        error: (error, stackTrace) => EmptyStateCard(
                          title: 'Feed pubblico non disponibile',
                          message: error.toString(),
                        ),
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PublicHero extends StatelessWidget {
  const _PublicHero({
    required this.profileAsync,
    required this.onPrimaryTap,
    required this.onSecondaryTap,
    required this.eventCount,
  });

  final AsyncValue<AppProfile?> profileAsync;
  final VoidCallback onPrimaryTap;
  final VoidCallback? onSecondaryTap;
  final int eventCount;

  @override
  Widget build(BuildContext context) {
    final profile = profileAsync.valueOrNull;
    final firstName = profile?.fullName.split(' ').first;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF18130F),
        borderRadius: BorderRadius.circular(36),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2218130F),
            blurRadius: 32,
            offset: Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const NightRadarLockup(
            label: 'NightRadar',
            caption: 'AI nightlife signal',
            textColor: Colors.white,
            iconSize: 58,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroTag(
                label: profile == null
                    ? 'WEB MOBILE FIRST'
                    : 'BENTORNATO ${firstName?.toUpperCase() ?? 'NIGHTRADAR'}',
              ),
              _HeroTag(label: '$eventCount SERATE PUBBLICHE'),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'NightRadar unisce PR e utenti in una home pubblica pronta da condividere.',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontSize: 38,
              height: 1,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'QR sempre visibile, link pubblico unico, esperienza piu rapida su Android e iPhone, con area operativa separata per PR e consumer.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 220,
                child: ElevatedButton.icon(
                  onPressed: onPrimaryTap,
                  icon: const Icon(Icons.rocket_launch_rounded),
                  label: Text(
                    profile == null ? 'Apri NightRadar' : 'Vai alla tua area',
                  ),
                ),
              ),
              SizedBox(
                width: 220,
                child: OutlinedButton.icon(
                  onPressed: onSecondaryTap,
                  icon: const Icon(Icons.local_activity_outlined),
                  label: const Text('Guarda una serata'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              _SignalStat(value: 'QR', label: 'Share, download, link pubblico'),
              _SignalStat(
                value: 'PR',
                label: 'Eventi e guest list esportabili',
              ),
              _SignalStat(value: 'PASS', label: 'Wallet rapido per gli utenti'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroTag extends StatelessWidget {
  const _HeroTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}

class _SignalStat extends StatelessWidget {
  const _SignalStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.78),
            ),
          ),
        ],
      ),
    );
  }
}

class _ValueCard extends StatelessWidget {
  const _ValueCard({
    required this.title,
    required this.description,
    required this.accent,
    required this.icon,
  });

  final String title;
  final String description;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 340,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFE9DDD1)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1018130F),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(description),
          ],
        ),
      ),
    );
  }
}

class _LandingEventCard extends StatelessWidget {
  const _LandingEventCard({required this.event, required this.onTap});

  final EventSummary event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('EEE d MMM, HH:mm', 'it_IT');

    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFE9DDD1)),
        ),
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
                        const SizedBox(height: 8),
                        Text('${event.venueName}  ${event.city}'),
                        const SizedBox(height: 4),
                        Text(formatter.format(event.startsAt)),
                      ],
                    ),
                  ),
                  RadarChip(label: event.radarLabel),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tag in event.musicTags.take(3))
                    Chip(label: Text(tag)),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      event.bestOfferPrice == null
                          ? 'Offerte in aggiornamento'
                          : 'Da EUR ${event.bestOfferPrice!.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text('${event.offerCount} offerte'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(size),
        ),
      ),
    );
  }
}
