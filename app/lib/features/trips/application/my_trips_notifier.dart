import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vamos/data/models/trip.dart';
import 'package:vamos/data/repositories/trip_repository.dart';
import 'package:vamos/features/trips/domain/trip_status.dart';

/// Streams the current user's trips, sorted for the F1.1 list:
///   ongoing (🟢) → upcoming (🟡) → finished (⚪) → archived (📦).
///
/// Within the same [TripStatus] bucket, trips are additionally sorted by
/// [startDate] ascending (soonest first for upcoming) — the repository
/// already returns data ordered by startDate from Firestore, so this
/// secondary sort is preserved naturally.
///
/// Auth: if E0-06 (auth) is not yet wired, this notifier falls back to a
/// [_mockUserId] constant. Replace with the real auth provider when available.
class MyTripsNotifier extends AutoDisposeStreamNotifier<List<Trip>> {
  @override
  Stream<List<Trip>> build() {
    // TODO(F1-01): replace with real auth provider once E0-06 is implemented.
    // e.g. final userId = ref.watch(authStateProvider).value?.uid ?? '';
    const userId = _mockUserId;

    if (userId.isEmpty) {
      // Not authenticated: emit empty list instead of crashing.
      return const Stream.empty();
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

// ---------------------------------------------------------------------------
// Auth mock — remove when E0-06 lands
// ---------------------------------------------------------------------------

/// Placeholder user ID used until E0-06 (auth) is implemented.
///
/// TODO(F1-01): delete this constant and wire [myTripsProvider] to the real
/// auth provider (e.g. FirebaseAuth.instance.currentUser?.uid).
const String _mockUserId = '';
