import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_copy.dart';
import '../../core/app_flavor.dart';
import '../../core/app_providers.dart';
import '../../core/widgets/brand_lockup.dart';
import '../../core/widgets/flavor_notice_card.dart';
import '../../core/widgets/language_toggle.dart';
import '../../core/widgets/public_link_card.dart';

enum _AuthPane {
  userSignIn,
  userSignUp,
  emailPending,
  promoterAccess,
  promoterRequest,
  promoterRequestSent,
}

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _authFormKey = GlobalKey<FormState>();
  final _promoterRequestFormKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _requestCityController = TextEditingController();
  final _requestPhoneController = TextEditingController();
  final _requestInstagramController = TextEditingController();
  final _requestNoteController = TextEditingController();

  _AuthPane _pane = _AuthPane.userSignIn;
  bool _isSubmitting = false;
  bool _isResendingEmail = false;
  String? _errorText;
  String? _pendingEmail;

  bool get _isUserSignUp => _pane == _AuthPane.userSignUp;
  bool get _isPromoterPane =>
      _pane == _AuthPane.promoterAccess ||
      _pane == _AuthPane.promoterRequest ||
      _pane == _AuthPane.promoterRequestSent;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _requestCityController.dispose();
    _requestPhoneController.dispose();
    _requestInstagramController.dispose();
    _requestNoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final copy = context.copy;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Align(
                  alignment: Alignment.centerRight,
                  child: LanguageToggle(),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE85D3F), Color(0xFF18130F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: NightRadarLockup(
                              label: 'NightRadar',
                              caption: copy.text(
                                it: 'Radar nightlife moderno',
                                en: 'Modern nightlife radar',
                              ),
                              textColor: Colors.white,
                              iconSize: 52,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _heroBadgeLabel(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        _heroTitle(),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _heroSubtitle(),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.84),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                PublicLinkCard(
                  title: copy.text(
                    it: 'QR pubblico sempre disponibile',
                    en: 'Public QR always available',
                  ),
                  subtitle: copy.text(
                    it: 'Dalla landing puoi condividere il progetto, aprire il sito live o scaricare il QR senza autenticarti.',
                    en: 'From the landing page you can share the project, open the live site, or download the QR without signing in.',
                  ),
                ),
                if (AppFlavorConfig.isDemo) ...[
                  const SizedBox(height: 12),
                  const FlavorNoticeCard(compact: true),
                ],
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3EBE3),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE0D2C4)),
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
                          Icons.gpp_good_rounded,
                          color: Color(0xFF186B5B),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              copy.text(
                                it: 'Disclaimer e privacy obbligatori all ingresso',
                                en: 'Disclaimer and privacy required at entry',
                              ),
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              copy.text(
                                it: 'Prima di usare NightRadar chiediamo un consenso iniziale dedicato, cosi i flussi utenti e PR restano coperti anche lato web mobile.',
                                en: 'Before using NightRadar we ask for a dedicated initial consent, so user and promoter flows stay covered on mobile web too.',
                              ),
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () =>
                                  context.push('/legal?from=/auth'),
                              icon: const Icon(Icons.open_in_new_rounded),
                              label: Text(
                                copy.text(
                                  it: 'Apri disclaimer e privacy',
                                  en: 'Open disclaimer and privacy',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildAudienceSelector(context),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: switch (_pane) {
                      _AuthPane.promoterAccess => _buildPromoterAccessCard(
                        context,
                      ),
                      _AuthPane.emailPending => _buildEmailPendingCard(context),
                      _AuthPane.promoterRequest => _buildPromoterRequestForm(
                        context,
                      ),
                      _AuthPane.promoterRequestSent =>
                        _buildPromoterRequestSentCard(context),
                      _ => _buildUserAuthForm(context),
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserAuthForm(BuildContext context) {
    final copy = context.copy;
    final theme = Theme.of(context);

    return Form(
      key: _authFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserModeChips(),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F1EA),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE0D2C4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  copy.text(it: 'Accesso utente', en: 'User access'),
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  _isUserSignUp
                      ? copy.text(
                          it: 'Crea il tuo profilo e poi entri nella tua area utente con serate, wallet e PR salvati.',
                          en: 'Create your profile and then enter your user area with events, wallet, and saved promoters.',
                        )
                      : copy.text(
                          it: 'Entra come utente per scoprire eventi, mettere like e prenotare in pochi tap.',
                          en: 'Sign in as a user to discover events, leave likes, and reserve in a few taps.',
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (_isUserSignUp) ...[
            TextFormField(
              controller: _fullNameController,
              decoration: InputDecoration(
                labelText: copy.text(it: 'Nome completo', en: 'Full name'),
              ),
              validator: (value) {
                if (!_isUserSignUp) {
                  return null;
                }
                if (value == null || value.trim().length < 2) {
                  return copy.text(
                    it: 'Inserisci il nome completo',
                    en: 'Enter your full name',
                  );
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
          ],
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: copy.text(it: 'Email', en: 'Email'),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || !value.contains('@')) {
                return copy.text(
                  it: 'Inserisci un email valida',
                  en: 'Enter a valid email',
                );
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: copy.text(it: 'Password', en: 'Password'),
            ),
            obscureText: true,
            validator: (value) {
              if (value == null || value.length < 6) {
                return copy.text(
                  it: 'Minimo 6 caratteri',
                  en: 'Minimum 6 characters',
                );
              }
              return null;
            },
          ),
          if (_errorText != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorText!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          Text(
            _isUserSignUp
                ? copy.text(
                    it: 'Dopo la registrazione, se il progetto richiede conferma email, resti guidato qui fino alla verifica.',
                    en: 'After sign-up, if the project requires email confirmation, you stay guided here until verification.',
                  )
                : copy.text(
                    it: 'Se invece devi lavorare come PR, apri il percorso PR qui sopra per entrare direttamente nell area promoter o richiedere l attivazione.',
                    en: 'If you need promoter access instead, switch to the promoter path above to enter the promoter area directly or request activation.',
                  ),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitAuthForm,
            child: Text(
              _isSubmitting
                  ? copy.text(it: 'Attendi...', en: 'Please wait...')
                  : (_isUserSignUp
                        ? copy.text(
                            it: 'Registrati come user',
                            en: 'Sign up as user',
                          )
                        : copy.text(
                            it: 'Accedi come user',
                            en: 'Sign in as user',
                          )),
            ),
          ),
          const SizedBox(height: 18),
          if (AppFlavorConfig.isDemo) ...[
            Text(
              copy.text(it: 'Account demo', en: 'Demo accounts'),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _DemoChip(
                  label: copy.text(it: 'Utente', en: 'User'),
                  email: 'user@nightradar.app',
                  onTap: _fillDemo,
                ),
                _DemoChip(
                  label: 'PR',
                  email: 'promoter@nightradar.app',
                  onTap: _fillDemo,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              copy.text(
                it: 'Password demo: NightRadar123!',
                en: 'Demo password: NightRadar123!',
              ),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPromoterAccessCard(BuildContext context) {
    final copy = context.copy;
    final theme = Theme.of(context);

    return Form(
      key: _authFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPromoterModeChips(),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F1EA),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE0D2C4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  copy.text(
                    it: 'Accesso PR diretto',
                    en: 'Direct promoter access',
                  ),
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  copy.text(
                    it: 'Se il tuo account PR e gia attivo, entri subito nell area promoter. Se non e ancora attivo, puoi inviare la richiesta dedicata qui accanto.',
                    en: 'If your promoter account is already active, you enter the promoter area immediately. If it is not active yet, you can send the dedicated request here.',
                  ),
                ),
              ],
            ),
          ),
          if (!AppFlavorConfig.isDemo) ...[
            const SizedBox(height: 18),
            _buildGoogleAccessCard(
              context,
              title: copy.text(
                it: 'Continua con Google come PR',
                en: 'Continue with Google as promoter',
              ),
              subtitle: copy.text(
                it: 'Appena il canale PR e approvato, NightRadar ti autentica e ti porta direttamente nell area promoter.',
                en: 'As soon as the promoter channel is approved, NightRadar authenticates you and brings you straight into the promoter area.',
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: Divider(color: theme.dividerColor)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(copy.text(it: 'oppure', en: 'or')),
                ),
                Expanded(child: Divider(color: theme.dividerColor)),
              ],
            ),
          ],
          const SizedBox(height: 18),
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: copy.text(it: 'Email PR', en: 'Promoter email'),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || !value.contains('@')) {
                return copy.text(
                  it: 'Inserisci un email valida',
                  en: 'Enter a valid email',
                );
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: copy.text(it: 'Password', en: 'Password'),
            ),
            obscureText: true,
            validator: (value) {
              if (value == null || value.length < 6) {
                return copy.text(
                  it: 'Minimo 6 caratteri',
                  en: 'Minimum 6 characters',
                );
              }
              return null;
            },
          ),
          if (_errorText != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorText!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitAuthForm,
            child: Text(
              _isSubmitting
                  ? copy.text(it: 'Attendi...', en: 'Please wait...')
                  : copy.text(it: 'Accedi come PR', en: 'Sign in as promoter'),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            copy.text(
              it: 'Quando il profilo PR e attivo, l accesso ti porta direttamente nella dashboard promoter senza passaggi aggiuntivi.',
              en: 'When the promoter profile is active, sign-in takes you straight to the promoter dashboard with no extra steps.',
            ),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 18),
          if (AppFlavorConfig.isDemo) ...[
            Text(
              copy.text(it: 'Account demo', en: 'Demo accounts'),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _DemoChip(
              label: 'PR',
              email: 'promoter@nightradar.app',
              onTap: _fillDemo,
            ),
            const SizedBox(height: 8),
            Text(
              copy.text(
                it: 'Password demo: NightRadar123!',
                en: 'Demo password: NightRadar123!',
              ),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGoogleAccessCard(
    BuildContext context, {
    required String title,
    required String subtitle,
  }) {
    final copy = context.copy;
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F1EA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0D2C4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(subtitle),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _continueWithGoogle,
            icon: const Icon(Icons.account_circle_outlined),
            label: Text(
              _isSubmitting
                  ? copy.text(it: 'Apro Google...', en: 'Opening Google...')
                  : copy.text(
                      it: 'Continua con Google',
                      en: 'Continue with Google',
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailPendingCard(BuildContext context) {
    final copy = context.copy;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          copy.text(it: 'Controlla la tua email', en: 'Check your email'),
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        Text(
          copy.text(
            it: 'Abbiamo preparato il tuo account, ma per entrare dobbiamo prima confermare l indirizzo email.',
            en: 'We prepared your account, but before signing in we need to confirm your email address.',
          ),
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF2ECE5),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            _pendingEmail ?? _emailController.text.trim(),
            style: theme.textTheme.titleMedium,
          ),
        ),
        if (_errorText != null) ...[
          const SizedBox(height: 12),
          Text(
            _errorText!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _isResendingEmail ? null : _resendSignupEmail,
          icon: const Icon(Icons.mark_email_read_outlined),
          label: Text(
            _isResendingEmail
                ? copy.text(it: 'Invio...', en: 'Sending...')
                : copy.text(it: 'Reinvia email', en: 'Resend email'),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _isSubmitting
              ? null
              : () {
                  setState(() {
                    _pane = _AuthPane.userSignIn;
                    _errorText = null;
                  });
                },
          icon: const Icon(Icons.login_rounded),
          label: Text(
            copy.text(
              it: 'Ho gia confermato, prova accesso',
              en: 'I already confirmed, try sign-in',
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: _isSubmitting
              ? null
              : () {
                  setState(() {
                    _pane = _AuthPane.userSignUp;
                    _errorText = null;
                  });
                },
          child: Text(
            copy.text(it: 'Usa un altra email', en: 'Use another email'),
          ),
        ),
      ],
    );
  }

  Widget _buildPromoterRequestForm(BuildContext context) {
    final copy = context.copy;
    final theme = Theme.of(context);

    return Form(
      key: _promoterRequestFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPromoterModeChips(),
          const SizedBox(height: 18),
          Text(
            copy.text(
              it: 'Richiesta account PR',
              en: 'Promoter account request',
            ),
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            copy.text(
              it: 'Mandaci i tuoi dati e apriamo il canale PR senza confondere il flusso utente normale.',
              en: 'Send us your details and we will open the promoter channel without confusing the normal user flow.',
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _fullNameController,
            decoration: InputDecoration(
              labelText: copy.text(it: 'Nome completo', en: 'Full name'),
            ),
            validator: (value) {
              if (value == null || value.trim().length < 2) {
                return copy.text(
                  it: 'Inserisci il nome completo',
                  en: 'Enter your full name',
                );
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: copy.text(it: 'Email', en: 'Email'),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || !value.contains('@')) {
                return copy.text(
                  it: 'Inserisci un email valida',
                  en: 'Enter a valid email',
                );
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _requestCityController,
            decoration: InputDecoration(
              labelText: copy.text(it: 'Citta', en: 'City'),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _requestPhoneController,
            decoration: InputDecoration(
              labelText: copy.text(it: 'Telefono', en: 'Phone'),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _requestInstagramController,
            decoration: InputDecoration(
              labelText: copy.text(
                it: 'Instagram o riferimento social',
                en: 'Instagram or social reference',
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _requestNoteController,
            decoration: InputDecoration(
              labelText: copy.text(
                it: 'Esperienza, locali o note utili',
                en: 'Experience, venues, or useful notes',
              ),
            ),
            maxLines: 4,
          ),
          if (_errorText != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorText!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _submitPromoterRequest,
            icon: const Icon(Icons.campaign_rounded),
            label: Text(
              _isSubmitting
                  ? copy.text(it: 'Invio...', en: 'Sending...')
                  : copy.text(
                      it: 'Invia richiesta PR',
                      en: 'Send promoter request',
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoterRequestSentCard(BuildContext context) {
    final copy = context.copy;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          copy.text(it: 'Richiesta PR inviata', en: 'Promoter request sent'),
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        Text(
          copy.text(
            it: 'Abbiamo salvato la tua richiesta PR. Ti contatteremo usando i dati che hai lasciato, senza interrompere il flusso utenti standard.',
            en: 'We saved your promoter request. We will contact you using the details you left, without interrupting the standard user flow.',
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF2ECE5),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            _pendingEmail ?? _emailController.text.trim(),
            style: theme.textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _pane = _AuthPane.promoterAccess;
              _errorText = null;
            });
          },
          child: Text(
            copy.text(it: 'Vai all accesso PR', en: 'Go to promoter access'),
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () {
            setState(() {
              _pane = _AuthPane.promoterRequest;
              _errorText = null;
            });
          },
          child: Text(
            copy.text(
              it: 'Modifica o invia un altra richiesta',
              en: 'Edit or send another request',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAudienceSelector(BuildContext context) {
    final copy = context.copy;
    return Row(
      children: [
        Expanded(
          child: _AudienceCard(
            icon: Icons.person_rounded,
            title: copy.text(it: 'Sono un user', en: 'I am a user'),
            subtitle: copy.text(
              it: 'Accedo o mi registro per vedere serate, like e prenotazioni.',
              en: 'I sign in or register to browse events, likes, and reservations.',
            ),
            selected: !_isPromoterPane,
            onTap: () => _setPane(_AuthPane.userSignIn),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _AudienceCard(
            icon: Icons.campaign_rounded,
            title: 'Sono un PR',
            subtitle: copy.text(
              it: 'Entro direttamente nell area promoter oppure richiedo attivazione.',
              en: 'I enter the promoter area directly or request activation.',
            ),
            selected: _isPromoterPane,
            onTap: () => _setPane(_AuthPane.promoterAccess),
          ),
        ),
      ],
    );
  }

  Widget _buildUserModeChips() {
    final copy = context.copy;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: Text(copy.text(it: 'Accesso user', en: 'User sign-in')),
          selected: _pane == _AuthPane.userSignIn,
          onSelected: (_) => _setPane(_AuthPane.userSignIn),
        ),
        if (!AppFlavorConfig.isDemo)
          ChoiceChip(
            label: Text(
              copy.text(it: 'Registrazione user', en: 'User sign-up'),
            ),
            selected: _pane == _AuthPane.userSignUp,
            onSelected: (_) => _setPane(_AuthPane.userSignUp),
          ),
      ],
    );
  }

  Widget _buildPromoterModeChips() {
    final copy = context.copy;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: Text(copy.text(it: 'Accesso PR', en: 'Promoter access')),
          selected: _pane == _AuthPane.promoterAccess,
          onSelected: (_) => _setPane(_AuthPane.promoterAccess),
        ),
        ChoiceChip(
          label: Text(
            copy.text(
              it: 'Richiedi attivazione PR',
              en: 'Request promoter activation',
            ),
          ),
          selected: _pane == _AuthPane.promoterRequest,
          onSelected: (_) => _setPane(_AuthPane.promoterRequest),
        ),
      ],
    );
  }

  void _setPane(_AuthPane pane) {
    if (AppFlavorConfig.isDemo && pane == _AuthPane.userSignUp) {
      return;
    }

    setState(() {
      _pane = pane;
      _errorText = null;
    });
  }

  Future<void> _submitAuthForm() async {
    if (!_authFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    final repository = ref.read(nightRadarRepositoryProvider);

    try {
      if (_isUserSignUp) {
        final response = await repository.signUp(
          fullName: _fullNameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (!mounted) {
          return;
        }

        if (response.session == null) {
          setState(() {
            _pendingEmail = _emailController.text.trim();
            _pane = _AuthPane.emailPending;
          });
          return;
        }
      } else {
        await repository.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }

      if (mounted) {
        final from = GoRouterState.of(context).uri.queryParameters['from'];
        context.go(
          from != null && from.isNotEmpty && from != '/auth' ? from : '/app',
        );
      }
    } catch (error) {
      final message = _humanizeError(error);
      final raw = error.toString().toLowerCase();
      final needsConfirmation =
          raw.contains('email_not_confirmed') ||
          raw.contains('email not confirmed');

      setState(() {
        _errorText = message;
        if (needsConfirmation) {
          _pendingEmail = _emailController.text.trim();
          _pane = _AuthPane.emailPending;
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _resendSignupEmail() async {
    final email = (_pendingEmail ?? _emailController.text).trim();
    if (email.isEmpty) {
      setState(() {
        _errorText = context.copy.text(
          it: 'Inserisci o recupera prima una email valida.',
          en: 'Enter or recover a valid email first.',
        );
      });
      return;
    }

    setState(() {
      _isResendingEmail = true;
      _errorText = null;
    });

    try {
      await ref
          .read(nightRadarRepositoryProvider)
          .resendSignupEmail(email: email);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.copy.text(
              it: 'Email di conferma reinviata a $email',
              en: 'Confirmation email sent again to $email',
            ),
          ),
        ),
      );
    } catch (error) {
      setState(() {
        _errorText = _humanizeError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isResendingEmail = false;
        });
      }
    }
  }

  Future<void> _submitPromoterRequest() async {
    if (!_promoterRequestFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      await ref
          .read(nightRadarRepositoryProvider)
          .createPromoterAccessRequest(
            fullName: _fullNameController.text.trim(),
            email: _emailController.text.trim(),
            city: _requestCityController.text.trim().isEmpty
                ? null
                : _requestCityController.text.trim(),
            phone: _requestPhoneController.text.trim().isEmpty
                ? null
                : _requestPhoneController.text.trim(),
            instagramHandle: _requestInstagramController.text.trim().isEmpty
                ? null
                : _requestInstagramController.text.trim(),
            experienceNote: _requestNoteController.text.trim().isEmpty
                ? null
                : _requestNoteController.text.trim(),
          );

      if (!mounted) {
        return;
      }

      setState(() {
        _pendingEmail = _emailController.text.trim();
        _pane = _AuthPane.promoterRequestSent;
      });
    } catch (error) {
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

  Future<void> _continueWithGoogle() async {
    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      final redirectTo = Uri.base.replace(queryParameters: {}).toString();
      await ref
          .read(nightRadarRepositoryProvider)
          .signInWithGoogle(redirectTo: redirectTo);
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

  String _heroBadgeLabel() {
    final copy = context.copy;
    return switch (_pane) {
      _AuthPane.promoterAccess ||
      _AuthPane.promoterRequest ||
      _AuthPane.promoterRequestSent => copy.text(
        it: 'ACCESSO PR',
        en: 'PR ACCESS',
      ),
      _AuthPane.emailPending => copy.text(it: 'CHECK EMAIL', en: 'EMAIL CHECK'),
      _ => 'NightRadar MVP',
    };
  }

  String _heroTitle() {
    final copy = context.copy;
    return switch (_pane) {
      _AuthPane.promoterAccess => copy.text(
        it: 'Accesso e attivazione PR in un punto solo.',
        en: 'Promoter access and activation in one place.',
      ),
      _AuthPane.promoterRequest => copy.text(
        it: 'Apri il canale PR senza rompere il percorso semplice per gli utenti.',
        en: 'Open the promoter channel without breaking the simple path for users.',
      ),
      _AuthPane.promoterRequestSent => copy.text(
        it: 'La tua richiesta PR e gia entrata nel radar operativo.',
        en: 'Your promoter request is already inside the operating radar.',
      ),
      _AuthPane.emailPending => copy.text(
        it: 'Un ultimo passaggio e poi NightRadar e pronto per te.',
        en: 'One last step and NightRadar is ready for you.',
      ),
      _ => copy.text(
        it: 'Scopri le serate, riempi le liste e manda al locale un riepilogo pronto.',
        en: 'Discover events, fill lists, and send the venue a ready summary.',
      ),
    };
  }

  String _heroSubtitle() {
    final copy = context.copy;
    return switch (_pane) {
      _AuthPane.promoterAccess => copy.text(
        it: 'Se il profilo PR e gia attivo entri subito nella dashboard. Se non lo e ancora, da qui passi alla richiesta dedicata in modo chiaro.',
        en: 'If the promoter profile is already active you go straight into the dashboard. If not, from here you move clearly into the dedicated request flow.',
      ),
      _AuthPane.promoterRequest => copy.text(
        it: 'La registrazione normale resta per gli utenti. Per il ruolo PR raccogliamo una richiesta dedicata e poi l accesso consigliato passa da Google.',
        en: 'Standard sign-up stays for users. For the promoter role we collect a dedicated request and then the recommended access goes through Google.',
      ),
      _AuthPane.promoterRequestSent => copy.text(
        it: 'Quando il profilo PR sara attivo potrai entrare con Google usando la stessa email condivisa nella richiesta.',
        en: 'When the promoter profile is active you can sign in with Google using the same email shared in the request.',
      ),
      _AuthPane.emailPending => copy.text(
        it: 'Se il progetto richiede verifica email, resti guidato qui con reinvio e accesso rapido appena confermi.',
        en: 'If the project requires email verification, you stay guided here with resend and quick access as soon as you confirm.',
      ),
      _ =>
        AppFlavorConfig.isDemo
            ? copy.text(
                it: 'Questa demo e pensata per esplorare utenti e PR in modalita read-only. Per operazioni reali usa la versione attiva.',
                en: 'This demo is designed to explore users and promoters in read-only mode. For real operations use the live version.',
              )
            : copy.text(
                it: 'Accedi come utente o richiedi account PR. I locali ricevono solo i dati finali, senza lato app dedicato.',
                en: 'Sign in as a user or request a promoter account. Venues receive only final data, without a dedicated app side.',
              ),
    };
  }

  String _humanizeError(Object error) {
    final raw = error.toString();
    final normalized = raw.toLowerCase();
    final copy = context.copy;

    if (normalized.contains('over_email_send_rate_limit') ||
        normalized.contains('email rate limit exceeded')) {
      return copy.text(
        it: 'Troppi invii email in poco tempo. Attendi qualche minuto e poi riprova.',
        en: 'Too many emails sent in a short time. Wait a few minutes and try again.',
      );
    }

    if (normalized.contains('email_not_confirmed') ||
        normalized.contains('email not confirmed')) {
      return copy.text(
        it: 'Email non ancora confermata. Apri la tua casella e conferma l accesso.',
        en: 'Email not confirmed yet. Open your inbox and confirm access.',
      );
    }

    if (normalized.contains('invalid login credentials')) {
      return copy.text(
        it: 'Email o password non corrette.',
        en: 'Incorrect email or password.',
      );
    }

    if (normalized.contains('account pr sospeso') ||
        normalized.contains('promoter account suspended')) {
      return copy.text(
        it: 'Account PR sospeso. Contatta il supporto NightRadar.',
        en: 'Promoter account suspended. Contact NightRadar support.',
      );
    }

    if (normalized.contains('user already registered')) {
      return copy.text(
        it: 'Questa email risulta gia registrata. Prova ad accedere.',
        en: 'This email is already registered. Try signing in.',
      );
    }

    if (normalized.contains('promoter_access_requests') &&
        normalized.contains('duplicate')) {
      return copy.text(
        it: 'Esiste gia una richiesta PR aperta per questa email.',
        en: 'There is already an open promoter request for this email.',
      );
    }

    return raw.replaceFirst('AuthException(message: ', '').replaceAll(')', '');
  }

  void _fillDemo(String email) {
    setState(() {
      _pane = email.contains('promoter')
          ? _AuthPane.promoterAccess
          : _AuthPane.userSignIn;
      _emailController.text = email;
      _passwordController.text = 'NightRadar123!';
      _errorText = null;
    });
  }
}

class _AudienceCard extends StatelessWidget {
  const _AudienceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF18130F) : const Color(0xFFF7F1EA),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? const Color(0xFFE85D3F) : const Color(0xFFE0D2C4),
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: selected
                  ? const Color(0xFFFFC9BA)
                  : const Color(0xFFE85D3F),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: selected ? Colors.white : null,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: selected ? Colors.white70 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DemoChip extends StatelessWidget {
  const _DemoChip({
    required this.label,
    required this.email,
    required this.onTap,
  });

  final String label;
  final String email;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text('$label  $email'),
      onPressed: () => onTap(email),
    );
  }
}
