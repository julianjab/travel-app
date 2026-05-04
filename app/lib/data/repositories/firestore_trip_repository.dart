import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vamos/data/firebase/firebase_providers.dart';
import 'package:vamos/data/models/member.dart';
import 'package:vamos/data/models/trip.dart';
import 'package:vamos/data/repositories/trip_repository.dart';

/// Firestore implementation of [TripRepository].
///
/// This is the ONLY file in the app that imports `cloud_firestore` for trips.
/// Widgets, notifiers, and tests never reference this class directly — they
/// depend on the [TripRepository] abstract type via [tripRepositoryProvider].
///
/// See `app/CLAUDE.md` §Hard rules — rule 1.
class FirestoreTripRepository implements TripRepository {
  const FirestoreTripRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _trips =>
      _firestore.collection('trips');

  // ---------------------------------------------------------------------------
  // Write
  // ---------------------------------------------------------------------------

  /// Creates a new trip and registers the facilitator as the first member.
  ///
  /// Uses a [WriteBatch] to atomically write both documents:
  ///   - `trips/{tripId}` with the serialized [trip]
  ///   - `trips/{tripId}/members/{facilitatorId}` with the facilitator member
  ///
  /// The [memberIds] array inside the trip doc MUST include the facilitator's
  /// uid so [watchUserTrips] (which filters by `array-contains userId`) picks
  /// up the trip immediately.
  ///
  /// Returns the generated [tripId] on success.
  @override
  Future<String> create(Trip trip, String facilitatorAlias) async {
    final tripRef = _trips.doc(); // auto-generated ID

    final facilitatorMember = Member(
      userId: trip.facilitatorId,
      alias: facilitatorAlias,
      tags: const {},
      joinedAt: trip.createdAt,
    );

    final batch = _firestore.batch();
    batch.set(tripRef, trip.toFirestore());
    batch.set(
      tripRef.collection('members').doc(trip.facilitatorId),
      facilitatorMember.toFirestore(),
    );

    await batch.commit();
    return tripRef.id;
  }

  /// Sets the trip's status field to "archived".
  ///
  /// Firestore security rules enforce that only the facilitator may write this
  /// field. Callers are responsible for confirming before calling.
  @override
  Future<void> archiveTrip(String tripId) async {
    await _trips.doc(tripId).update({'status': 'archived'});
  }

  // ---------------------------------------------------------------------------
  // Read
  // ---------------------------------------------------------------------------

  /// Streams the single trip document at `trips/{tripId}`.
  ///
  /// Emits null if the document does not exist (e.g., was deleted).
  @override
  Stream<Trip?> watchById(String tripId) {
    return _trips.doc(tripId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return Trip.fromFirestore(snap);
    });
  }

  /// Streams all active trips the [userId] belongs to, ordered by [startDate].
  ///
  /// Filters: `memberIds array-contains userId` AND `status == "active"`.
  /// Sorting by [startDate] ascending is done in Firestore using the compound
  /// index declared in `firestore.indexes.json`
  /// (`memberIds array-contains, status, startDate desc`).
  ///
  /// The notifier ([MyTripsNotifier]) applies the in-memory sort that groups by
  /// computed status (ongoing → upcoming → finished → archived) because that
  /// ordering depends on the current date, which Firestore cannot compute.
  @override
  Stream<List<Trip>> watchUserTrips(String userId) {
    return _trips
        .where('memberIds', arrayContains: userId)
        .where('status', isEqualTo: 'active')
        .orderBy('startDate')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Trip.fromFirestore(
                  doc as DocumentSnapshot<Map<String, dynamic>>,
                ))
            .toList());
  }
}

// ---------------------------------------------------------------------------
// Riverpod provider
// ---------------------------------------------------------------------------

/// Provides the [TripRepository] implementation.
///
/// Returns the abstract [TripRepository] type — callers never see
/// [FirestoreTripRepository]. To override in tests or dev mode:
///
/// ```dart
/// ProviderScope(
///   overrides: [
///     tripRepositoryProvider.overrideWithValue(MockTripRepository()),
///   ],
///   child: MyApp(),
/// )
/// ```
///
/// Not autoDispose — the repository is stateless and cheap to keep alive.
final tripRepositoryProvider = Provider<TripRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return FirestoreTripRepository(firestore);
});
