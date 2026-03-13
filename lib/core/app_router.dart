import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_screen.dart';
import '../features/events/presentation/event_detail_screen.dart';
import '../features/events/presentation/reservation_form_screen.dart';
import '../features/events/presentation/user_home_screen.dart';
import '../features/events/presentation/wallet_screen.dart';
import '../features/promoter/promoter_dashboard_screen.dart';
import '../features/public/public_home_screen.dart';
import '../shared/models.dart';
import 'app_providers.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final refresh = GoRouterRefreshStream(client.auth.onAuthStateChange);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final signedIn = client.auth.currentSession != null;
      final isAuthRoute = state.matchedLocation == '/auth';
      final isPublicRoute =
          state.matchedLocation == '/' ||
          isAuthRoute ||
          state.fullPath == '/event/:eventId';

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
    final profileAsync = ref.watch(currentProfileProvider);

    return profileAsync.when(
      data: (profile) {
        if (profile == null) {
          return const AuthScreen();
        }

        return switch (profile.role) {
          AppRole.promoter => const PromoterDashboardScreen(),
          AppRole.venueAdmin || AppRole.doorStaff => const _LegacyRoleScreen(),
          _ => const UserHomeScreen(),
        };
      },
      error: (error, stackTrace) =>
          _RouteStatusView(title: 'Errore profilo', message: error.toString()),
      loading: () => const _RouteStatusView(
        title: 'NightRadar',
        message: 'Sto preparando la tua area.',
        loading: true,
      ),
    );
  }
}

class _LegacyRoleScreen extends StatelessWidget {
  const _LegacyRoleScreen();

  @override
  Widget build(BuildContext context) {
    return const _RouteStatusView(
      title: 'Area Locale Rimossa',
      message:
          'NightRadar ora e solo per utenti e PR. I locali ricevono le liste finali via condivisione esterna, senza dashboard dedicata nell app.',
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
