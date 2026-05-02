import 'package:vamos/data/models/trip.dart';

/// Abstract contract for the trips data source.
///
/// The UI and notifiers depend on this type — never on the concrete Firestore
/// implementation. That makes it trivial to swap the backend, inject a mock in
/// tests, or run a dev-mode stub without Firebase.
///
/// See `app/CLAUDE.md` §"Dependencias y override pattern" for the override
/// contract and how to provide alternative implementations.
abstract class TripRepository {
  /// Streams all active trips the [userId] belongs to, ordered by [startDate].
  ///
  /// Filters: `memberIds array-contains userId` AND `status == "active"`.
  Stream<List<Trip>> watchUserTrips(String userId);
}
