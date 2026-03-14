import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app_copy.dart';
import '../features/auth/auth_screen.dart';
import '../features/events/presentation/event_detail_screen.dart';
import '../features/events/presentation/reservation_form_screen.dart';
import '../features/events/presentation/user_home_screen.dart';
import '../features/legal/legal_consent_screen.dart';
import '../features/legal/legal_providers.dart';
import '../features/events/presentation/wallet_screen.dart';
import '../features/promoter/promoter_dashboard_screen.dart';
import '../features/public/public_home_screen.dart';
import '../shared/legal_constants.dart';
import '../shared/models.dart';
import 'app_providers.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final localLegalAccepted = ref.watch(localLegalConsentProvider);
  final refresh = GoRouterRefreshStream(client.auth.onAuthStateChange);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final signedIn = client.auth.currentSession != null;
      final isAuthRoute = state.matchedLocation == '/auth';
      final isLegalRoute = state.matchedLocation == '/legal';
      final isPublicRoute =
          state.matchedLocation == '/' ||
          state.matchedLocation == '/app' ||
          isLegalRoute ||
          isAuthRoute ||
          state.fullPath == '/event/:eventId' ||
          state.fullPath == '/event/:eventId/reserve';

      if (!localLegalAccepted && !isLegalRoute) {
        final from = Uri.encodeComponent(state.uri.toString());
        return '/legal?from=$from';
      }

      if (!signedIn && !isPublicRoute) {
        final from = Uri.encodeComponent(state.uri.toString());
        return '/auth?from=$from';
      }

      if (signedIn && isAuthRoute) {
        final from = state.uri.queryParameters['from'];
        if (from != null && from.isNotEmpty && from != '/auth') {
          return from;
        }
        return '/app';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
      GoRoute(
        path: '/legal',
        builder: (context, state) =>
            LegalConsentScreen(fromPath: state.uri.queryParameters['from']),
      ),
      GoRoute(path: '/', builder: (context, state) => const PublicHomeScreen()),
      GoRoute(path: '/app', builder: (context, state) => const AppHomeScreen()),
      GoRoute(
        path: '/event/:eventId',
        builder: (context, state) =>
            EventDetailScreen(eventId: state.pathParameters['eventId']!),
      ),
      GoRoute(
        path: '/event/:eventId/reserve',
        builder: (context, state) => ReservationFormScreen(
          eventId: state.pathParameters['eventId']!,
          offerId: state.uri.queryParameters['offerId'],
        ),
      ),
      GoRoute(
        path: '/wallet/:reservationId',
        builder: (context, state) =>
            WalletScreen(reservationId: state.pathParameters['reservationId']!),
      ),
      GoRoute(
        path: '/promoter',
        builder: (context, state) => const PromoterAreaGate(),
      ),
    ],
  );
});

class AppHomeScreen extends ConsumerWidget {
  const AppHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copy = context.copy;
    final profileAsync = ref.watch(currentProfileProvider);

    return profileAsync.when(
      data: (profile) {
        if (profile == null) {
          return const UserHomeScreen();
        }

        if (!profile.hasAcceptedLegalVersion(nightRadarLegalVersion)) {
          return const LegalConsentScreen(
            requireSignedInProfileAcceptance: true,
          );
        }

        if (profile.role == AppRole.promoter && profile.isPromoterSuspended) {
          return PromoterSuspendedScreen(
            reason: profile.promoterSuspensionReason,
          );
        }

        return switch (profile.role) {
          AppRole.promoter => const PromoterDashboardScreen(),
          AppRole.venueAdmin || AppRole.doorStaff => const _LegacyRoleScreen(),
          _ => const UserHomeScreen(),
        };
      },
      error: (error, stackTrace) => _RouteStatusView(
        title: copy.text(it: 'Errore profilo', en: 'Profile error'),
        message: error.toString(),
      ),
      loading: () => _RouteStatusView(
        title: 'NightRadar',
        message: copy.text(
          it: 'Sto preparando la tua area.',
          en: 'Preparing your area.',
        ),
        loading: true,
      ),
    );
  }
}

class PromoterAreaGate extends ConsumerWidget {
  const PromoterAreaGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copy = context.copy;
    final profileAsync = ref.watch(currentProfileProvider);

    return profileAsync.when(
      data: (profile) {
        if (profile == null) {
          return const AuthScreen();
        }

        if (profile.isPromoterSuspended) {
          return PromoterSuspendedScreen(
            reason: profile.promoterSuspensionReason,
          );
        }

        if (profile.role != AppRole.promoter) {
          return _RouteStatusView(
            title: copy.text(
              it: 'Area PR non disponibile',
              en: 'PR area unavailable',
            ),
            message: copy.text(
              it: 'Questo account non ha un profilo PR. Accedi come utente oppure crea un account promoter dal percorso PR.',
              en: 'This account does not have a promoter profile. Sign in as a user or create a promoter account from the promoter path.',
            ),
          );
        }

        if (!profile.hasAcceptedLegalVersion(nightRadarLegalVersion)) {
          return const LegalConsentScreen(
            requireSignedInProfileAcceptance: true,
          );
        }

        return const PromoterDashboardScreen();
      },
      error: (error, stackTrace) => _RouteStatusView(
        title: copy.text(it: 'Errore area PR', en: 'Promoter area error'),
        message: error.toString(),
      ),
      loading: () => _RouteStatusView(
        title: 'NightRadar',
        message: copy.text(
          it: 'Sto preparando la tua area PR.',
          en: 'Preparing your promoter area.',
        ),
        loading: true,
      ),
    );
  }
}

class PromoterSuspendedScreen extends ConsumerWidget {
  const PromoterSuspendedScreen({super.key, this.reason});

  final String? reason;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copy = context.copy;
    final theme = Theme.of(context);
    final cleanReason = reason?.trim();

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.pause_circle_filled_rounded,
                  size: 52,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 18),
                Text(
                  copy.text(
                    it: 'Account PR sospeso',
                    en: 'Promoter account suspended',
                  ),
                  style: theme.textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  cleanReason == null || cleanReason.isEmpty
                      ? copy.text(
                          it: 'L accesso all area promoter e temporaneamente bloccato. Contatta il supporto NightRadar per riattivare il profilo.',
                          en: 'Access to the promoter area is temporarily blocked. Contact NightRadar support to reactivate the profile.',
                        )
                      : copy.text(
                          it: 'L accesso all area promoter e temporaneamente bloccato. Motivo: $cleanReason',
                          en: 'Access to the promoter area is temporarily blocked. Reason: $cleanReason',
                        ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: () async {
                    final client = ref.read(supabaseClientProvider);
                    await client.auth.signOut();
                    if (context.mounted) {
                      context.go('/auth');
                    }
                  },
                  child: Text(copy.text(it: 'Esci', en: 'Sign out')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LegacyRoleScreen extends StatelessWidget {
  const _LegacyRoleScreen();

  @override
  Widget build(BuildContext context) {
    final copy = context.copy;
    return _RouteStatusView(
      title: copy.text(it: 'Area locale rimossa', en: 'Venue area removed'),
      message: copy.text(
        it: 'NightRadar ora e solo per utenti e PR. I locali ricevono le liste finali via condivisione esterna, senza dashboard dedicata nell app.',
        en: 'NightRadar is now only for users and promoters. Venues receive final lists via external sharing, without a dedicated in-app dashboard.',
      ),
    );
  }
}

class _RouteStatusView extends StatelessWidget {
  const _RouteStatusView({
    required this.title,
    required this.message,
    this.loading = false,
  });

  final String title;
  final String message;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading) const CircularProgressIndicator(),
              if (loading) const SizedBox(height: 18),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
