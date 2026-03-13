import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_copy.dart';
import '../app_flavor.dart';

class FlavorNoticeCard extends StatelessWidget {
  const FlavorNoticeCard({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (!AppFlavorConfig.isDemo) {
      return const SizedBox.shrink();
    }
    final copy = context.copy;

    return Container(
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF5E8DD),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE1CBB8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.visibility_outlined,
              color: Color(0xFFE85D3F),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  copy.text(it: 'Modalita demo', en: 'Demo mode'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  copy.text(
                    it:
                        'Questa e una demo read-only: puoi esplorare flussi e account demo, ma per creare eventi, liste e prenotazioni usa la versione attiva.',
                    en:
                        'This is a read-only demo: you can explore demo flows and accounts, but use the live version to create events, lists, and reservations.',
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _openActiveSite,
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: Text(
                    copy.text(
                      it: 'Apri la versione attiva',
                      en: 'Open the live version',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openActiveSite() async {
    await launchUrl(
      Uri.parse(AppFlavorConfig.alternativePublicAppUrl),
      webOnlyWindowName: '_blank',
    );
  }
}
