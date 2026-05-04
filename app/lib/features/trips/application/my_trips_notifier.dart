import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vamos/data/models/trip.dart';
import 'package:vamos/data/repositories/firestore_trip_repository.dart';
import 'package:vamos/features/auth/application/auth_notifier.dart';
import 'package:vamos/features/trips/domain/trip_status.dart';

// ---------------------------------------------------------------------------
// Auth provider — overrideable for tests and dev mode
// ---------------------------------------------------------------------------

/// Provides the current user's ID.
///
/// Derived from [authStateProvider] so it automatically updates when the
/// user signs in or out. Returns an empty string when not authenticated.
///
/// Override in tests or the dev entry point to inject a fake user ID without
/// Firebase:
///
/// ```dart
/// ProviderScope(
///   overrides: [
///     currentUserIdProvider.overrideWithValue('user_test'),
///     tripRepositoryProvider.overrideWithValue(MockTripRepository()),
///   ],
///   child: MyApp(),
/// )
/// ```
final currentUserIdProvider = Provider<String>((ref) {
  return ref.watch(authStateProvider).value?.uid ?? '';
});

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

/// Streams the current user's trips, sorted for the F1.1 list:
///   ongoing → upcoming → finished → archived.
///
/// Within the same [TripStatus] bucket, trips are additionally sorted by
/// [startDate] ascending (soonest first for upcoming) — the repository
/// already returns data ordered by startDate from Firestore, so this
/// secondary sort is preserved naturally.
class MyTripsNotifier extends AutoDisposeStreamNotifier<List<Trip>> {
  @override
  Stream<List<Trip>> build() {
    final userId = ref.watch(currentUserIdProvider);

    if (userId.isEmpty) {
      // Not authenticated yet (E0-06 pending). Emit an empty list so the
      // notifier resolves to AsyncValue.data([]) instead of staying stuck
      // in loading. Stream.empty() closes without emitting, which would
      // freeze the screen on the loading spinner.
      return Stream.value(const <Trip>[]);
    }

    return ref
        .watch(tripRepositoryProvider)
        .watchUserTrips(userId)
        .map(_sortedByStatus);
  }

  List<Trip> _sortedByStatus(List<Trip> trips) {
    final now = DateTime.now();
    return List<Trip>.from(trips)
      ..sort((a, b) {
        final statusA = computeStatus(
          start: a.startDate,
          end: a.endDate,
          isArchived: a.status == 'archived',
          now: now,
        );
        final statusB = computeStatus(
          start: b.startDate,
          end: b.endDate,
          isArchived: b.status == 'archived',
          now: now,
        );
        final keyDiff = tripStatusSortKey(statusA) - tripStatusSortKey(statusB);
        if (keyDiff != 0) return keyDiff;
        // Within same status bucket: sort by startDate ascending.
        return a.startDate.compareTo(b.startDate);
      });
  }
}

/// Riverpod provider for [MyTripsNotifier].
///
/// autoDispose: true — the screen owns the lifecycle. When the user navigates
/// away, the Firestore listener is released.
final myTripsProvider =
    AutoDisposeStreamNotifierProvider<MyTripsNotifier, List<Trip>>(
  MyTripsNotifier.new,
);
