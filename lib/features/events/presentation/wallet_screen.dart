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
              (reservation.status == 'approved' ||
                  reservation.status == 'checked_in') &&
              reservation.canShowQrAtEntry;
          final showSecretCode =
              (reservation.status == 'approved' ||
                  reservation.status == 'checked_in') &&
              reservation.canShowSecretCodeAtEntry;
          final showAssignedListName =
              (reservation.status == 'approved' ||
                  reservation.status == 'checked_in') &&
              reservation.canShowAssignedListNameAtEntry;

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
                              : showSecretCode
                              ? copy.text(
                                  it: 'Mostra questo codice all ingresso',
                                  en: 'Show this code at the entrance',
                                )
                              : showAssignedListName
                              ? copy.text(
                                  it: 'Mostra il nome lista assegnato all ingresso',
                                  en: 'Show the assigned list name at the entrance',
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
                        if (showSecretCode) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F1EA),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFE0D2C4),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  copy.text(
                                    it: 'Codice segreto',
                                    en: 'Secret code',
                                  ),
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  reservation.entrySecretCode ?? '',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (showAssignedListName) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F1EA),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFE0D2C4),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  copy.text(
                                    it: 'Nome lista o tavolo',
                                    en: 'List or table name',
                                  ),
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  reservation.listName ?? '',
                                  style: Theme.of(context).textTheme.titleLarge,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        Text(
                          copy.longDateTime(reservation.startsAt),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          copy.text(
                            it: 'Referente: ${reservation.guestName}  ·  Persone: ${reservation.partySize}',
                            en: 'Lead guest: ${reservation.guestName}  ·  People: ${reservation.partySize}',
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
                        const SizedBox(height: 8),
                        Text(
                          copy.guestAccessLabel(reservation.guestAccessType),
                        ),
                        if (reservation.guestEmail?.trim().isNotEmpty ==
                            true) ...[
                          const SizedBox(height: 8),
                          Text(
                            copy.text(
                              it: 'Ricevuta: ${reservation.guestEmail}',
                              en: 'Receipt: ${reservation.guestEmail}',
                            ),
                            textAlign: TextAlign.center,
                          ),
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
        error: (error, stackTrace) => ScreenStatusView(
          title: copy.text(
            it: 'Wallet non disponibile',
            en: 'Wallet unavailable',
          ),
          message: error.toString(),
        ),
        loading: () => ScreenStatusView(
          title: copy.text(
            it: 'Sto aprendo il wallet',
            en: 'Opening your wallet',
          ),
          message: copy.text(
            it: 'Recupero QR, codici e dettagli della prenotazione.',
            en: 'Loading QR, access codes, and reservation details.',
          ),
          loading: true,
        ),
      ),
    );
  }
}
