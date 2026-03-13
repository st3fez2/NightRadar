import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_copy.dart';
import '../../core/app_providers.dart';
import '../../core/widgets/brand_lockup.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/language_toggle.dart';
import '../../shared/legal_constants.dart';
import 'legal_documents.dart';
import 'legal_providers.dart';

class LegalConsentScreen extends ConsumerStatefulWidget {
  const LegalConsentScreen({
    super.key,
    this.fromPath,
    this.requireSignedInProfileAcceptance = false,
    this.signedInOverride,
  });

  final String? fromPath;
  final bool requireSignedInProfileAcceptance;
  final bool? signedInOverride;

  @override
  ConsumerState<LegalConsentScreen> createState() => _LegalConsentScreenState();
}

class _LegalConsentScreenState extends ConsumerState<LegalConsentScreen> {
  bool _disclaimerAccepted = false;
  bool _privacyAccepted = false;
  bool _isSubmitting = false;
  String? _errorText;

  bool get _canContinue => _disclaimerAccepted && _privacyAccepted;

  bool _isSignedIn() {
    final override = widget.signedInOverride;
    if (override != null) {
      return override;
    }

    return ref.read(supabaseClientProvider).auth.currentSession != null;
  }

  @override
  Widget build(BuildContext context) {
    final copy = context.copy;
    final signedIn = _isSignedIn();
    final title = signedIn
        ? copy.text(
            it: 'Prima di entrare nella tua area dobbiamo registrare il consenso legale.',
            en: 'Before entering your area we need to register the legal consent.',
          )
        : copy.text(
            it: 'Prima di entrare in NightRadar devi accettare disclaimer e privacy.',
            en: 'Before entering NightRadar you need to accept the disclaimer and privacy terms.',
          );
    final subtitle = signedIn
        ? copy.text(
            it: 'Salviamo il consenso sul dispositivo e sul profilo, cosi i flussi utente e PR restano allineati.',
            en: 'We save consent on both the device and the profile, so user and promoter flows stay aligned.',
          )
        : copy.text(
            it: 'La landing pubblica, l area utenti e gli strumenti PR si aprono solo dopo questa conferma.',
            en: 'The public landing, user area, and promoter tools open only after this confirmation.',
          );

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5EEE7), Color(0xFFE8E0D7)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ResponsivePage(
            maxWidth: 1040,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                const Align(
                  alignment: Alignment.centerRight,
                  child: LanguageToggle(),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF18130F),
                    borderRadius: BorderRadius.circular(34),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x2218130F),
                        blurRadius: 28,
                        offset: Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      NightRadarLockup(
                        label: 'NightRadar',
                        caption: copy.text(
                          it: 'Blocco disclaimer + privacy',
                          en: 'Disclaimer + privacy gate',
                        ),
                        textColor: Colors.white,
                        iconSize: 56,
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _LegalTag(
                            label: signedIn
                                ? copy.text(
                                    it: 'CONSENSO PROFILO',
                                    en: 'PROFILE CONSENT',
                                  )
                                : copy.text(
                                    it: 'INGRESSO PROTETTO',
                                    en: 'PROTECTED ENTRY',
                                  ),
                          ),
                          _LegalTag(
                            label: legalVersionLabel(copy).toUpperCase(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(color: Colors.white, height: 1.05),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.84),
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _SummaryStrip(
                  icon: Icons.gpp_good_rounded,
                  title: copy.text(it: 'Perche lo chiediamo', en: 'Why we ask'),
                  description: copy.text(
                    it: 'NightRadar gestisce liste, accessi, contatti, richieste ai PR ed export verso i locali. Prima di usare il servizio, chiarisce limiti del prodotto e uso dei dati.',
                    en: 'NightRadar handles lists, entry flows, contacts, promoter requests, and exports to venues. Before you use the service, it clarifies product limits and data usage.',
                  ),
                ),
                const SizedBox(height: 18),
                _DocumentCard(
                  icon: Icons.shield_outlined,
                  title: copy.text(
                    it: 'Disclaimer operativo',
                    en: 'Operational disclaimer',
                  ),
                  summary: nightRadarDisclaimerSummary(copy),
                  sections: nightRadarDisclaimerSections(copy),
                ),
                const SizedBox(height: 16),
                _DocumentCard(
                  icon: Icons.privacy_tip_outlined,
                  title: copy.text(
                    it: 'Informativa privacy sintetica',
                    en: 'Privacy summary',
                  ),
                  summary: nightRadarPrivacySummary(copy),
                  sections: nightRadarPrivacySections(copy),
                ),
                const SizedBox(height: 18),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          copy.text(
                            it: 'Conferma richiesta',
                            en: 'Confirmation required',
                          ),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          copy.text(
                            it: 'Il consenso viene registrato per la versione legale corrente: ${legalVersionLabel(copy)}.',
                            en: 'Consent is recorded for the current legal version: ${legalVersionLabel(copy)}.',
                          ),
                        ),
                        const SizedBox(height: 16),
                        CheckboxListTile(
                          value: _disclaimerAccepted,
                          onChanged: (value) {
                            setState(() {
                              _disclaimerAccepted = value ?? false;
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            copy.text(
                              it: 'Accetto il disclaimer operativo e confermo di usare NightRadar in modo lecito e responsabile.',
                              en: 'I accept the operational disclaimer and confirm that I use NightRadar lawfully and responsibly.',
                            ),
                          ),
                        ),
                        CheckboxListTile(
                          value: _privacyAccepted,
                          onChanged: (value) {
                            setState(() {
                              _privacyAccepted = value ?? false;
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            copy.text(
                              it: 'Ho letto l informativa privacy e compreso come NightRadar tratta i dati necessari a login, prenotazioni, richieste ai PR, liste, QR e preferenze locali.',
                              en: 'I have read the privacy notice and understood how NightRadar processes the data needed for login, reservations, promoter requests, lists, QR passes, and local preferences.',
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          copy.text(
                            it: 'Contatto privacy operativo: $nightRadarPrivacyContactEmail',
                            en: 'Operational privacy contact: $nightRadarPrivacyContactEmail',
                          ),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (_errorText != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            _errorText!,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        ResponsiveActionRow(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _isSubmitting || !_canContinue
                                  ? null
                                  : _acceptAndContinue,
                              icon: const Icon(Icons.check_circle_outline),
                              label: Text(
                                _isSubmitting
                                    ? copy.text(
                                        it: 'Salvataggio...',
                                        en: 'Saving...',
                                      )
                                    : copy.text(
                                        it: 'Accetta e continua',
                                        en: 'Accept and continue',
                                      ),
                              ),
                            ),
                            if (signedIn)
                              OutlinedButton.icon(
                                onPressed: _isSubmitting ? null : _signOut,
                                icon: const Icon(Icons.logout_rounded),
                                label: Text(
                                  copy.text(it: 'Esci', en: 'Sign out'),
                                ),
                              )
                            else
                              OutlinedButton.icon(
                                onPressed: _isSubmitting
                                    ? null
                                    : () => context.go('/auth'),
                                icon: const Icon(Icons.login_rounded),
                                label: Text(
                                  copy.text(
                                    it: 'Vai all accesso',
                                    en: 'Go to sign-in',
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _acceptAndContinue() async {
    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    final repository = ref.read(nightRadarRepositoryProvider);
    final signedIn = _isSignedIn();

    try {
      await ref.read(localLegalConsentProvider.notifier).acceptCurrentVersion();

      if (signedIn || widget.requireSignedInProfileAcceptance) {
        await repository.acceptLegalPolicies(
          acceptedAt: DateTime.now().toUtc(),
          version: nightRadarLegalVersion,
        );
        ref.invalidate(currentProfileProvider);
      }

      if (!mounted) {
        return;
      }

      final target = _resolveTarget(signedIn: signedIn);
      context.go(target);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorText = _humanizeError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    await ref.read(nightRadarRepositoryProvider).signOut();
    if (!mounted) {
      return;
    }
    context.go('/');
  }

  String _resolveTarget({required bool signedIn}) {
    final fromPath = widget.fromPath;
    if (fromPath != null &&
        fromPath.isNotEmpty &&
        fromPath != '/legal' &&
        fromPath != '/auth') {
      return fromPath;
    }

    return signedIn ? '/app' : '/';
  }

  String _humanizeError(Object error) {
    final raw = error.toString();
    if (raw.contains('AuthException')) {
      return raw
          .replaceFirst('AuthException(message: ', '')
          .replaceAll(')', '');
    }
    return context.copy.text(
      it: 'Non sono riuscito a salvare il consenso. Riprova tra un attimo.',
      en: 'I could not save the consent. Try again in a moment.',
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.icon,
    required this.title,
    required this.summary,
    required this.sections,
  });

  final IconData icon;
  final String title;
  final String summary;
  final List<LegalSection> sections;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4E6DB),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: const Color(0xFFE85D3F)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(summary),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            for (final section in sections) ...[
              Text(
                section.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              for (final point in section.points) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 7),
                      child: Icon(
                        Icons.circle,
                        size: 8,
                        color: Color(0xFF186B5B),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(point)),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              if (section != sections.last) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _LegalTag extends StatelessWidget {
  const _LegalTag({required this.label});

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

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EBE3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE0D2C4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF186B5B)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(description),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
