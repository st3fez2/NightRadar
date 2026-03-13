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
        builder: (context, state) => const PromoterDashboardScreen(),
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
          return const AuthScreen();
        }

        if (!profile.hasAcceptedLegalVersion(nightRadarLegalVersion)) {
          return const LegalConsentScreen(
            requireSignedInProfileAcceptance: true,
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
