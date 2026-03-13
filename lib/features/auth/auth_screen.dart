import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_providers.dart';
import '../../core/widgets/public_link_card.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSignUp = false;
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'NightRadar MVP',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Scopri le serate, riempi le liste e manda al locale un riepilogo pronto.',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Accedi come utente o PR. I locali ricevono solo i dati finali, senza lato app dedicato.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.84),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const PublicLinkCard(
                  title: 'QR pubblico sempre disponibile',
                  subtitle:
                      'Dalla landing puoi condividere il progetto, aprire il sito live o scaricare il QR senza autenticarti.',
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ChoiceChip(
                                label: const Text('Accedi'),
                                selected: !_isSignUp,
                                onSelected: (_) => setState(() {
                                  _isSignUp = false;
                                }),
                              ),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: const Text('Registrati'),
                                selected: _isSignUp,
                                onSelected: (_) => setState(() {
                                  _isSignUp = true;
                                }),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          if (_isSignUp) ...[
                            TextFormField(
                              controller: _fullNameController,
                              decoration: const InputDecoration(
                                labelText: 'Nome completo',
                              ),
                              validator: (value) {
                                if (!_isSignUp) {
                                  return null;
                                }
                                if (value == null || value.trim().length < 2) {
                                  return 'Inserisci il nome completo';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                          ],
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || !value.contains('@')) {
                                return 'Inserisci un email valida';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passwordController,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.length < 6) {
                                return 'Minimo 6 caratteri';
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
                            onPressed: _isSubmitting ? null : _submit,
                            child: Text(_isSignUp ? 'Crea account' : 'Accedi'),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Account demo',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _DemoChip(
                                label: 'Utente',
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
                            'Password demo: NightRadar123!',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    final repository = ref.read(nightRadarRepositoryProvider);

    try {
      if (_isSignUp) {
        await repository.signUp(
          fullName: _fullNameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
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
      setState(() {
        _errorText = error
            .toString()
            .replaceFirst('AuthException(message: ', '')
            .replaceAll(')', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _fillDemo(String email) {
    setState(() {
      _isSignUp = false;
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
