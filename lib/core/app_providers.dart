import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/events/data/nightradar_repository.dart';
import '../shared/models.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final nightRadarRepositoryProvider = Provider<NightRadarRepository>((ref) {
  return NightRadarRepository(ref.watch(supabaseClientProvider));
});

final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseClientProvider).auth.onAuthStateChange;
});

final currentProfileProvider = FutureProvider<AppProfile?>((ref) async {
  ref.watch(authStateChangesProvider);
  return ref.watch(nightRadarRepositoryProvider).getCurrentProfile();
});

final eventFeedProvider = FutureProvider<List<EventSummary>>((ref) async {
  return ref.watch(nightRadarRepositoryProvider).fetchEventFeed();
});

final eventDetailsProvider =
    FutureProvider.family<EventDetails, String>((ref, eventId) async {
  return ref.watch(nightRadarRepositoryProvider).fetchEventDetails(eventId);
});

final myReservationsProvider =
    FutureProvider<List<ReservationRecord>>((ref) async {
  ref.watch(authStateChangesProvider);
  return ref.watch(nightRadarRepositoryProvider).fetchMyReservations();
});

final reservationProvider =
    FutureProvider.family<ReservationRecord, String>((ref, reservationId) async {
  return ref.watch(nightRadarRepositoryProvider).fetchReservationById(
        reservationId,
      );
});

final promoterDashboardProvider =
    FutureProvider<PromoterDashboardData>((ref) async {
  ref.watch(authStateChangesProvider);
  return ref.watch(nightRadarRepositoryProvider).fetchPromoterDashboard();
});
