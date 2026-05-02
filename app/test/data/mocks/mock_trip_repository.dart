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
    // Emit the current snapshot synchronously. In tests that use
    // StreamNotifier, this resolves to AsyncValue.data([...]) immediately.
    return Stream.value(List<Trip>.from(_trips));
  }
}
