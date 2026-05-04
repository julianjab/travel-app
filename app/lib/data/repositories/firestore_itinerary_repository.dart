import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vamos/data/firebase/firebase_providers.dart';
import 'package:vamos/data/models/itinerary_item.dart';
import 'package:vamos/data/repositories/itinerary_repository.dart';

/// Firestore implementation of [ItineraryRepository].
///
/// This is the ONLY file in the app that imports `cloud_firestore` for items.
class FirestoreItineraryRepository implements ItineraryRepository {
  const FirestoreItineraryRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _items(String tripId) =>
      _firestore.collection('trips').doc(tripId).collection('items');

  @override
  Stream<List<ItineraryItem>> watchTripItems(String tripId) {
    return _items(tripId)
        .orderBy('day')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ItineraryItem.fromFirestore(
                  doc as DocumentSnapshot<Map<String, dynamic>>,
                ))
            .toList());
  }

  @override
  Future<void> createItem({
    required String tripId,
    required ItineraryItem item,
  }) async {
    final docRef = _items(tripId).doc(); // auto-generated ID
    await docRef.set(item.toMap());
  }

  @override
  Future<void> updateItem({
    required String tripId,
    required ItineraryItem item,
  }) async {
    await _items(tripId)
        .doc(item.id)
        .update(item.toMap()..['updatedAt'] = Timestamp.now());
  }

  @override
  Future<void> deleteItem({
    required String tripId,
    required String itemId,
  }) async {
    await _items(tripId).doc(itemId).delete();
  }

  @override
  Future<void> castVote({
    required String tripId,
    required String itemId,
    required String userId,
    required String vote,
  }) async {
    await _items(tripId).doc(itemId).update({
      'votes.$userId': vote,
      'updatedAt': Timestamp.now(),
    });
  }
}

// ---------------------------------------------------------------------------
// Riverpod provider
// ---------------------------------------------------------------------------

/// Provides the [ItineraryRepository] implementation.
///
/// Returns the abstract [ItineraryRepository] type. Override in tests/dev mode:
///
/// ```dart
/// ProviderScope(
///   overrides: [
///     itineraryRepositoryProvider.overrideWithValue(MockItineraryRepository()),
///   ],
///   child: MyApp(),
/// )
/// ```
final itineraryRepositoryProvider = Provider<ItineraryRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return FirestoreItineraryRepository(firestore);
});
