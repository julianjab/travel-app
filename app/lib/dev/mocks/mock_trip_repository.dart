import 'package:vamos/data/models/trip.dart';
import 'package:vamos/data/repositories/trip_repository.dart';

/// In-memory [TripRepository] for tests and dev stubs.
///
/// Backed by a mutable list. Call [setTrips] before your test to inject the
/// desired fixture set, then override the provider in [ProviderScope]:
///
/// ```dart
/// final mock = MockTripRepository();
/// mock.setTrips([trip1, trip2, trip3]);
///
/// await tester.pumpWidget(
///   ProviderScope(
///     overrides: [
///       tripRepositoryProvider.overrideWithValue(mock),
///     ],
///     child: MaterialApp.router(routerConfig: router),
///   ),
/// );
/// ```
///
/// [watchUserTrips] emits [_trips] once synchronously (via [Stream.value]).
/// Call [setTrips] again to push a new emission if your test mutates state.
class MockTripRepository implements TripRepository {
  final List<Trip> _trips = [];

  /// Replaces the current fixture set. The next subscription to
  /// [watchUserTrips] will emit this list.
  void setTrips(List<Trip> trips) {
    _trips
      ..clear()
      ..addAll(trips);
  }

  @override
  Stream<List<Trip>> watchUserTrips(String userId) {
    return Stream.value(List<Trip>.from(_trips));
  }

  /// Creates a trip in the in-memory store and returns a fake generated ID.
  ///
  /// The [trip] is stored with a fixed fake ID "mock-trip-id" for simplicity.
  /// Override this method if tests need a specific ID or multiple creates.
  @override
  Future<String> create(Trip trip, String facilitatorAlias) async {
    const fakeId = 'mock-trip-id';
    _trips.add(trip.copyWith(id: fakeId));
    return fakeId;
  }

  /// Returns a stream that emits the trip with [tripId] if it exists, or null.
  @override
  Stream<Trip?> watchById(String tripId) {
    final trip = _trips.where((t) => t.id == tripId).firstOrNull;
    return Stream.value(trip);
  }

  /// Archives a trip in the in-memory store by marking its status.
  ///
  /// In the mock, this is a no-op — the status field is not mutated because
  /// [Trip] is immutable and the mock does not push new stream events.
  /// Tests that need to verify archive behavior should override this method.
  @override
  Future<void> archiveTrip(String tripId) async {}
}
