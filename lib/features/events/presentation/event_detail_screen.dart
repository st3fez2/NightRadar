import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/app_copy.dart';
import '../../../core/app_flavor.dart';
import '../../../core/app_providers.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/flavor_notice_card.dart';
import '../../../core/widgets/language_toggle.dart';
import '../../../shared/models.dart';
import 'event_like_preferences.dart';
import 'user_discovery_preferences.dart';

class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copy = context.copy;
    final eventAsync = ref.watch(eventDetailsProvider(eventId));
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final discovery = ref.watch(userDiscoveryPreferencesProvider);
    final eventLikes = ref.watch(eventLikePreferencesProvider);

    return Scaffold(
      appBar: AppBar(
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: Center(child: LanguageToggle(compact: true)),
          ),
        ],
      ),
      body: eventAsync.when(
        data: (event) {
          final topPromoterId = _findTopPromoterId(event.offers);

          return ResponsivePage(
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
                        errorBuilder: (context, error, stackTrace) =>
                            const EventImagePlaceholder(),
                      ),
                    ),
                  ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                Text(copy.longDateTime(event.summary.startsAt)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      avatar: Icon(
                        eventLikes.hasLiked(event.summary.id)
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 18,
                        color: eventLikes.hasLiked(event.summary.id)
                            ? const Color(0xFFE85D3F)
                            : null,
                      ),
                      label: Text('${event.summary.likeCount}'),
                      onPressed: () => _toggleEventLike(
                        context,
                        ref,
                        event.summary,
                        eventLikes.hasLiked(event.summary.id),
                      ),
                    ),
                    if (event.summary.primaryPromoterName?.trim().isNotEmpty ==
                        true)
                      Chip(
                        avatar: Icon(
                          discovery.isTrustedPromoter(
                                event.summary.primaryPromoterId,
                              )
                              ? Icons.star_rounded
                              : Icons.person_outline_rounded,
                          size: 18,
                        ),
                        label: Text(
                          discovery.isTrustedPromoter(
                                event.summary.primaryPromoterId,
                              )
                              ? copy.text(
                                  it: 'PR fidato',
                                  en: 'Trusted promoter',
                                )
                              : 'PR ${event.summary.primaryPromoterName}',
                        ),
                      ),
                  ],
                ),
                if (event.summary.minimumAge != null) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Chip(
                      avatar: const Icon(Icons.badge_outlined, size: 18),
                      label: Text(
                        copy.minimumAgeLabel(event.summary.minimumAge),
                      ),
                    ),
                  ),
                ],
                if (AppFlavorConfig.isDemo) ...[
                  const SizedBox(height: 16),
                  const FlavorNoticeCard(compact: true),
                ],
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          copy.text(it: 'Locale', en: 'Venue'),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
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
                if (event.offers.isEmpty && event.promoterContact != null) ...[
                  const SizedBox(height: 18),
                  _GeneralContactCard(
                    event: event,
                    onWhatsApp:
                        AppFlavorConfig.allowMutations &&
                            event.promoterContact!.whatsappEnabled &&
                            event.promoterContact!.phone?.trim().isNotEmpty ==
                                true
                        ? () => _openPromoterWhatsApp(
                            context,
                            copy,
                            phone: event.promoterContact!.phone!,
                            eventTitle: event.summary.title,
                            promoterName: event.promoterContact!.displayName,
                          )
                        : null,
                    onEmail:
                        AppFlavorConfig.allowMutations &&
                            event.promoterContact!.emailEnabled &&
                            event.promoterContact!.email?.trim().isNotEmpty ==
                                true
                        ? () => _openPromoterEmail(
                            context,
                            copy,
                            email: event.promoterContact!.email!,
                            eventTitle: event.summary.title,
                            promoterName: event.promoterContact!.displayName,
                          )
                        : null,
                    onRequest:
                        AppFlavorConfig.allowMutations &&
                            event.promoterContact!.inboxEnabled
                        ? () => _openContactRequestDialog(
                            context,
                            ref,
                            event,
                            profile,
                          )
                        : null,
                    onInstagram:
                        event.promoterContact!.instagramHandle
                                ?.trim()
                                .isNotEmpty ==
                            true
                        ? () => _openSocialProfile(
                            context,
                            _instagramUrl(
                              event.promoterContact!.instagramHandle!,
                            ),
                          )
                        : null,
                    onTikTok:
                        event.promoterContact!.tiktokHandle
                                ?.trim()
                                .isNotEmpty ==
                            true
                        ? () => _openSocialProfile(
                            context,
                            _tiktokUrl(event.promoterContact!.tiktokHandle!),
                          )
                        : null,
                    trustedPromoter: discovery.isTrustedPromoter(
                      event.promoterContact!.promoterId,
                    ),
                    onToggleTrustedPromoter:
                        event.promoterContact!.promoterId == null
                        ? null
                        : () => _toggleTrustedPromoter(
                            context,
                            ref,
                            promoterId: event.promoterContact!.promoterId!,
                            promoterName:
                                event.promoterContact!.displayName ?? 'PR',
                            isTrusted: discovery.isTrustedPromoter(
                              event.promoterContact!.promoterId,
                            ),
                          ),
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        copy.text(it: 'Offerte attive', en: 'Active offers'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Text(copy.availableCount(event.offers.length)),
                  ],
                ),
                const SizedBox(height: 12),
                if (event.offers.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            copy.text(
                              it: 'Nessuna offerta attiva al momento',
                              en: 'No active offers at the moment',
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: AppFlavorConfig.allowMutations
                                ? () => context.push('/event/$eventId/reserve')
                                : null,
                            child: Text(
                              AppFlavorConfig.allowMutations
                                  ? copy.text(
                                      it: 'Richiedi accesso generico',
                                      en: 'Request general access',
                                    )
                                  : copy.text(
                                      it: 'Disponibile nella versione attiva',
                                      en: 'Available in the live version',
                                    ),
                            ),
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
                        highlightPromoter:
                            offer.promoterId != null &&
                            offer.promoterId == topPromoterId,
                        onReserve: AppFlavorConfig.allowMutations
                            ? () => context.push(
                                '/event/$eventId/reserve?offerId=${offer.id}',
                              )
                            : null,
                        onWhatsApp:
                            AppFlavorConfig.allowMutations &&
                                offer.promoterPhone?.trim().isNotEmpty == true
                            ? () => _openPromoterWhatsApp(
                                context,
                                copy,
                                phone: offer.promoterPhone!,
                                eventTitle: event.summary.title,
                                promoterName: offer.promoterName,
                                offerTitle: offer.title,
                              )
                            : null,
                        onEmail:
                            AppFlavorConfig.allowMutations &&
                                offer.promoterEmail?.trim().isNotEmpty == true
                            ? () => _openPromoterEmail(
                                context,
                                copy,
                                email: offer.promoterEmail!,
                                eventTitle: event.summary.title,
                                promoterName: offer.promoterName,
                                offerTitle: offer.title,
                              )
                            : null,
                        onRequest: AppFlavorConfig.allowMutations
                            ? () => _openContactRequestDialog(
                                context,
                                ref,
                                event,
                                profile,
                                initialOfferId: offer.id,
                              )
                            : null,
                        onInstagram:
                            offer.promoterInstagramHandle?.trim().isNotEmpty ==
                                true
                            ? () => _openSocialProfile(
                                context,
                                _instagramUrl(offer.promoterInstagramHandle!),
                              )
                            : null,
                        onTikTok:
                            offer.promoterTiktokHandle?.trim().isNotEmpty ==
                                true
                            ? () => _openSocialProfile(
                                context,
                                _tiktokUrl(offer.promoterTiktokHandle!),
                              )
                            : null,
                        trustedPromoter: discovery.isTrustedPromoter(
                          offer.promoterId,
                        ),
                        onToggleTrustedPromoter: offer.promoterId == null
                            ? null
                            : () => _toggleTrustedPromoter(
                                context,
                                ref,
                                promoterId: offer.promoterId!,
                                promoterName: offer.promoterName ?? 'PR',
                                isTrusted: discovery.isTrustedPromoter(
                                  offer.promoterId,
                                ),
                              ),
                        onToggleThumbsUp: offer.promoterId == null
                            ? null
                            : () => _togglePromoterReaction(
                                context,
                                ref,
                                promoterId: offer.promoterId!,
                                reactionType: PromoterReactionType.thumbsUp,
                                profile: profile,
                              ),
                        onToggleHeart: offer.promoterId == null
                            ? null
                            : () => _togglePromoterReaction(
                                context,
                                ref,
                                promoterId: offer.promoterId!,
                                reactionType: PromoterReactionType.heart,
                                profile: profile,
                              ),
                        reactionsEnabled: AppFlavorConfig.allowMutations,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
        error: (error, stackTrace) => ScreenStatusView(
          title: copy.text(
            it: 'Errore nel dettaglio evento',
            en: 'Event detail error',
          ),
          message: error.toString(),
        ),
        loading: () => ScreenStatusView(
          title: copy.text(
            it: 'Sto aprendo l evento',
            en: 'Opening the event',
          ),
          message: copy.text(
            it: 'Recupero offerte, dettagli e contatti del PR.',
            en: 'Loading offers, event details, and promoter contacts.',
          ),
          loading: true,
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

  String? _findTopPromoterId(List<EventOffer> offers) {
    EventOffer? topOffer;
    for (final offer in offers) {
      if (offer.promoterId == null) {
        continue;
      }
      if (topOffer == null ||
          (offer.promoterRating ?? 0) > (topOffer.promoterRating ?? 0)) {
        topOffer = offer;
      }
    }
    return topOffer?.promoterId;
  }

  Future<void> _openPromoterWhatsApp(
    BuildContext context,
    AppCopy copy, {
    required String phone,
    required String eventTitle,
    String? promoterName,
    String? offerTitle,
  }) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final message = copy.text(
      it: 'Ciao ${promoterName ?? 'PR'}, mi interessa ${offerTitle ?? 'la tua lista'} per $eventTitle su NightRadar.',
      en: 'Hi ${promoterName ?? 'promoter'}, I am interested in ${offerTitle ?? 'your list'} for $eventTitle on NightRadar.',
    );
    final encoded = Uri.encodeComponent(message);
    final appUri = Uri.parse('whatsapp://send?phone=$cleanPhone&text=$encoded');
    final webUri = Uri.parse('https://wa.me/$cleanPhone?text=$encoded');
    final openedApp = await launchUrl(
      appUri,
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

  Future<void> _openPromoterEmail(
    BuildContext context,
    AppCopy copy, {
    required String email,
    required String eventTitle,
    String? promoterName,
    String? offerTitle,
  }) async {
    final subject = copy.text(
      it: 'Richiesta NightRadar per $eventTitle',
      en: 'NightRadar request for $eventTitle',
    );
    final body = copy.text(
      it: 'Ciao ${promoterName ?? 'PR'}, mi interessa ${offerTitle ?? 'la tua proposta'} per $eventTitle. Possiamo sentirci?',
      en: 'Hi ${promoterName ?? 'promoter'}, I am interested in ${offerTitle ?? 'your offer'} for $eventTitle. Can we connect?',
    );
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {'subject': subject, 'body': body},
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

  Future<void> _togglePromoterReaction(
    BuildContext context,
    WidgetRef ref, {
    required String promoterId,
    required PromoterReactionType reactionType,
    required AppProfile? profile,
  }) async {
    final copy = context.copy;
    if (profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            copy.text(
              it: 'Accedi per lasciare cuore o pollice su al PR',
              en: 'Sign in to leave a heart or thumbs up to the promoter',
            ),
          ),
        ),
      );
      return;
    }

    try {
      await ref
          .read(nightRadarRepositoryProvider)
          .togglePromoterReaction(
            promoterId: promoterId,
            reactionType: reactionType,
          );
      ref.invalidate(eventDetailsProvider(eventId));
      ref.invalidate(promoterDashboardProvider);
      await ref.read(eventDetailsProvider(eventId).future);
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _toggleTrustedPromoter(
    BuildContext context,
    WidgetRef ref, {
    required String promoterId,
    required String promoterName,
    required bool isTrusted,
  }) async {
    final copy = context.copy;
    try {
      await ref
          .read(userDiscoveryPreferencesProvider.notifier)
          .toggleTrustedPromoter(
            promoterId: promoterId,
            promoterName: promoterName,
          );
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !isTrusted
                ? copy.text(
                    it: '$promoterName ora e tra i tuoi PR fidati',
                    en: '$promoterName is now one of your trusted promoters',
                  )
                : copy.text(
                    it: '$promoterName e stato rimosso dai PR fidati',
                    en: '$promoterName was removed from trusted promoters',
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

  Future<void> _toggleEventLike(
    BuildContext context,
    WidgetRef ref,
    EventSummary event,
    bool currentlyLiked,
  ) async {
    final copy = context.copy;
    final likePreferences = ref.read(eventLikePreferencesProvider);

    try {
      await ref
          .read(nightRadarRepositoryProvider)
          .toggleEventLike(
            eventId: event.id,
            viewerToken: likePreferences.viewerToken,
          );
      await ref
          .read(eventLikePreferencesProvider.notifier)
          .setLiked(event.id, !currentlyLiked);
      ref.invalidate(eventDetailsProvider(event.id));
      ref.invalidate(eventFeedProvider);
      await ref.read(eventDetailsProvider(event.id).future);

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

  Future<void> _openContactRequestDialog(
    BuildContext context,
    WidgetRef ref,
    EventDetails event,
    AppProfile? profile, {
    String? initialOfferId,
  }) async {
    final copy = context.copy;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: profile?.fullName ?? '');
    final emailController = TextEditingController(text: profile?.email ?? '');
    final phoneController = TextEditingController(text: profile?.phone ?? '');
    final messageController = TextEditingController();
    var selectedOfferId = initialOfferId;
    var partySize = 2;
    var replyPreference = ContactPreference.whatsapp;
    var isSending = false;
    String? errorText;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                copy.text(
                  it: 'Invia richiesta al PR',
                  en: 'Send request to the promoter',
                ),
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (event.offers.isNotEmpty) ...[
                        DropdownButtonFormField<String?>(
                          initialValue: selectedOfferId,
                          decoration: InputDecoration(
                            labelText: copy.text(
                              it: 'Offerta di interesse',
                              en: 'Offer of interest',
                            ),
                          ),
                          items: [
                            DropdownMenuItem<String?>(
                              value: null,
                              child: Text(
                                copy.text(
                                  it: 'Generica per evento',
                                  en: 'General event request',
                                ),
                              ),
                            ),
                            for (final offer in event.offers)
                              DropdownMenuItem<String?>(
                                value: offer.id,
                                child: Text(
                                  '${offer.title} · ${offer.promoterName ?? 'PR'}',
                                ),
                              ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedOfferId = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: copy.text(it: 'Nome', en: 'Name'),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().length < 2) {
                            return copy.text(
                              it: 'Inserisci il tuo nome',
                              en: 'Enter your name',
                            );
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: copy.text(it: 'Email', en: 'Email'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneController,
                        decoration: InputDecoration(
                          labelText: copy.text(
                            it: 'Telefono / WhatsApp',
                            en: 'Phone / WhatsApp',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        initialValue: partySize,
                        decoration: InputDecoration(
                          labelText: copy.text(
                            it: 'Numero persone',
                            en: 'Party size',
                          ),
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
                      const SizedBox(height: 12),
                      DropdownButtonFormField<ContactPreference>(
                        initialValue: replyPreference,
                        decoration: InputDecoration(
                          labelText: copy.text(
                            it: 'Preferenza risposta',
                            en: 'Reply preference',
                          ),
                        ),
                        items: ContactPreference.values
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(copy.contactPreferenceLabel(value)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            replyPreference = value ?? replyPreference;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: messageController,
                        decoration: InputDecoration(
                          labelText: copy.text(it: 'Messaggio', en: 'Message'),
                        ),
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.trim().length < 4) {
                            return copy.text(
                              it: 'Scrivi un messaggio breve',
                              en: 'Write a short message',
                            );
                          }
                          return null;
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
                  onPressed: isSending
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: Text(copy.text(it: 'Annulla', en: 'Cancel')),
                ),
                ElevatedButton(
                  onPressed: isSending
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }
                          if (!_hasReplyContact(
                            emailController.text,
                            phoneController.text,
                          )) {
                            setState(() {
                              errorText = copy.text(
                                it: 'Lascia almeno email o telefono',
                                en: 'Leave at least an email or phone number',
                              );
                            });
                            return;
                          }

                          setState(() {
                            isSending = true;
                            errorText = null;
                          });

                          try {
                            final warning = await ref
                                .read(nightRadarRepositoryProvider)
                                .createPromoterContactRequest(
                                  event: event,
                                  offerId: selectedOfferId,
                                  requesterName: nameController.text.trim(),
                                  requesterEmail: _nullIfBlank(
                                    emailController.text,
                                  ),
                                  requesterPhone: _nullIfBlank(
                                    phoneController.text,
                                  ),
                                  partySize: partySize,
                                  message: messageController.text.trim(),
                                  replyPreference: replyPreference,
                                );

                            if (!context.mounted) {
                              return;
                            }
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  warning == null
                                      ? copy.text(
                                          it: 'Richiesta inviata al PR e salvata nella sua inbox NightRadar.',
                                          en: 'Request sent to the promoter and saved in their NightRadar inbox.',
                                        )
                                      : copy.text(
                                          it: 'Richiesta salvata nella inbox del PR. La mail verra ritentata dal servizio.',
                                          en: 'Request saved in the promoter inbox. Email delivery will be retried by the service.',
                                        ),
                                ),
                              ),
                            );
                          } catch (error) {
                            if (!context.mounted) {
                              return;
                            }
                            setState(() {
                              errorText = error.toString();
                            });
                          } finally {
                            if (context.mounted) {
                              setState(() {
                                isSending = false;
                              });
                            }
                          }
                        },
                  child: Text(
                    isSending
                        ? copy.text(it: 'Invio...', en: 'Sending...')
                        : copy.text(it: 'Invia', en: 'Send'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  bool _hasReplyContact(String email, String phone) {
    return email.trim().isNotEmpty || phone.trim().isNotEmpty;
  }

  String? _nullIfBlank(String value) {
    return value.trim().isEmpty ? null : value.trim();
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.offer,
    required this.highlightPromoter,
    required this.onReserve,
    this.onWhatsApp,
    this.onEmail,
    this.onRequest,
    this.onInstagram,
    this.onTikTok,
    this.trustedPromoter = false,
    this.onToggleTrustedPromoter,
    this.onToggleThumbsUp,
    this.onToggleHeart,
    this.reactionsEnabled = true,
  });

  final EventOffer offer;
  final bool highlightPromoter;
  final VoidCallback? onReserve;
  final VoidCallback? onWhatsApp;
  final VoidCallback? onEmail;
  final VoidCallback? onRequest;
  final VoidCallback? onInstagram;
  final VoidCallback? onTikTok;
  final bool trustedPromoter;
  final VoidCallback? onToggleTrustedPromoter;
  final VoidCallback? onToggleThumbsUp;
  final VoidCallback? onToggleHeart;
  final bool reactionsEnabled;

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
                  child: Text(
                    offer.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Text(
                  offer.price == 0 ? 'FREE' : copy.priceAmount(offer.price),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (offer.promoterName != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: highlightPromoter
                      ? const Color(0xFFF9E4DB)
                      : const Color(0xFFF6F1EB),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: highlightPromoter
                        ? const Color(0xFFE85D3F)
                        : const Color(0xFFE4D8CB),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PromoterAvatar(
                          avatarUrl: offer.promoterAvatarUrl,
                          fallbackLabel: offer.promoterName!,
                        ),
                        const SizedBox(width: 12),
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
                                    'PR ${offer.promoterName}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  if (offer.promoterVerified)
                                    Chip(
                                      label: Text(
                                        copy.text(
                                          it: 'Verificato',
                                          en: 'Verified',
                                        ),
                                      ),
                                    ),
                                  if (highlightPromoter)
                                    Chip(
                                      label: Text(
                                        copy.text(
                                          it: 'Top PR',
                                          en: 'Top promoter',
                                        ),
                                      ),
                                    ),
                                  if (trustedPromoter)
                                    Chip(
                                      avatar: const Icon(
                                        Icons.star_rounded,
                                        size: 16,
                                      ),
                                      label: Text(
                                        copy.text(
                                          it: 'PR fidato',
                                          en: 'Trusted promoter',
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Rating ${(offer.promoterRating ?? 0).toStringAsFixed(1)}',
                              ),
                              if (offer.promoterBio?.trim().isNotEmpty == true)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(offer.promoterBio!),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _ReactionButton(
                          icon: Icons.thumb_up_alt_rounded,
                          label: copy.promoterReactionLabel(
                            PromoterReactionType.thumbsUp,
                          ),
                          count: offer.reactions.thumbsUpCount,
                          selected: offer.reactions.viewerThumbsUp,
                          enabled: reactionsEnabled && onToggleThumbsUp != null,
                          onTap: onToggleThumbsUp,
                        ),
                        _ReactionButton(
                          icon: Icons.favorite_rounded,
                          label: copy.promoterReactionLabel(
                            PromoterReactionType.heart,
                          ),
                          count: offer.reactions.heartCount,
                          selected: offer.reactions.viewerHeart,
                          enabled: reactionsEnabled && onToggleHeart != null,
                          onTap: onToggleHeart,
                        ),
                      ],
                    ),
                    if (onWhatsApp != null ||
                        onEmail != null ||
                        onRequest != null ||
                        onInstagram != null ||
                        onTikTok != null ||
                        onToggleTrustedPromoter != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (onToggleTrustedPromoter != null)
                              OutlinedButton.icon(
                                onPressed: onToggleTrustedPromoter,
                                icon: Icon(
                                  trustedPromoter
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                ),
                                label: Text(
                                  trustedPromoter
                                      ? copy.text(
                                          it: 'PR salvato',
                                          en: 'Promoter saved',
                                        )
                                      : copy.text(
                                          it: 'Salva PR',
                                          en: 'Save promoter',
                                        ),
                                ),
                              ),
                            if (onInstagram != null)
                              OutlinedButton.icon(
                                onPressed: onInstagram,
                                icon: const Icon(Icons.camera_alt_outlined),
                                label: const Text('Instagram'),
                              ),
                            if (onTikTok != null)
                              OutlinedButton.icon(
                                onPressed: onTikTok,
                                icon: const Icon(Icons.music_note_rounded),
                                label: const Text('TikTok'),
                              ),
                            if (onWhatsApp != null)
                              OutlinedButton.icon(
                                onPressed: onWhatsApp,
                                icon: const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                ),
                                label: const Text('WhatsApp'),
                              ),
                            if (onEmail != null)
                              OutlinedButton.icon(
                                onPressed: onEmail,
                                icon: const Icon(Icons.mail_outline_rounded),
                                label: Text(
                                  copy.text(it: 'Email', en: 'Email'),
                                ),
                              ),
                            if (onRequest != null)
                              OutlinedButton.icon(
                                onPressed: onRequest,
                                icon: const Icon(Icons.inbox_outlined),
                                label: Text(
                                  copy.text(
                                    it: 'Invia richiesta',
                                    en: 'Send request',
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
            if (offer.description != null) ...[
              const SizedBox(height: 10),
              Text(offer.description!),
            ],
            if (offer.conditions != null) ...[
              const SizedBox(height: 8),
              Text(offer.conditions!),
            ],
            if (offer.isTableOffer && offer.tableGuestCapacity != null) ...[
              const SizedBox(height: 8),
              Text(
                copy.text(
                  it: 'Capienza tavolo: fino a ${offer.tableGuestCapacity} persone',
                  en: 'Table size: up to ${offer.tableGuestCapacity} people',
                ),
              ),
            ],
            if (offer.showPublicAvailability && offer.spotsLeft != null) ...[
              const SizedBox(height: 8),
              Text(
                copy.text(
                  it: offer.isTableOffer
                      ? 'Tavoli residui: ${offer.spotsLeft}'
                      : 'Posti residui: ${offer.spotsLeft}',
                  en: offer.isTableOffer
                      ? 'Tables left: ${offer.spotsLeft}'
                      : 'Spots left: ${offer.spotsLeft}',
                ),
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (offer.showQrOnEntry)
                  Chip(
                    avatar: const Icon(Icons.qr_code_2_rounded, size: 18),
                    label: Text(
                      copy.text(it: 'QR all ingresso', en: 'QR at entry'),
                    ),
                  ),
                if (offer.showSecretCodeOnEntry)
                  Chip(
                    avatar: const Icon(Icons.password_rounded, size: 18),
                    label: Text(
                      copy.text(it: 'Codice segreto', en: 'Secret code'),
                    ),
                  ),
                if (offer.showListNameOnEntry)
                  Chip(
                    avatar: const Icon(Icons.badge_outlined, size: 18),
                    label: Text(
                      copy.text(
                        it: 'Nome lista o tavolo',
                        en: 'List or table name',
                      ),
                    ),
                  ),
                Chip(
                  avatar: const Icon(Icons.verified_user_outlined, size: 18),
                  label: Text(
                    copy.text(
                      it: 'Utente verificato o guest',
                      en: 'Verified user or guest',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: onReserve,
              child: Text(
                AppFlavorConfig.allowMutations
                    ? copy.text(
                        it: 'Prenota con questa offerta',
                        en: 'Reserve with this offer',
                      )
                    : copy.text(
                        it: 'Apri la versione attiva',
                        en: 'Open the live version',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReactionButton extends StatelessWidget {
  const _ReactionButton({
    required this.icon,
    required this.label,
    required this.count,
    required this.selected,
    required this.enabled,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final int count;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFFE85D3F) : const Color(0xFF18130F);

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: enabled ? onTap : null,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFCE6DF) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? const Color(0xFFE85D3F) : const Color(0xFFE4D8CB),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              '$count',
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _GeneralContactCard extends StatelessWidget {
  const _GeneralContactCard({
    required this.event,
    this.onWhatsApp,
    this.onEmail,
    this.onRequest,
    this.onInstagram,
    this.onTikTok,
    this.trustedPromoter = false,
    this.onToggleTrustedPromoter,
  });

  final EventDetails event;
  final VoidCallback? onWhatsApp;
  final VoidCallback? onEmail;
  final VoidCallback? onRequest;
  final VoidCallback? onInstagram;
  final VoidCallback? onTikTok;
  final bool trustedPromoter;
  final VoidCallback? onToggleTrustedPromoter;

  @override
  Widget build(BuildContext context) {
    final copy = context.copy;
    final contact = event.promoterContact;
    if (contact == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              copy.text(it: 'Contatto PR', en: 'Promoter contact'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              copy.text(
                it: 'Per questo evento puoi sentire ${contact.displayName ?? 'il PR'} via WhatsApp, email oppure inviare una richiesta strutturata dalla inbox NightRadar.',
                en: 'For this event you can reach ${contact.displayName ?? 'the promoter'} via WhatsApp, email, or send a structured request through the NightRadar inbox.',
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (onWhatsApp != null)
                  ElevatedButton.icon(
                    onPressed: onWhatsApp,
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                    label: const Text('WhatsApp'),
                  ),
                if (onToggleTrustedPromoter != null)
                  OutlinedButton.icon(
                    onPressed: onToggleTrustedPromoter,
                    icon: Icon(
                      trustedPromoter
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                    ),
                    label: Text(
                      trustedPromoter
                          ? copy.text(it: 'PR salvato', en: 'Promoter saved')
                          : copy.text(it: 'Salva PR', en: 'Save promoter'),
                    ),
                  ),
                if (onInstagram != null)
                  OutlinedButton.icon(
                    onPressed: onInstagram,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Instagram'),
                  ),
                if (onTikTok != null)
                  OutlinedButton.icon(
                    onPressed: onTikTok,
                    icon: const Icon(Icons.music_note_rounded),
                    label: const Text('TikTok'),
                  ),
                if (onEmail != null)
                  OutlinedButton.icon(
                    onPressed: onEmail,
                    icon: const Icon(Icons.mail_outline_rounded),
                    label: Text(copy.text(it: 'Email', en: 'Email')),
                  ),
                if (onRequest != null)
                  OutlinedButton.icon(
                    onPressed: onRequest,
                    icon: const Icon(Icons.inbox_outlined),
                    label: Text(
                      copy.text(it: 'Invia richiesta', en: 'Send request'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoterAvatar extends StatelessWidget {
  const _PromoterAvatar({required this.avatarUrl, required this.fallbackLabel});

  final String? avatarUrl;
  final String fallbackLabel;

  @override
  Widget build(BuildContext context) {
    if (avatarUrl?.trim().isNotEmpty == true) {
      return CircleAvatar(
        radius: 28,
        backgroundImage: NetworkImage(avatarUrl!),
      );
    }

    final initial = fallbackLabel.trim().isEmpty
        ? 'P'
        : fallbackLabel.trim().substring(0, 1).toUpperCase();

    return CircleAvatar(
      radius: 28,
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
