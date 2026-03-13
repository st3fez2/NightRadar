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
  signIn,
  signUp,
  emailPending,
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

  _AuthPane _pane = _AuthPane.signIn;
  bool _isSubmitting = false;
  bool _isResendingEmail = false;
  String? _errorText;
  String? _pendingEmail;

  bool get _isSignUp => _pane == _AuthPane.signUp;

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
                    it:
                        'Dalla landing puoi condividere il progetto, aprire il sito live o scaricare il QR senza autenticarti.',
                    en:
                        'From the landing page you can share the project, open the live site, or download the QR without signing in.',
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
                                it:
                                    'Prima di usare NightRadar chiediamo un consenso iniziale dedicato, cosi i flussi utenti e PR restano coperti anche lato web mobile.',
                                en:
                                    'Before using NightRadar we ask for a dedicated initial consent, so user and promoter flows stay covered on mobile web too.',
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
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: switch (_pane) {
                      _AuthPane.emailPending => _buildEmailPendingCard(context),
                      _AuthPane.promoterRequest => _buildPromoterRequestForm(
                        context,
                      ),
                      _AuthPane.promoterRequestSent =>
                        _buildPromoterRequestSentCard(context),
                      _ => _buildAuthForm(context),
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

  Widget _buildAuthForm(BuildContext context) {
    final copy = context.copy;
    final theme = Theme.of(context);

    return Form(
      key: _authFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildModeChips(),
          const SizedBox(height: 18),
          if (_isSignUp) ...[
            TextFormField(
              controller: _fullNameController,
              decoration: InputDecoration(
                labelText: copy.text(it: 'Nome completo', en: 'Full name'),
              ),
              validator: (value) {
                if (!_isSignUp) {
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
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitAuthForm,
            child: Text(
              _isSubmitting
                  ? copy.text(it: 'Attendi...', en: 'Please wait...')
                  : (_isSignUp
                        ? copy.text(it: 'Crea account', en: 'Create account')
                        : copy.text(it: 'Accedi', en: 'Sign in')),
            ),
          ),
          if (_isSignUp) ...[
            const SizedBox(height: 10),
            Text(
              copy.text(
                it:
                    'Se il progetto richiede conferma email, dopo la registrazione ti porto direttamente alla schermata di verifica.',
                en:
                    'If the project requires email confirmation, after sign-up I take you straight to the verification screen.',
              ),
              style: theme.textTheme.bodySmall,
            ),
          ],
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
            it:
                'Abbiamo preparato il tuo account, ma per entrare dobbiamo prima confermare l indirizzo email.',
            en:
                'We prepared your account, but before signing in we need to confirm your email address.',
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
                    _pane = _AuthPane.signIn;
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
                    _pane = _AuthPane.signUp;
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
          _buildModeChips(),
          const SizedBox(height: 18),
          Text(
            copy.text(it: 'Richiesta account PR', en: 'Promoter account request'),
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            copy.text(
              it:
                  'Mandaci i tuoi dati e apriamo il canale PR senza confondere il flusso utente normale.',
              en:
                  'Send us your details and we will open the promoter channel without confusing the normal user flow.',
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
            it:
                'Abbiamo salvato la tua richiesta PR. Ti contatteremo usando i dati che hai lasciato, senza interrompere il flusso utenti standard.',
            en:
                'We saved your promoter request. We will contact you using the details you left, without interrupting the standard user flow.',
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
              _pane = _AuthPane.signIn;
              _errorText = null;
            });
          },
          child: Text(copy.text(it: 'Vai all accesso', en: 'Go to sign-in')),
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

  Widget _buildModeChips() {
    final copy = context.copy;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: Text(copy.text(it: 'Accedi', en: 'Sign in')),
          selected: _pane == _AuthPane.signIn,
          onSelected: (_) => _setPane(_AuthPane.signIn),
        ),
        if (!AppFlavorConfig.isDemo)
          ChoiceChip(
            label: Text(copy.text(it: 'Registrati', en: 'Sign up')),
            selected: _pane == _AuthPane.signUp,
            onSelected: (_) => _setPane(_AuthPane.signUp),
          ),
        ChoiceChip(
          label: Text(
            copy.text(it: 'Richiedi account PR', en: 'Request promoter account'),
          ),
          selected: _pane == _AuthPane.promoterRequest,
          onSelected: (_) => _setPane(_AuthPane.promoterRequest),
        ),
      ],
    );
  }

  void _setPane(_AuthPane pane) {
    if (AppFlavorConfig.isDemo && pane == _AuthPane.signUp) {
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
      if (_isSignUp) {
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

  String _heroBadgeLabel() {
    final copy = context.copy;
    return switch (_pane) {
      _AuthPane.promoterRequest || _AuthPane.promoterRequestSent => copy.text(
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
      _AuthPane.promoterRequest =>
        copy.text(
          it: 'Apri il canale PR senza rompere il percorso semplice per gli utenti.',
          en: 'Open the promoter channel without breaking the simple path for users.',
        ),
      _AuthPane.promoterRequestSent =>
        copy.text(
          it: 'La tua richiesta PR e gia entrata nel radar operativo.',
          en: 'Your promoter request is already inside the operating radar.',
        ),
      _AuthPane.emailPending =>
        copy.text(
          it: 'Un ultimo passaggio e poi NightRadar e pronto per te.',
          en: 'One last step and NightRadar is ready for you.',
        ),
      _ =>
        copy.text(
          it: 'Scopri le serate, riempi le liste e manda al locale un riepilogo pronto.',
          en: 'Discover events, fill lists, and send the venue a ready summary.',
        ),
    };
  }

  String _heroSubtitle() {
    final copy = context.copy;
    return switch (_pane) {
      _AuthPane.promoterRequest =>
        copy.text(
          it:
              'La registrazione normale resta per gli utenti. Per il ruolo PR raccogliamo una richiesta dedicata, piu chiara e gestibile.',
          en:
              'Standard sign-up stays for users. For the promoter role we collect a dedicated request that is clearer and easier to manage.',
        ),
      _AuthPane.promoterRequestSent =>
        copy.text(
          it:
              'Adesso puoi anche usare il login standard oppure attendere il contatto del team per l attivazione PR.',
          en:
              'Now you can also use the standard login or wait for the team to contact you for promoter activation.',
        ),
      _AuthPane.emailPending =>
        copy.text(
          it:
              'Se il progetto richiede verifica email, resti guidato qui con reinvio e accesso rapido appena confermi.',
          en:
              'If the project requires email verification, you stay guided here with resend and quick access as soon as you confirm.',
        ),
      _ =>
        AppFlavorConfig.isDemo
            ? copy.text(
                it:
                    'Questa demo e pensata per esplorare utenti e PR in modalita read-only. Per operazioni reali usa la versione attiva.',
                en:
                    'This demo is designed to explore users and promoters in read-only mode. For real operations use the live version.',
              )
            : copy.text(
                it:
                    'Accedi come utente o richiedi account PR. I locali ricevono solo i dati finali, senza lato app dedicato.',
                en:
                    'Sign in as a user or request a promoter account. Venues receive only final data, without a dedicated app side.',
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
      _pane = _AuthPane.signIn;
      _emailController.text = email;
      _passwordController.text = 'NightRadar123!';
      _errorText = null;
    });
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
