import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_copy.dart';
import '../../core/app_flavor.dart';
import '../../core/app_providers.dart';
import '../../core/widgets/brand_lockup.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/flavor_notice_card.dart';
import '../../core/widgets/language_toggle.dart';
import '../../core/widgets/public_link_card.dart';
import '../../shared/models.dart';

class PublicHomeScreen extends ConsumerWidget {
  const PublicHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copy = context.copy;
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
                      const Align(
                        alignment: Alignment.centerRight,
                        child: LanguageToggle(),
                      ),
                      const SizedBox(height: 12),
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
                                PublicLinkCard(
                                  title: copy.text(
                                    it: 'Main page con QR sempre pronto',
                                    en: 'Main page with QR always ready',
                                  ),
                                  subtitle: copy.text(
                                    it: 'Questo e il link pubblico ufficiale da condividere, scaricare o aprire su Android, iPhone e web.',
                                    en: 'This is the official public link to share, download, or open on Android, iPhone, and web.',
                                  ),
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
                              Expanded(
                                flex: 5,
                                child: PublicLinkCard(
                                  title: copy.text(
                                    it: 'Main page con QR sempre pronto',
                                    en: 'Main page with QR always ready',
                                  ),
                                  subtitle: copy.text(
                                    it: 'Condividi il sito live, scarica il QR o apri subito la versione pubblica mobile-first del progetto.',
                                    en: 'Share the live site, download the QR, or open the public mobile-first version of the product right away.',
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      if (AppFlavorConfig.isDemo) ...[
                        const SizedBox(height: 16),
                        const FlavorNoticeCard(),
                      ],
                      const SizedBox(height: 16),
                      InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () => context.push('/legal?from=/'),
                        child: Ink(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.82),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFFE0D2C4)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                height: 44,
                                width: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4E6DB),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.policy_outlined,
                                  color: Color(0xFFE85D3F),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      copy.text(
                                        it: 'Disclaimer e privacy sempre accessibili',
                                        en: 'Disclaimer and privacy always available',
                                      ),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      copy.text(
                                        it: 'NightRadar richiede accettazione iniziale e lascia i testi legali sempre riapribili dal web pubblico.',
                                        en: 'NightRadar requires initial acceptance and keeps the legal texts always accessible again from the public web page.',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Icon(Icons.arrow_forward_rounded),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        copy.text(
                          it: 'Serate live in evidenza',
                          en: 'Highlighted live nights',
                        ),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        copy.text(
                          it: 'Landing pubblica ottimizzata per mobile: accesso rapido, look piu deciso e CTA chiare per utenti e PR.',
                          en: 'Public landing optimized for mobile: faster access, a sharper look, and clearer CTAs for users and promoters.',
                        ),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      eventsAsync.when(
                        data: (events) {
                          if (events.isEmpty) {
                            return EmptyStateCard(
                              title: copy.text(
                                it: 'Nessuna serata pubblica al momento',
                                en: 'No public events right now',
                              ),
                              message: copy.text(
                                it: 'La landing resta pronta con QR e link pubblico, ma non ci sono eventi attivi da mostrare adesso.',
                                en: 'The landing stays ready with QR and public link, but there are no active events to show right now.',
                              ),
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
                          title: copy.text(
                            it: 'Feed pubblico non disponibile',
                            en: 'Public feed unavailable',
                          ),
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
    final copy = context.copy;
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
          NightRadarLockup(
            label: 'NightRadar',
            caption: copy.text(
              it: 'Segnale nightlife AI',
              en: 'AI nightlife signal',
            ),
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
                    ? copy.text(it: 'WEB MOBILE FIRST', en: 'WEB MOBILE FIRST')
                    : copy.text(
                        it: 'BENTORNATO ${firstName?.toUpperCase() ?? 'NIGHTRADAR'}',
                        en: 'WELCOME BACK ${firstName?.toUpperCase() ?? 'NIGHTRADAR'}',
                      ),
              ),
              if (AppFlavorConfig.isDemo)
                _HeroTag(label: AppFlavorConfig.modeLabel),
              _HeroTag(
                label: copy.text(
                  it: '$eventCount SERATE PUBBLICHE',
                  en: '$eventCount PUBLIC EVENTS',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            AppFlavorConfig.isDemo
                ? copy.text(
                    it: 'NightRadar Demo mostra utenti e PR in una vetrina rapida, pensata per farti capire il prodotto in pochi tocchi.',
                    en: 'NightRadar Demo shows users and promoters in a quick showcase built to explain the product in just a few taps.',
                  )
                : copy.text(
                    it: 'NightRadar unisce PR e utenti in una home pubblica pronta da condividere.',
                    en: 'NightRadar brings promoters and users together in a public home page ready to share.',
                  ),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontSize: 38,
              height: 1,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            AppFlavorConfig.isDemo
                ? copy.text(
                    it: 'QR sempre visibile, account demo pronti e navigazione read-only. Quando vuoi lavorare davvero su eventi, liste e prenotazioni, passi alla versione attiva.',
                    en: 'QR always visible, demo accounts ready, and read-only navigation. When you want to work for real on events, lists, and reservations, switch to the live version.',
                  )
                : copy.text(
                    it: 'QR sempre visibile, link pubblico unico, esperienza piu rapida su Android e iPhone, con area operativa separata per PR e consumer.',
                    en: 'QR always visible, one public link, faster experience on Android and iPhone, with a separate operational area for promoters and users.',
                  ),
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
                    profile == null
                        ? (AppFlavorConfig.isDemo
                              ? copy.text(it: 'Apri la demo', en: 'Open demo')
                              : copy.text(
                                  it: 'Apri NightRadar',
                                  en: 'Open NightRadar',
                                ))
                        : copy.text(
                            it: 'Vai alla tua area',
                            en: 'Go to your area',
                          ),
                  ),
                ),
              ),
              if (AppFlavorConfig.isDemo)
                SizedBox(
                  width: 220,
                  child: OutlinedButton.icon(
                    onPressed: onSecondaryTap,
                    icon: const Icon(Icons.local_activity_outlined),
                    label: Text(
                      copy.text(it: 'Guarda una serata', en: 'View an event'),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _SignalStat(
                value: 'QR',
                label: copy.text(
                  it: 'Share, download, link pubblico',
                  en: 'Share, download, public link',
                ),
              ),
              _SignalStat(
                value: 'PR',
                label: copy.text(
                  it: 'Eventi e guest list esportabili',
                  en: 'Exportable events and guest lists',
                ),
              ),
              _SignalStat(
                value: 'PASS',
                label: copy.text(
                  it: 'Wallet rapido per gli utenti',
                  en: 'Fast wallet for users',
                ),
              ),
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

class _LandingEventCard extends StatelessWidget {
  const _LandingEventCard({required this.event, required this.onTap});

  final EventSummary event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final copy = context.copy;

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
                        Text(copy.shortDateTime(event.startsAt)),
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
                  if (event.minimumAge != null)
                    Chip(label: Text(copy.minimumAgeLabel(event.minimumAge))),
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
                          ? copy.unavailableOffersPrice()
                          : copy.fromPrice(event.bestOfferPrice!),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text(copy.offersCount(event.offerCount)),
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
