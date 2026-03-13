import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/app_providers.dart';
import '../../../core/app_copy.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/language_toggle.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key, required this.reservationId});

  final String reservationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copy = context.copy;
    final reservationAsync = ref.watch(reservationProvider(reservationId));

    return Scaffold(
      appBar: AppBar(
        title: Text(copy.text(it: 'Wallet', en: 'Wallet')),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: Center(child: LanguageToggle(compact: true)),
          ),
        ],
      ),
      body: reservationAsync.when(
        data: (reservation) {
          final showQr =
              reservation.status == 'approved' ||
              reservation.status == 'checked_in';

          return ResponsivePage(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                NightRadarHero(
                  title: reservation.eventTitle,
                  subtitle:
                      '${reservation.venueName}  ${reservation.city ?? ''}',
                  trailing: RadarChip(label: reservation.status),
                ),
                const SizedBox(height: 18),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          showQr
                              ? copy.text(
                                  it: 'Mostra questo QR all ingresso',
                                  en: 'Show this QR at the entrance',
                                )
                              : copy.text(
                                  it: 'Prenotazione in attesa',
                                  en: 'Reservation pending',
                                ),
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        if (showQr && reservation.qrToken != null)
                          QrImageView(
                            data: reservation.qrToken!,
                            size: MediaQuery.sizeOf(context).width < 420
                                ? 190
                                : 220,
                            backgroundColor: Colors.white,
                          )
                        else
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 30),
                            child: Icon(Icons.hourglass_top_rounded, size: 64),
                          ),
                        const SizedBox(height: 14),
                        Text(
                          copy.longDateTime(reservation.startsAt),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          copy.text(
                            it:
                                'Referente: ${reservation.guestName}  ·  Persone: ${reservation.partySize}',
                            en:
                                'Lead guest: ${reservation.guestName}  ·  People: ${reservation.partySize}',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (reservation.offerTitle != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            copy.text(
                              it: 'Offerta: ${reservation.offerTitle}',
                              en: 'Offer: ${reservation.offerTitle}',
                            ),
                          ),
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
                  onPressed: () => context.go('/app'),
                  child: Text(
                    copy.text(it: 'Torna alla home', en: 'Back to home'),
                  ),
                ),
              ],
            ),
          );
        },
        error: (error, stackTrace) => Center(
          child: EmptyStateCard(
            title: copy.text(it: 'Wallet non disponibile', en: 'Wallet unavailable'),
            message: error.toString(),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
