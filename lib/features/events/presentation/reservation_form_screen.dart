import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_providers.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../shared/models.dart';

class ReservationFormScreen extends ConsumerStatefulWidget {
  const ReservationFormScreen({
    super.key,
    required this.eventId,
    this.offerId,
  });

  final String eventId;
  final String? offerId;

  @override
  ConsumerState<ReservationFormScreen> createState() =>
      _ReservationFormScreenState();
}

class _ReservationFormScreenState
    extends ConsumerState<ReservationFormScreen> {
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
    final eventAsync = ref.watch(eventDetailsProvider(widget.eventId));
    final profile = ref.watch(currentProfileProvider).valueOrNull;

    if (_guestNameController.text.isEmpty && profile != null) {
      _guestNameController.text = profile.fullName;
      _phoneController.text = profile.email ?? '';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conferma prenotazione'),
      ),
      body: eventAsync.when(
        data: (event) {
          final selectedOffer = _resolveOffer(event);

          return ResponsivePage(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
              NightRadarHero(
                title: event.summary.title,
                subtitle: selectedOffer == null
                    ? 'Richiesta accesso generico'
                    : 'Offerta selezionata: ${selectedOffer.title}',
                trailing: RadarChip(label: event.summary.radarLabel),
              ),
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
                                ? 'Ingresso free'
                                : 'EUR ${selectedOffer.price.toStringAsFixed(0)}',
                          ),
                          const SizedBox(height: 12),
                        ],
                        TextFormField(
                          controller: _guestNameController,
                          decoration: const InputDecoration(
                            labelText: 'Nome referente',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().length < 2) {
                              return 'Inserisci il nome del referente';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Telefono o email',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Inserisci un contatto';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          initialValue: _partySize,
                          decoration: const InputDecoration(
                            labelText: 'Numero persone',
                          ),
                          items: List.generate(
                            10,
                            (index) => DropdownMenuItem(
                              value: index + 1,
                              child: Text('${index + 1} persone'),
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
                          decoration: const InputDecoration(
                            labelText: 'Note',
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton(
                          onPressed: _isSubmitting
                              ? null
                              : () => _submit(context, event, selectedOffer),
                          child: Text(
                            _isSubmitting
                                ? 'Invio in corso...'
                                : 'Genera prenotazione e QR',
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
            title: 'Prenotazione non disponibile',
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
      final reservation = await ref.read(nightRadarRepositoryProvider).createReservation(
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
