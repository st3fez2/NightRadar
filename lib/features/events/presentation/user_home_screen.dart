import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_copy.dart';
import '../../../core/app_flavor.dart';
import '../../../core/app_providers.dart';
import '../../../core/widgets/brand_lockup.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/flavor_notice_card.dart';
import '../../../core/widgets/language_toggle.dart';
import '../../../core/widgets/public_link_card.dart';
import '../../../shared/models.dart';
import 'drive_time_estimator.dart';
import 'event_like_preferences.dart';
import 'user_discovery_preferences.dart';

class UserHomeScreen extends ConsumerStatefulWidget {
  const UserHomeScreen({super.key});

  @override
  ConsumerState<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends ConsumerState<UserHomeScreen> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final copy = context.copy;
    final eventsAsync = ref.watch(eventFeedProvider);
    final reservationsAsync = ref.watch(myReservationsProvider);
    final profileAsync = ref.watch(currentProfileProvider);
    final discovery = ref.watch(userDiscoveryPreferencesProvider);
    final eventLikes = ref.watch(eventLikePreferencesProvider);

    return Scaffold(
      appBar: AppBar(
        title: NightRadarLockup(
          label: 'NightRadar',
          caption: copy.text(it: 'Area utente', en: 'User mode'),
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
                    ? copy.text(
                        it: 'Sei in due? Parti da stasera',
                        en: 'Going out as two? Start with tonight',
                      )
                    : copy.text(
                        it:
                            'Ciao ${profileAsync.value!.fullName.split(' ').first}',
                        en:
                            'Hi ${profileAsync.value!.fullName.split(' ').first}',
                      ),
                subtitle: copy.text(
                  it:
                      'Filtra per stasera o domani, resta dentro il tuo tempo auto stimato e tieni a portata i PR di cui ti fidi.',
                  en:
                      'Filter for tonight or tomorrow, stay within your estimated drive time, and keep trusted promoters close.',
                ),
                trailing: const RadarChip(label: 'active'),
              ),
              const SizedBox(height: 18),
              PublicLinkCard(
                title: copy.text(
                  it: 'Condividi NightRadar con il tuo gruppo',
                  en: 'Share NightRadar with your group',
                ),
                subtitle: copy.text(
                  it:
                      'La home utente tiene sempre visibile QR e link pubblico, cosi puoi girarli al volo ad amici e nuovi invitati.',
                  en:
                      'The user home keeps QR and public link visible, so you can forward them quickly to friends and new guests.',
                ),
              ),
              if (AppFlavorConfig.isDemo) ...[
                const SizedBox(height: 12),
                const FlavorNoticeCard(compact: true),
              ],
              const SizedBox(height: 18),
              eventsAsync.when(
                data: (events) {
                  final profile = profileAsync.valueOrNull;
                  final tags = {
                    for (final event in events) ...event.musicTags,
                  }.toList()
                    ..sort();
                  final cityOptions = _buildCityOptions(
                    profile: profile,
                    events: events,
                    selectedOriginCity: discovery.originCity,
                  );
                  final effectiveOriginCity = _effectiveOriginCity(
                    profile: profile,
                    discovery: discovery,
                    cityOptions: cityOptions,
                  );
                  final visibleEvents = _filterAndSortEvents(
                    events,
                    discovery: discovery,
                    originCity: effectiveOriginCity,
                  );
                  final suggestedEvent = _pickSuggestedEvent(visibleEvents);
                  final trustedPromoterEvents = visibleEvents
                      .where(
                        (event) =>
                            discovery.isTrustedPromoter(event.primaryPromoterId),
                      )
                      .take(3)
                      .toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DiscoveryPlannerCard(
                        timePlan: discovery.timePlan,
                        maxDriveMinutes: discovery.maxDriveMinutes,
                        originCity: effectiveOriginCity,
                        cityOptions: cityOptions,
                        trustedPromoterNames:
                            discovery.trustedPromoters.values.toList(),
                        onTimePlanChanged: (plan) {
                          ref
                              .read(userDiscoveryPreferencesProvider.notifier)
                              .setTimePlan(plan);
                        },
                        onMaxDriveChanged: (value) {
                          ref
                              .read(userDiscoveryPreferencesProvider.notifier)
                              .setMaxDriveMinutes(value);
                        },
                        onOriginCityChanged: (city) {
                          ref
                              .read(userDiscoveryPreferencesProvider.notifier)
                              .setOriginCity(city);
                        },
                      ),
                      if (suggestedEvent != null) ...[
                        const SizedBox(height: 16),
                        _SuggestionSpotlight(
                          event: suggestedEvent,
                          driveEstimate: estimateDriveTime(
                            originCity: effectiveOriginCity,
                            destinationCity: suggestedEvent.city,
                          ),
                          isTrusted: discovery.isTrustedPromoter(
                            suggestedEvent.primaryPromoterId,
                          ),
                          isLiked: eventLikes.hasLiked(suggestedEvent.id),
                          onOpen: () => context.push('/event/${suggestedEvent.id}'),
                          onToggleLike: () => _toggleEventLike(
                            context,
                            event: suggestedEvent,
                            currentlyLiked: eventLikes.hasLiked(
                              suggestedEvent.id,
                            ),
                          ),
                        ),
                      ],
                      if (trustedPromoterEvents.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        Text(
                          copy.text(
                            it: 'PR fidati da tenere d occhio',
                            en: 'Trusted promoter picks',
                          ),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 10),
                        ...trustedPromoterEvents.map(
                          (event) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _TrustedPromoterEventCard(
                              event: event,
                              driveEstimate: estimateDriveTime(
                                originCity: effectiveOriginCity,
                                destinationCity: event.city,
                              ),
                              isLiked: eventLikes.hasLiked(event.id),
                              onOpen: () => context.push('/event/${event.id}'),
                              onToggleLike: () => _toggleEventLike(
                                context,
                                event: event,
                                currentlyLiked: eventLikes.hasLiked(event.id),
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _FilterChip(
                              label: copy.text(it: 'Tutto', en: 'All'),
                              selected: _selectedFilter == 'all',
                              onTap: () => setState(() => _selectedFilter = 'all'),
                            ),
                            for (final tag in tags)
                              _FilterChip(
                                label: tag,
                                selected: _selectedFilter == tag,
                                onTap: () => setState(() => _selectedFilter = tag),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        copy.text(
                          it: 'Eventi che rientrano nel tuo radar',
                          en: 'Events inside your radar',
                        ),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      if (visibleEvents.isEmpty)
                        EmptyStateCard(
                          title: copy.text(
                            it: 'Nessuna serata compatibile',
                            en: 'No matching events',
                          ),
                          message: copy.text(
                            it:
                                'Prova ad allargare il tempo auto, cambiare giorno oppure togliere il filtro musicale.',
                            en:
                                'Try extending the drive time, changing the day, or clearing the music filter.',
                          ),
                        )
                      else
                        ...visibleEvents.map(
                          (event) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _EventCard(
                              event: event,
                              driveEstimate: estimateDriveTime(
                                originCity: effectiveOriginCity,
                                destinationCity: event.city,
                              ),
                              isTrustedPromoter:
                                  discovery.isTrustedPromoter(
                                    event.primaryPromoterId,
                                  ),
                              isLiked: eventLikes.hasLiked(event.id),
                              onTap: () => context.push('/event/${event.id}'),
                              onToggleLike: () => _toggleEventLike(
                                context,
                                event: event,
                                currentlyLiked: eventLikes.hasLiked(event.id),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
                error: (error, stackTrace) => EmptyStateCard(
                  title: copy.text(
                    it: 'Impossibile caricare le serate',
                    en: 'Unable to load events',
                  ),
                  message: error.toString(),
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                copy.text(it: 'I miei pass', en: 'My passes'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              reservationsAsync.when(
                data: (reservations) {
                  if (reservations.isEmpty) {
                    return EmptyStateCard(
                      title: copy.text(
                        it: 'Ancora nessun pass',
                        en: 'No passes yet',
                      ),
                      message: copy.text(
                        it:
                            'Quando prenoti una serata, il tuo QR apparira qui.',
                        en:
                            'When you reserve an event, your QR will appear here.',
                      ),
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
                                  '${reservation.venueName}  ${copy.shortDateTime(reservation.startsAt)}',
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
                  title: copy.text(
                    it: 'Wallet non disponibile',
                    en: 'Wallet unavailable',
                  ),
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

  Future<void> _toggleEventLike(
    BuildContext context, {
    required EventSummary event,
    required bool currentlyLiked,
  }) async {
    final copy = context.copy;
    final likePreferences = ref.read(eventLikePreferencesProvider);

    try {
      await ref.read(nightRadarRepositoryProvider).toggleEventLike(
            eventId: event.id,
            viewerToken: likePreferences.viewerToken,
          );
      await ref
          .read(eventLikePreferencesProvider.notifier)
          .setLiked(event.id, !currentlyLiked);
      ref.invalidate(eventFeedProvider);
      ref.invalidate(eventDetailsProvider(event.id));
      await ref.read(eventFeedProvider.future);

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !currentlyLiked
                ? copy.text(
                    it: 'Hai lasciato un like a ${event.title}',
                    en: 'You liked ${event.title}',
                  )
                : copy.text(
                    it: 'Hai tolto il like da ${event.title}',
                    en: 'You removed your like from ${event.title}',
                  ),
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  List<String> _buildCityOptions({
    required AppProfile? profile,
    required List<EventSummary> events,
    required String? selectedOriginCity,
  }) {
    final options = <String>{
      if (profile?.city?.trim().isNotEmpty == true) profile!.city!.trim(),
      if (selectedOriginCity?.trim().isNotEmpty == true)
        selectedOriginCity!.trim(),
      for (final event in events)
        if (event.city.trim().isNotEmpty) event.city.trim(),
    }.toList()
      ..sort();
    return options;
  }

  String? _effectiveOriginCity({
    required AppProfile? profile,
    required UserDiscoveryPreferences discovery,
    required List<String> cityOptions,
  }) {
    final selected = discovery.originCity?.trim();
    if (selected != null && selected.isNotEmpty) {
      return selected;
    }
    final profileCity = profile?.city?.trim();
    if (profileCity != null && profileCity.isNotEmpty) {
      return profileCity;
    }
    return cityOptions.isEmpty ? null : cityOptions.first;
  }

  List<EventSummary> _filterAndSortEvents(
    List<EventSummary> events, {
    required UserDiscoveryPreferences discovery,
    required String? originCity,
  }) {
    final now = DateTime.now();
    final filtered = events.where((event) {
      if (_selectedFilter != 'all' &&
          !event.musicTags.contains(_selectedFilter)) {
        return false;
      }
      if (!_matchesTimePlan(event.startsAt, discovery.timePlan, now)) {
        return false;
      }
      final driveEstimate = estimateDriveTime(
        originCity: originCity,
        destinationCity: event.city,
      );
      if (discovery.maxDriveMinutes != null &&
          driveEstimate != null &&
          driveEstimate.minutes > discovery.maxDriveMinutes!) {
        return false;
      }
      return true;
    }).toList();

    filtered.sort(
      (left, right) => _scoreEvent(
        right,
        discovery: discovery,
        originCity: originCity,
      ).compareTo(
        _scoreEvent(
          left,
          discovery: discovery,
          originCity: originCity,
        ),
      ),
    );
    return filtered;
  }

  EventSummary? _pickSuggestedEvent(List<EventSummary> events) {
    if (events.isEmpty) {
      return null;
    }
    return events.first;
  }

  bool _matchesTimePlan(
    DateTime startsAt,
    UserEventTimePlan plan,
    DateTime now,
  ) {
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfTomorrow = startOfToday.add(const Duration(days: 1));
    final startOfDayAfter = startOfTomorrow.add(const Duration(days: 1));

    return switch (plan) {
      UserEventTimePlan.tonight =>
        startsAt.isAfter(now.subtract(const Duration(hours: 2))) &&
        startsAt.isBefore(startOfTomorrow),
      UserEventTimePlan.tomorrow =>
        !startsAt.isBefore(startOfTomorrow) && startsAt.isBefore(startOfDayAfter),
      UserEventTimePlan.flexible => !startsAt.isBefore(startOfToday),
    };
  }

  double _scoreEvent(
    EventSummary event, {
    required UserDiscoveryPreferences discovery,
    required String? originCity,
  }) {
    final driveEstimate = estimateDriveTime(
      originCity: originCity,
      destinationCity: event.city,
    );
    final driveBonus = driveEstimate == null
        ? 8
        : 30 - (driveEstimate.minutes / 3);
    final trustedBonus = discovery.isTrustedPromoter(event.primaryPromoterId)
        ? 25
        : 0;
    final priceBonus = event.bestOfferPrice == null
        ? 8
        : (35 - event.bestOfferPrice!).clamp(0, 20).toDouble();
    final offerBonus = event.offerCount.clamp(0, 6) * 2;
    final likeBonus = (event.likeCount / 3).clamp(0, 8);
    return event.radarScore.toDouble() +
        driveBonus +
        trustedBonus +
        priceBonus +
        offerBonus +
        likeBonus;
  }
}

class _DiscoveryPlannerCard extends StatelessWidget {
  const _DiscoveryPlannerCard({
    required this.timePlan,
    required this.maxDriveMinutes,
    required this.originCity,
    required this.cityOptions,
    required this.trustedPromoterNames,
    required this.onTimePlanChanged,
    required this.onMaxDriveChanged,
    required this.onOriginCityChanged,
  });

  final UserEventTimePlan timePlan;
  final int? maxDriveMinutes;
  final String? originCity;
  final List<String> cityOptions;
  final List<String> trustedPromoterNames;
  final ValueChanged<UserEventTimePlan> onTimePlanChanged;
  final ValueChanged<int?> onMaxDriveChanged;
  final ValueChanged<String?> onOriginCityChanged;

  @override
  Widget build(BuildContext context) {
    final copy = context.copy;
    final compact = MediaQuery.sizeOf(context).width < 440;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              copy.text(
                it: 'Planner rapido per due amici',
                en: 'Quick plan for two friends',
              ),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              copy.text(
                it:
                    'Scegli se stai guardando stasera o domani, imposta la partenza e taglia il feed entro un tempo auto stimato.',
                en:
                    'Choose whether you are looking at tonight or tomorrow, set your starting city, and trim the feed by estimated drive time.',
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _PlannerChip(
                  label: copy.text(it: 'Stasera', en: 'Tonight'),
                  selected: timePlan == UserEventTimePlan.tonight,
                  onTap: () => onTimePlanChanged(UserEventTimePlan.tonight),
                ),
                _PlannerChip(
                  label: copy.text(it: 'Domani', en: 'Tomorrow'),
                  selected: timePlan == UserEventTimePlan.tomorrow,
                  onTap: () => onTimePlanChanged(UserEventTimePlan.tomorrow),
                ),
                _PlannerChip(
                  label: copy.text(it: 'Flessibile', en: 'Flexible'),
                  selected: timePlan == UserEventTimePlan.flexible,
                  onTap: () => onTimePlanChanged(UserEventTimePlan.flexible),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (cityOptions.isNotEmpty)
              DropdownButtonFormField<String?>(
                initialValue: originCity,
                decoration: InputDecoration(
                  labelText: copy.text(
                    it: 'Partenza in auto',
                    en: 'Driving from',
                  ),
                ),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(copy.text(it: 'Scelta automatica', en: 'Auto')),
                  ),
                  for (final city in cityOptions)
                    DropdownMenuItem<String?>(
                      value: city,
                      child: Text(city),
                    ),
                ],
                onChanged: onOriginCityChanged,
              ),
            const SizedBox(height: 14),
            Text(
              copy.text(it: 'Tempo auto massimo', en: 'Max drive time'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _driveOptions(
                      context,
                      selected: maxDriveMinutes,
                    ),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _driveOptions(
                      context,
                      selected: maxDriveMinutes,
                    ),
                  ),
            if (trustedPromoterNames.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                copy.text(it: 'PR salvati', en: 'Saved promoters'),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: trustedPromoterNames
                    .map(
                      (name) => Chip(
                        avatar: const Icon(Icons.star_rounded, size: 16),
                        label: Text(name),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _driveOptions(
    BuildContext context, {
    required int? selected,
  }) {
    final copy = context.copy;
    return [
      _PlannerChip(
        label: copy.text(it: 'Nessun limite', en: 'No limit'),
        selected: selected == null,
        onTap: () => onMaxDriveChanged(null),
      ),
      _PlannerChip(
        label: '30 min',
        selected: selected == 30,
        onTap: () => onMaxDriveChanged(30),
      ),
      _PlannerChip(
        label: '45 min',
        selected: selected == 45,
        onTap: () => onMaxDriveChanged(45),
      ),
      _PlannerChip(
        label: '60 min',
        selected: selected == 60,
        onTap: () => onMaxDriveChanged(60),
      ),
      _PlannerChip(
        label: '90 min',
        selected: selected == 90,
        onTap: () => onMaxDriveChanged(90),
      ),
    ];
  }
}

class _SuggestionSpotlight extends StatelessWidget {
  const _SuggestionSpotlight({
    required this.event,
    required this.driveEstimate,
    required this.isTrusted,
    required this.isLiked,
    required this.onOpen,
    required this.onToggleLike,
  });

  final EventSummary event;
  final DriveTimeEstimate? driveEstimate;
  final bool isTrusted;
  final bool isLiked;
  final VoidCallback onOpen;
  final VoidCallback onToggleLike;

  @override
  Widget build(BuildContext context) {
    final copy = context.copy;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF6F1EB), Color(0xFFFCE6DF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE9DDD1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Chip(
                avatar: const Icon(Icons.auto_awesome_rounded, size: 16),
                label: Text(
                  copy.text(
                    it: 'Suggerimento rapido',
                    en: 'Quick suggestion',
                  ),
                ),
              ),
              RadarChip(label: event.radarLabel),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            event.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text('${event.venueName}  ${event.city}'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (driveEstimate != null)
                Chip(
                  avatar: const Icon(Icons.directions_car_outlined, size: 16),
                  label: Text(
                    copy.text(
                      it:
                          'Auto ~${driveEstimate!.minutes} min da ${driveEstimate!.originCity}',
                      en:
                          'Drive ~${driveEstimate!.minutes} min from ${driveEstimate!.originCity}',
                    ),
                  ),
                ),
              if (event.primaryPromoterName?.trim().isNotEmpty == true)
                Chip(
                  avatar: Icon(
                    isTrusted ? Icons.star_rounded : Icons.person_outline_rounded,
                    size: 16,
                  ),
                  label: Text(
                    isTrusted
                        ? copy.text(
                            it: 'PR fidato: ${event.primaryPromoterName}',
                            en: 'Trusted promoter: ${event.primaryPromoterName}',
                          )
                        : 'PR ${event.primaryPromoterName}',
                  ),
                ),
              Chip(
                avatar: Icon(
                  isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  size: 16,
                ),
                label: Text('${event.likeCount}'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ResponsiveActionRow(
            children: [
              ElevatedButton(
                onPressed: onOpen,
                child: Text(
                  copy.text(it: 'Apri evento', en: 'Open event'),
                ),
              ),
              OutlinedButton.icon(
                onPressed: onToggleLike,
                icon: Icon(
                  isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                ),
                label: Text(
                  isLiked
                      ? copy.text(it: 'Like inviato', en: 'Liked')
                      : copy.text(it: 'Metti like', en: 'Like event'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrustedPromoterEventCard extends StatelessWidget {
  const _TrustedPromoterEventCard({
    required this.event,
    required this.driveEstimate,
    required this.isLiked,
    required this.onOpen,
    required this.onToggleLike,
  });

  final EventSummary event;
  final DriveTimeEstimate? driveEstimate;
  final bool isLiked;
  final VoidCallback onOpen;
  final VoidCallback onToggleLike;

  @override
  Widget build(BuildContext context) {
    final copy = context.copy;
    return Card(
      child: ListTile(
        onTap: onOpen,
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFFCE6DF),
          child: Icon(Icons.star_rounded, color: Color(0xFFE85D3F)),
        ),
        title: Text(event.title),
        subtitle: Text(
          [
            if (event.primaryPromoterName?.trim().isNotEmpty == true)
              'PR ${event.primaryPromoterName}',
            if (driveEstimate != null)
              copy.text(
                it: 'Auto ~${driveEstimate!.minutes} min',
                en: 'Drive ~${driveEstimate!.minutes} min',
              ),
          ].join('  ·  '),
        ),
        trailing: IconButton(
          tooltip: copy.text(it: 'Like evento', en: 'Like event'),
          onPressed: onToggleLike,
          icon: Icon(
            isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: isLiked ? const Color(0xFFE85D3F) : null,
          ),
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.driveEstimate,
    required this.isTrustedPromoter,
    required this.isLiked,
    required this.onTap,
    required this.onToggleLike,
  });

  final EventSummary event;
  final DriveTimeEstimate? driveEstimate;
  final bool isTrustedPromoter;
  final bool isLiked;
  final VoidCallback onTap;
  final VoidCallback onToggleLike;

  @override
  Widget build(BuildContext context) {
    final copy = context.copy;
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
                    ? const EventImagePlaceholder()
                    : Image.network(
                        event.coverImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const EventImagePlaceholder(),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: copy.text(it: 'Like evento', en: 'Like event'),
                        onPressed: onToggleLike,
                        icon: Icon(
                          isLiked
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: isLiked ? const Color(0xFFE85D3F) : null,
                        ),
                      ),
                      RadarChip(label: event.radarLabel),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('${event.venueName}  ${event.city}'),
                  const SizedBox(height: 4),
                  Text(copy.shortDateTime(event.startsAt)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (driveEstimate != null)
                        Chip(
                          avatar: const Icon(Icons.directions_car_outlined, size: 16),
                          label: Text(
                            copy.text(
                              it: 'Auto ~${driveEstimate!.minutes} min',
                              en: 'Drive ~${driveEstimate!.minutes} min',
                            ),
                          ),
                        ),
                      if (event.primaryPromoterName?.trim().isNotEmpty == true)
                        Chip(
                          avatar: Icon(
                            isTrustedPromoter
                                ? Icons.star_rounded
                                : Icons.person_outline_rounded,
                            size: 16,
                          ),
                          label: Text(
                            isTrustedPromoter
                                ? copy.text(
                                    it: 'PR fidato',
                                    en: 'Trusted promoter',
                                  )
                                : 'PR ${event.primaryPromoterName}',
                          ),
                        ),
                      Chip(
                        avatar: Icon(
                          isLiked
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 16,
                        ),
                        label: Text('${event.likeCount}'),
                      ),
                      if (event.minimumAge != null)
                        Chip(
                          label: Text(copy.minimumAgeLabel(event.minimumAge)),
                        ),
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
                                  ? copy.pendingOffersPrice()
                                  : copy.fromPrice(event.bestOfferPrice!),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(copy.offersCount(event.offerCount)),
                          ],
                        )
                      : Row(
                          children: [
                            Text(
                              event.bestOfferPrice == null
                                  ? copy.pendingOffersPrice()
                                  : copy.fromPrice(event.bestOfferPrice!),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const Spacer(),
                            Text(copy.offersCount(event.offerCount)),
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

class _PlannerChip extends StatelessWidget {
  const _PlannerChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
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
