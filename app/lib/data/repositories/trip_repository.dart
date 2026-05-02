import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vamos/data/firebase/firebase_providers.dart';
import 'package:vamos/data/models/trip.dart';

/// The only place in the codebase that reads/writes the `trips` collection.
///
/// Widgets and notifiers never import `cloud_firestore` directly —
/// they go through this repository. See `app/CLAUDE.md` §Hard rules.
class TripRepository {
  const TripRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _trips =>
      _firestore.collection('trips');

  // ---------------------------------------------------------------------------
  // Read
  // ---------------------------------------------------------------------------

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

/// Provides the singleton [TripRepository].
///
/// Not autoDispose — the repository is stateless and cheap to keep alive.
final tripRepositoryProvider = Provider<TripRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return TripRepository(firestore);
});
