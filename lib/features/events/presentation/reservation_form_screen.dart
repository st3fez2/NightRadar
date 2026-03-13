import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_copy.dart';
import '../../../core/app_flavor.dart';
import '../../../core/app_providers.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/flavor_notice_card.dart';
import '../../../core/widgets/language_toggle.dart';
import '../../../shared/legal_constants.dart';
import '../../../shared/models.dart';

class ReservationFormScreen extends ConsumerStatefulWidget {
  const ReservationFormScreen({super.key, required this.eventId, this.offerId});

  final String eventId;
  final String? offerId;

  @override
  ConsumerState<ReservationFormScreen> createState() =>
      _ReservationFormScreenState();
}

class _ReservationFormScreenState extends ConsumerState<ReservationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _guestNameController = TextEditingController();
  final _guestLastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _listNameController = TextEditingController();
  final _notesController = TextEditingController();

  int _partySize = 2;
  bool _isSubmitting = false;
  bool _anonymousEntry = false;

  @override
  void dispose() {
    _guestNameController.dispose();
    _guestLastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _listNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final copy = context.copy;
    final eventAsync = ref.watch(eventDetailsProvider(widget.eventId));
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final authUser = ref.watch(supabaseClientProvider).auth.currentUser;
    final isVerifiedSession = authUser != null && !authUser.isAnonymous;
    final isAnonymousSession = authUser?.isAnonymous == true;

    if (_guestNameController.text.isEmpty &&
        profile != null &&
        isVerifiedSession) {
      _guestNameController.text = profile.fullName;
      _emailController.text = profile.email ?? '';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          copy.text(it: 'Conferma prenotazione', en: 'Confirm reservation'),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: Center(child: LanguageToggle(compact: true)),
          ),
        ],
      ),
      body: eventAsync.when(
        data: (event) {
          final selectedOffer = _resolveOffer(event);
          final maxPartySize = _maxPartySize(selectedOffer);
          final requiresPhone =
              selectedOffer?.phoneRequirement != PhoneRequirement.none;
          final needsReceiptEmail = !isVerifiedSession;
          final canChooseAnonymousEntry =
              selectedOffer?.allowAnonymousEntry ?? false;
          final needsListName = selectedOffer?.requiresListName ?? false;
          final anonymousEntryActive =
              canChooseAnonymousEntry && _anonymousEntry;
          final offerUnavailable =
              selectedOffer != null &&
              selectedOffer.spotsLeft != null &&
              selectedOffer.spotsLeft! <= 0;
          if (_partySize > maxPartySize) {
            _partySize = maxPartySize;
          }

          return ResponsivePage(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                NightRadarHero(
                  title: event.summary.title,
                  subtitle: selectedOffer == null
                      ? copy.text(
                          it: 'Richiesta accesso generico',
                          en: 'General access request',
                        )
                      : copy.text(
                          it: 'Offerta selezionata: ${selectedOffer.title}',
                          en: 'Selected offer: ${selectedOffer.title}',
                        ),
                  trailing: RadarChip(label: event.summary.radarLabel),
                ),
                if (AppFlavorConfig.isDemo) ...[
                  const SizedBox(height: 12),
                  const FlavorNoticeCard(compact: true),
                ],
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (selectedOffer != null) ...[
                            Text(
                              selectedOffer.title,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              selectedOffer.price == 0
                                  ? copy.freeEntryLabel()
                                  : copy.priceAmount(selectedOffer.price),
                            ),
                            if (selectedOffer.isTableOffer &&
                                selectedOffer.tableGuestCapacity != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                copy.text(
                                  it: 'Tavolo per massimo ${selectedOffer.tableGuestCapacity} persone',
                                  en: 'Table for up to ${selectedOffer.tableGuestCapacity} people',
                                ),
                              ),
                            ],
                            if (selectedOffer.showPublicAvailability &&
                                selectedOffer.spotsLeft != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                copy.text(
                                  it: selectedOffer.isTableOffer
                                      ? 'Tavoli residui visibili: ${selectedOffer.spotsLeft}'
                                      : 'Posti residui visibili: ${selectedOffer.spotsLeft}',
                                  en: selectedOffer.isTableOffer
                                      ? 'Visible tables left: ${selectedOffer.spotsLeft}'
                                      : 'Visible spots left: ${selectedOffer.spotsLeft}',
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                          ],
                          if (!isVerifiedSession) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7F1EA),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: const Color(0xFFE0D2C4),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isAnonymousSession
                                        ? copy.text(
                                            it: 'Stai prenotando come guest anonimo',
                                            en: 'You are reserving as an anonymous guest',
                                          )
                                        : copy.text(
                                            it: 'Vuoi apparire come utente verificato?',
                                            en: 'Want to appear as a verified user?',
                                          ),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    isAnonymousSession
                                        ? copy.text(
                                            it: 'Il PR vedra un guest anonimo con email ricevuta, non un account verificato.',
                                            en: 'The promoter will see an anonymous guest with a receipt email, not a verified account.',
                                          )
                                        : copy.text(
                                            it: 'Puoi accedere prima e risultare piu affidabile per il PR, oppure continuare subito come guest con email ricevuta.',
                                            en: 'You can sign in first and look more reliable to the promoter, or continue now as a guest with an email receipt.',
                                          ),
                                  ),
                                  if (!isAnonymousSession) ...[
                                    const SizedBox(height: 12),
                                    OutlinedButton.icon(
                                      onPressed: () => context.push(
                                        '/auth?from=${Uri.encodeComponent(_authFromPath())}',
                                      ),
                                      icon: const Icon(
                                        Icons.verified_user_outlined,
                                      ),
                                      label: Text(
                                        copy.text(
                                          it: 'Accedi come utente verificato',
                                          en: 'Sign in as verified user',
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ] else ...[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Chip(
                                avatar: const Icon(
                                  Icons.verified_rounded,
                                  size: 18,
                                ),
                                label: Text(
                                  copy.text(
                                    it: 'Prenotazione come utente verificato',
                                    en: 'Booking as verified user',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (canChooseAnonymousEntry) ...[
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              value: anonymousEntryActive,
                              onChanged: (value) {
                                setState(() {
                                  _anonymousEntry = value;
                                });
                              },
                              title: Text(
                                copy.text(
                                  it: 'Mostra una voce anonima al PR',
                                  en: 'Show an anonymous entry to the promoter',
                                ),
                              ),
                              subtitle: Text(
                                copy.text(
                                  it: 'Utile se vuoi comparire solo con il nome lista o tavolo.',
                                  en: 'Useful if you want to appear only with the list or table name.',
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          TextFormField(
                            controller: _guestNameController,
                            decoration: InputDecoration(
                              labelText: copy.text(
                                it: anonymousEntryActive
                                    ? 'Nome referente interno'
                                    : 'Nome referente',
                                en: anonymousEntryActive
                                    ? 'Internal lead name'
                                    : 'Lead guest name',
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().length < 2) {
                                return copy.text(
                                  it: 'Inserisci il nome del referente',
                                  en: 'Enter the lead guest name',
                                );
                              }
                              return null;
                            },
                          ),
                          if (selectedOffer?.collectLastName == true &&
                              !anonymousEntryActive) ...[
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _guestLastNameController,
                              decoration: InputDecoration(
                                labelText: copy.text(
                                  it: 'Cognome referente',
                                  en: 'Lead guest last name',
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().length < 2) {
                                  return copy.text(
                                    it: 'Inserisci anche il cognome',
                                    en: 'Enter the last name too',
                                  );
                                }
                                return null;
                              },
                            ),
                          ],
                          const SizedBox(height: 12),
                          if (requiresPhone) ...[
                            TextFormField(
                              controller: _phoneController,
                              decoration: InputDecoration(
                                labelText: copy.text(
                                  it: 'Telefono referente',
                                  en: 'Lead guest phone',
                                ),
                              ),
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return copy.text(
                                    it: 'Inserisci il telefono del referente',
                                    en: 'Enter the lead guest phone',
                                  );
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (needsReceiptEmail) ...[
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: copy.text(
                                  it: 'Email per ricevuta',
                                  en: 'Receipt email',
                                ),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                final trimmed = value?.trim() ?? '';
                                if (trimmed.isEmpty ||
                                    !_isLikelyEmail(trimmed)) {
                                  return copy.text(
                                    it: 'Inserisci una email valida per la ricevuta',
                                    en: 'Enter a valid receipt email',
                                  );
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (needsListName ||
                              selectedOffer?.showListNameOnEntry == true) ...[
                            TextFormField(
                              controller: _listNameController,
                              decoration: InputDecoration(
                                labelText: copy.text(
                                  it: 'Nome lista o tavolo',
                                  en: 'List or table name',
                                ),
                              ),
                              validator: (value) {
                                if (!needsListName) {
                                  return null;
                                }
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
                          DropdownButtonFormField<int>(
                            key: ValueKey(
                              '${selectedOffer?.id ?? 'generic'}-$maxPartySize',
                            ),
                            initialValue: _partySize,
                            decoration: InputDecoration(
                              labelText: copy.text(
                                it: 'Numero persone',
                                en: 'Party size',
                              ),
                            ),
                            items: List.generate(
                              maxPartySize,
                              (index) => DropdownMenuItem(
                                value: index + 1,
                                child: Text(copy.peopleCount(index + 1)),
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _partySize = value ?? 1;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _notesController,
                            decoration: InputDecoration(
                              labelText: copy.text(it: 'Note', en: 'Notes'),
                            ),
                            maxLines: 3,
                          ),
                          if (offerUnavailable) ...[
                            const SizedBox(height: 12),
                            Text(
                              copy.text(
                                it: selectedOffer.isTableOffer
                                    ? 'Questa offerta tavolo risulta esaurita adesso.'
                                    : 'Questa offerta risulta esaurita adesso.',
                                en: selectedOffer.isTableOffer
                                    ? 'This table offer is currently sold out.'
                                    : 'This offer is currently sold out.',
                              ),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          ElevatedButton(
                            onPressed:
                                !AppFlavorConfig.allowMutations ||
                                    _isSubmitting ||
                                    offerUnavailable
                                ? null
                                : () => _submit(
                                    context,
                                    event,
                                    selectedOffer,
                                    isVerifiedSession: isVerifiedSession,
                                    isAnonymousSession: isAnonymousSession,
                                  ),
                            child: Text(
                              !AppFlavorConfig.allowMutations
                                  ? copy.text(
                                      it: 'Disponibile solo nella versione attiva',
                                      en: 'Available only in the live version',
                                    )
                                  : (_isSubmitting
                                        ? copy.text(
                                            it: 'Invio in corso...',
                                            en: 'Submitting...',
                                          )
                                        : copy.text(
                                            it: isVerifiedSession
                                                ? 'Genera prenotazione'
                                                : 'Continua come guest e prenota',
                                            en: isVerifiedSession
                                                ? 'Create reservation'
                                                : 'Continue as guest and reserve',
                                          )),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        error: (error, stackTrace) => Center(
          child: EmptyStateCard(
            title: copy.text(
              it: 'Prenotazione non disponibile',
              en: 'Reservation unavailable',
            ),
            message: error.toString(),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  EventOffer? _resolveOffer(EventDetails event) {
    if (widget.offerId == null) {
      return null;
    }

    for (final offer in event.offers) {
      if (offer.id == widget.offerId) {
        return offer;
      }
    }

    return null;
  }

  int _maxPartySize(EventOffer? offer) {
    if (offer == null) {
      return 10;
    }
    if (offer.isTableOffer && offer.tableGuestCapacity != null) {
      return offer.tableGuestCapacity!.clamp(1, 30);
    }
    if (offer.spotsLeft != null) {
      return offer.spotsLeft!.clamp(1, 30);
    }
    return 10;
  }

  String _authFromPath() {
    final base = '/event/${widget.eventId}/reserve';
    if (widget.offerId == null || widget.offerId!.isEmpty) {
      return base;
    }
    return '$base?offerId=${Uri.encodeQueryComponent(widget.offerId!)}';
  }

  bool _isLikelyEmail(String value) {
    return value.contains('@') && value.contains('.');
  }

  Future<void> _submit(
    BuildContext context,
    EventDetails event,
    EventOffer? offer, {
    required bool isVerifiedSession,
    required bool isAnonymousSession,
  }) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final repository = ref.read(nightRadarRepositoryProvider);
      if (!isVerifiedSession && !isAnonymousSession) {
        await repository.signInAnonymously();
        ref.invalidate(currentProfileProvider);
      }

      var profile = await repository.getCurrentProfile();
      for (var attempt = 0; attempt < 4 && profile == null; attempt++) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
        profile = await repository.getCurrentProfile();
      }

      if (profile != null &&
          !profile.hasAcceptedLegalVersion(nightRadarLegalVersion)) {
        await repository.acceptLegalPolicies(
          acceptedAt: DateTime.now(),
          version: nightRadarLegalVersion,
        );
        ref.invalidate(currentProfileProvider);
      }

      final reservation = await ref
          .read(nightRadarRepositoryProvider)
          .createReservation(
            event: event,
            offer: offer,
            guestName: _guestNameController.text.trim(),
            guestLastName: _guestLastNameController.text.trim().isEmpty
                ? null
                : _guestLastNameController.text.trim(),
            phone: _phoneController.text.trim(),
            receiptEmail: _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
            partySize: _partySize,
            listName: _listNameController.text.trim().isEmpty
                ? null
                : _listNameController.text.trim(),
            isAnonymousEntry: _anonymousEntry,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          );

      ref.invalidate(myReservationsProvider);
      ref.invalidate(reservationProvider(reservation.id));

      if (!context.mounted) {
        return;
      }

      context.go('/wallet/${reservation.id}');
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
