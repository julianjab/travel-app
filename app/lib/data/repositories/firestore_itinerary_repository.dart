import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vamos/data/firebase/firebase_providers.dart';
import 'package:vamos/data/models/itinerary_item.dart';
import 'package:vamos/data/repositories/itinerary_repository.dart';

/// Firestore implementation of [ItineraryRepository].
///
/// This is the ONLY file in the app that imports `cloud_firestore` for items.
/// Skeleton: methods throw [UnimplementedError] until F2.x implements the
/// itinerary flow. The interface is in place so that notifiers can depend on
/// [ItineraryRepository] without coupling to Firebase.
class FirestoreItineraryRepository implements ItineraryRepository {
  const FirestoreItineraryRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _items(String tripId) =>
      _firestore.collection('trips').doc(tripId).collection('items');

  @override
  Stream<List<ItineraryItem>> watchTripItems(String tripId) {
    // TODO(F2-x): implement when the itinerary flow is built.
    throw UnimplementedError('watchTripItems is not yet implemented');
  }

  @override
  Future<void> createItem({
    required String tripId,
    required ItineraryItem item,
  }) async {
    // TODO(F2-x): implement when the itinerary flow is built.
    throw UnimplementedError('createItem is not yet implemented');
  }

  @override
  Future<void> updateItem({
    required String tripId,
    required ItineraryItem item,
  }) async {
    // TODO(F2-x): implement when the itinerary flow is built.
    throw UnimplementedError('updateItem is not yet implemented');
  }

  @override
  Future<void> deleteItem({
    required String tripId,
    required String itemId,
  }) async {
    // TODO(F2-x): implement when the itinerary flow is built.
    throw UnimplementedError('deleteItem is not yet implemented');
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
