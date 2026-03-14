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
import '../../shared/models.dart';

enum _AuthPane {
  userSignIn,
  userSignUp,
  emailPending,
  promoterSignIn,
  promoterSignUp,
}

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _authFormKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  _AuthPane _pane = _AuthPane.userSignIn;
  String? _lastRouteMode;
  bool _isSubmitting = false;
  bool _isResendingEmail = false;
  bool _isCompletingPromoterGoogleSignup = false;
  bool _hasProcessedPromoterGoogleSignup = false;
  String? _errorText;
  String? _pendingEmail;
  bool _pendingPromoterSignUp = false;

  bool get _isUserSignIn => _pane == _AuthPane.userSignIn;
  bool get _isUserSignUp => _pane == _AuthPane.userSignUp;
  bool get _isPromoterSignUp => _pane == _AuthPane.promoterSignUp;
  bool get _isPromoterPane =>
      _pane == _AuthPane.promoterSignIn || _pane == _AuthPane.promoterSignUp;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uri = _currentRouteUri();
    if (uri == null) {
      return;
    }
    final routeMode =
        '${uri.queryParameters['mode']}|${uri.queryParameters['from']}';
    if (_lastRouteMode == routeMode) {
      return;
    }
    _lastRouteMode = routeMode;
    if (uri.queryParameters['oauth_role'] != 'promoter') {
      _hasProcessedPromoterGoogleSignup = false;
    }

    final requestedPane = _paneFromUri(uri);
    final resolvedPane = AppFlavorConfig.isDemo
        ? switch (requestedPane) {
            _AuthPane.userSignUp => _AuthPane.userSignIn,
            _AuthPane.promoterSignUp => _AuthPane.promoterSignIn,
            _ => requestedPane,
          }
        : requestedPane;
    if (resolvedPane == null || resolvedPane == _pane) {
      return;
    }

    setState(() {
      _pane = resolvedPane;
      _errorText = null;
      if (resolvedPane != _AuthPane.emailPending) {
        _pendingPromoterSignUp = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final copy = context.copy;
    final theme = Theme.of(context);
    final authUser = ref.watch(currentAuthUserProvider);

    if (authUser != null &&
        _currentRouteUri()?.queryParameters['oauth_role'] == 'promoter' &&
        !_isCompletingPromoterGoogleSignup &&
        !_hasProcessedPromoterGoogleSignup) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _completePromoterGoogleSignup();
      });
    }

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
                      _AuthPane.promoterSignIn => _buildPromoterSignInCard(
                        context,
                      ),
                      _AuthPane.emailPending => _buildEmailPendingCard(context),
                      _AuthPane.promoterSignUp => _buildPromoterSignUpForm(
                        context,
                      ),
                      _ => _buildUserAuthForm(context),
                    },
                  ),
                ),
                if (AppFlavorConfig.isDemo) ...[
                  const SizedBox(height: 12),
                  const FlavorNoticeCard(compact: true),
                ],
                const SizedBox(height: 16),
                PublicLinkCard(
                  compact: true,
                  title: copy.text(
                    it: 'Condividi NightRadar',
                    en: 'Share NightRadar',
                  ),
                  subtitle: copy.text(
                    it: 'QR e link pubblico sempre pronti, ma tenuti in coda per non rubare spazio all accesso.',
                    en: 'Public QR and link always ready, but kept at the bottom so they do not steal focus from access.',
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
          if (!AppFlavorConfig.isDemo && _isUserSignIn) ...[
            const SizedBox(height: 18),
            _buildGoogleAccessCard(
              context,
              title: copy.text(
                it: 'Continua con Google come user',
                en: 'Continue with Google as user',
              ),
              subtitle: copy.text(
                it: 'Se vuoi entrare piu velocemente per prenotare e salvare i tuoi pass, puoi usare Google e tornare subito all evento che stavi aprendo.',
                en: 'If you want a faster way to book and save your passes, you can use Google and go straight back to the event you were opening.',
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
                    it: 'Se invece devi lavorare come PR, apri il percorso PR qui sopra per accedere o registrarti direttamente come promoter.',
                    en: 'If you need promoter access instead, switch to the promoter path above to sign in or sign up directly as a promoter.',
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

  Widget _buildPromoterSignInCard(BuildContext context) {
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
                    it: 'Se hai gia un account PR, accedi e NightRadar ti porta subito nella dashboard promoter. Se devi ancora crearlo, usa la registrazione PR qui sopra.',
                    en: 'If you already have a promoter account, sign in and NightRadar takes you straight to the promoter dashboard. If you still need to create it, use the promoter sign-up above.',
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
                it: 'Se il tuo account PR e gia registrato, Google ti autentica e ti porta direttamente nell area promoter.',
                en: 'If your promoter account is already registered, Google authenticates you and takes you straight into the promoter area.',
              ),
              promoterSignupFlow: true,
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
    bool promoterSignupFlow = false,
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
            onPressed: _isSubmitting
                ? null
                : () => _continueWithGoogle(
                    promoterSignupFlow: promoterSignupFlow,
                  ),
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
          _pendingPromoterSignUp
              ? copy.text(
                  it: 'Abbiamo preparato il tuo account PR, ma per entrare dobbiamo prima confermare l indirizzo email.',
                  en: 'We prepared your promoter account, but before signing in we need to confirm your email address.',
                )
              : copy.text(
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
                    _pane = _pendingPromoterSignUp
                        ? _AuthPane.promoterSignIn
                        : _AuthPane.userSignIn;
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
                    _pane = _pendingPromoterSignUp
                        ? _AuthPane.promoterSignUp
                        : _AuthPane.userSignUp;
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

  Widget _buildPromoterSignUpForm(BuildContext context) {
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
                    it: 'Registrazione PR automatica',
                    en: 'Automatic promoter sign-up',
                  ),
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  copy.text(
                    it: 'Crea direttamente il tuo account PR. Dopo l accesso potrai completare la scheda con bio, foto o logo, Instagram e TikTok.',
                    en: 'Create your promoter account directly. After sign-in you can complete the card with bio, photo or logo, Instagram, and TikTok.',
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
                it: 'Registrati con Google come PR',
                en: 'Sign up with Google as promoter',
              ),
              subtitle: copy.text(
                it: 'Se e il tuo primo accesso, Google crea l account e NightRadar completa subito il profilo promoter al rientro.',
                en: 'If this is your first access, Google creates the account and NightRadar completes the promoter profile as soon as you come back.',
              ),
              promoterSignupFlow: true,
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
                  : copy.text(
                      it: 'Registrati come PR',
                      en: 'Sign up as promoter',
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            copy.text(
              it: 'La registrazione PR crea subito il profilo promoter. Da dashboard potrai poi personalizzare la tua scheda pubblica con foto o logo.',
              en: 'Promoter sign-up creates the promoter profile immediately. From the dashboard you can then customize the public card with a photo or logo.',
            ),
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
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
              it: 'Accedo o mi registro come promoter e poi personalizzo la mia scheda PR.',
              en: 'I sign in or sign up as a promoter and then customize my promoter card.',
            ),
            selected: _isPromoterPane,
            onTap: () => _setPane(_AuthPane.promoterSignIn),
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
          selected: _pane == _AuthPane.promoterSignIn,
          onSelected: (_) => _setPane(_AuthPane.promoterSignIn),
        ),
        if (!AppFlavorConfig.isDemo)
          ChoiceChip(
            label: Text(
              copy.text(it: 'Registrazione PR', en: 'Promoter sign-up'),
            ),
            selected: _pane == _AuthPane.promoterSignUp,
            onSelected: (_) => _setPane(_AuthPane.promoterSignUp),
          ),
      ],
    );
  }

  _AuthPane? _paneFromUri(Uri uri) {
    final mode = uri.queryParameters['mode']?.trim();
    return switch (mode) {
      'user-signup' => _AuthPane.userSignUp,
      'promoter-signin' => _AuthPane.promoterSignIn,
      'promoter-signup' => _AuthPane.promoterSignUp,
      'user-signin' => _AuthPane.userSignIn,
      _ => _defaultPaneFromTarget(uri.queryParameters['from']),
    };
  }

  _AuthPane? _defaultPaneFromTarget(String? from) {
    if (from == null || from.isEmpty) {
      return null;
    }
    return from.startsWith('/promoter') ? _AuthPane.promoterSignIn : null;
  }

  void _setPane(_AuthPane pane) {
    if (AppFlavorConfig.isDemo &&
        (pane == _AuthPane.userSignUp || pane == _AuthPane.promoterSignUp)) {
      return;
    }

    setState(() {
      _pane = pane;
      _errorText = null;
      if (pane != _AuthPane.emailPending) {
        _pendingPromoterSignUp = false;
      }
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
      if (_isUserSignUp || _isPromoterSignUp) {
        final response = await repository.signUp(
          fullName: _fullNameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          role: _isPromoterSignUp ? AppRole.promoter : AppRole.user,
        );

        if (!mounted) {
          return;
        }

        if (response.session == null) {
          setState(() {
            _pendingEmail = _emailController.text.trim();
            _pendingPromoterSignUp = _isPromoterSignUp;
            _pane = _AuthPane.emailPending;
          });
          return;
        }
      } else {
        await repository.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        if (_pane == _AuthPane.promoterSignIn) {
          await repository.promoteCurrentUserToPromoter();
          ref.invalidate(currentProfileProvider);
        }
      }

      if (_isPromoterSignUp) {
        await repository.promoteCurrentUserToPromoter();
        ref.invalidate(currentProfileProvider);
      }

      if (mounted) {
        final from = _currentRouteUri()?.queryParameters['from'];
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
          _pendingPromoterSignUp = _isPromoterSignUp;
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

  Future<void> _continueWithGoogle({bool promoterSignupFlow = false}) async {
    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      final baseUri = Uri.base;
      final queryParameters = Map<String, String>.from(baseUri.queryParameters);
      if (promoterSignupFlow) {
        queryParameters['mode'] = 'promoter-signup';
        queryParameters['oauth_role'] = 'promoter';
        queryParameters['from'] = '/promoter';
      }
      final redirectTo = baseUri
          .replace(queryParameters: queryParameters)
          .toString();
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

  Future<void> _completePromoterGoogleSignup() async {
    if (_isCompletingPromoterGoogleSignup) {
      return;
    }

    setState(() {
      _hasProcessedPromoterGoogleSignup = true;
      _isCompletingPromoterGoogleSignup = true;
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      await ref
          .read(nightRadarRepositoryProvider)
          .promoteCurrentUserToPromoter();
      ref.invalidate(currentProfileProvider);

      if (!mounted) {
        return;
      }

      final from = _currentRouteUri()?.queryParameters['from'];
      context.go(
        from != null && from.isNotEmpty && from != '/auth' ? from : '/promoter',
      );
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
          _isCompletingPromoterGoogleSignup = false;
          _isSubmitting = false;
        });
      }
    }
  }

  Uri? _currentRouteUri() {
    try {
      return GoRouterState.of(context).uri;
    } catch (_) {
      return null;
    }
  }

  String _heroBadgeLabel() {
    final copy = context.copy;
    return switch (_pane) {
      _AuthPane.promoterSignIn ||
      _AuthPane.promoterSignUp => copy.text(it: 'ACCESSO PR', en: 'PR ACCESS'),
      _AuthPane.emailPending => copy.text(it: 'CHECK EMAIL', en: 'EMAIL CHECK'),
      _ => 'NightRadar MVP',
    };
  }

  String _heroTitle() {
    final copy = context.copy;
    return switch (_pane) {
      _AuthPane.promoterSignIn || _AuthPane.promoterSignUp => copy.text(
        it: 'Accesso e registrazione PR in un punto solo.',
        en: 'Promoter access and sign-up in one place.',
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
      _AuthPane.promoterSignIn || _AuthPane.promoterSignUp => copy.text(
        it: 'Il promoter puo accedere o registrarsi direttamente. Dopo l ingresso completa la scheda con bio, foto o logo e canali pubblici se vuole mostrarli.',
        en: 'A promoter can sign in or sign up directly. After entry they complete the card with bio, photo or logo, and public channels if they want to show them.',
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
                it: 'Accedi o registrati come utente o PR. I locali ricevono solo i dati finali, senza lato app dedicato.',
                en: 'Sign in or sign up as a user or promoter. Venues receive only final data, without a dedicated app side.',
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
        it: 'Questa email PR risulta gia collegata. Prova ad accedere.',
        en: 'This promoter email is already linked. Try signing in.',
      );
    }

    return raw.replaceFirst('AuthException(message: ', '').replaceAll(')', '');
  }

  void _fillDemo(String email) {
    setState(() {
      _pane = email.contains('promoter')
          ? _AuthPane.promoterSignIn
          : _AuthPane.userSignIn;
      _emailController.text = email;
      _passwordController.text = 'NightRadar123!';
      _errorText = null;
      _pendingPromoterSignUp = false;
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
