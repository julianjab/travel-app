import 'package:vamos/data/models/itinerary_item.dart';

/// Abstract contract for the itinerary items data source.
///
/// Consumers (notifiers, widgets) depend on this type — never on
/// FirestoreItineraryRepository. See `app/CLAUDE.md` §"Dependencias y override
/// pattern" for the override contract.
abstract class ItineraryRepository {
  /// Streams all items for the trip identified by [tripId], ordered by
  /// [day] ascending then [createdAt] ascending.
  ///
  /// The compound index `(day asc, createdAt asc)` declared in
  /// `firestore.indexes.json` backs this query.
  Stream<List<ItineraryItem>> watchTripItems(String tripId);

  /// Creates a new itinerary item inside [tripId].
  Future<void> createItem({
    required String tripId,
    required ItineraryItem item,
  });

  /// Updates an existing item. Only the author or facilitator may call this.
  /// Enforcement happens in Firestore rules; this method does not re-check.
  Future<void> updateItem({
    required String tripId,
    required ItineraryItem item,
  });

  /// Deletes an item. Only the author or the trip facilitator may call this.
  /// Enforcement happens in Firestore rules.
  Future<void> deleteItem({required String tripId, required String itemId});
}
