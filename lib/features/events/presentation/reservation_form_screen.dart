import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_copy.dart';
import '../../../core/app_flavor.dart';
import '../../../core/app_providers.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/flavor_notice_card.dart';
import '../../../core/widgets/language_toggle.dart';
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
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  int _partySize = 2;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _guestNameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final copy = context.copy;
    final eventAsync = ref.watch(eventDetailsProvider(widget.eventId));
    final profile = ref.watch(currentProfileProvider).valueOrNull;

    if (_guestNameController.text.isEmpty && profile != null) {
      _guestNameController.text = profile.fullName;
      _phoneController.text = profile.email ?? '';
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
                          TextFormField(
                            controller: _guestNameController,
                            decoration: InputDecoration(
                              labelText: copy.text(
                                it: 'Nome referente',
                                en: 'Lead guest name',
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
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _phoneController,
                            decoration: InputDecoration(
                              labelText: copy.text(
                                it: 'Telefono o email',
                                en: 'Phone or email',
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return copy.text(
                                  it: 'Inserisci un contatto',
                                  en: 'Enter a contact',
                                );
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
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
                                : () => _submit(context, event, selectedOffer),
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
                                            it: 'Genera prenotazione e QR',
                                            en: 'Generate reservation and QR',
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

  Future<void> _submit(
    BuildContext context,
    EventDetails event,
    EventOffer? offer,
  ) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final reservation = await ref
          .read(nightRadarRepositoryProvider)
          .createReservation(
            event: event,
            offer: offer,
            guestName: _guestNameController.text.trim(),
            phone: _phoneController.text.trim(),
            partySize: _partySize,
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
