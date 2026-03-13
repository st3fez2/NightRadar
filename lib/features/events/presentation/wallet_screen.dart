import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/app_providers.dart';
import '../../../core/widgets/common_widgets.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({
    super.key,
    required this.reservationId,
  });

  final String reservationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservationAsync = ref.watch(reservationProvider(reservationId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet'),
      ),
      body: reservationAsync.when(
        data: (reservation) {
          final showQr = reservation.status == 'approved' ||
              reservation.status == 'checked_in';

          return ResponsivePage(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
              NightRadarHero(
                title: reservation.eventTitle,
                subtitle: '${reservation.venueName}  ${reservation.city ?? ''}',
                trailing: RadarChip(label: reservation.status),
              ),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        showQr ? 'Mostra questo QR all ingresso' : 'Prenotazione in attesa',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      if (showQr && reservation.qrToken != null)
                        QrImageView(
                          data: reservation.qrToken!,
                          size: MediaQuery.sizeOf(context).width < 420 ? 190 : 220,
                          backgroundColor: Colors.white,
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 30),
                          child: Icon(Icons.hourglass_top_rounded, size: 64),
                        ),
                      const SizedBox(height: 14),
                      Text(
                        DateFormat('EEEE d MMMM, HH:mm', 'it_IT')
                            .format(reservation.startsAt),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Referente: ${reservation.guestName}  ·  Persone: ${reservation.partySize}',
                        textAlign: TextAlign.center,
                      ),
                      if (reservation.offerTitle != null) ...[
                        const SizedBox(height: 8),
                        Text('Offerta: ${reservation.offerTitle}'),
                      ],
                      if (reservation.promoterName != null) ...[
                        const SizedBox(height: 8),
                        Text('PR: ${reservation.promoterName}'),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('Torna alla home'),
              ),
              ],
            ),
          );
        },
        error: (error, stackTrace) => Center(
          child: EmptyStateCard(
            title: 'Wallet non disponibile',
            message: error.toString(),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
