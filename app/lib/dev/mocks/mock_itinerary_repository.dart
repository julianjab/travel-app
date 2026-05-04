import 'package:vamos/data/models/itinerary_item.dart';
import 'package:vamos/data/repositories/itinerary_repository.dart';

/// In-memory [ItineraryRepository] for tests and dev stubs.
///
/// Backed by a mutable list. Call [setItems] before your test to inject
/// the desired fixture set, then override the provider in [ProviderScope]:
///
/// ```dart
/// final mock = MockItineraryRepository();
/// mock.setItems([item1, item2]);
///
/// await tester.pumpWidget(
///   ProviderScope(
///     overrides: [
///       itineraryRepositoryProvider.overrideWithValue(mock),
///     ],
///     child: MaterialApp.router(routerConfig: router),
///   ),
/// );
/// ```
///
/// [watchTripItems] emits [_items] once synchronously.
class MockItineraryRepository implements ItineraryRepository {
  final List<ItineraryItem> _items = [];

  /// Replaces the current fixture set.
  void setItems(List<ItineraryItem> items) {
    _items
      ..clear()
      ..addAll(items);
  }

  @override
  Stream<List<ItineraryItem>> watchTripItems(String tripId) {
    return Stream.value(List<ItineraryItem>.from(_items));
  }

  @override
  Future<void> createItem({
    required String tripId,
    required ItineraryItem item,
  }) async {
    _items.add(item);
  }

  @override
  Future<void> updateItem({
    required String tripId,
    required ItineraryItem item,
  }) async {
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _items[index] = item;
    }
  }

  @override
  Future<void> deleteItem({
    required String tripId,
    required String itemId,
  }) async {
    _items.removeWhere((i) => i.id == itemId);
  }

  /// No-op vote — mock does not track vote state.
  @override
  Future<void> castVote({
    required String tripId,
    required String itemId,
    required String userId,
    required String vote,
  }) async {}
}
