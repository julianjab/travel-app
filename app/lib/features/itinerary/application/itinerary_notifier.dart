import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vamos/data/models/itinerary_item.dart';
import 'package:vamos/data/repositories/firestore_itinerary_repository.dart';

/// Streams all itinerary items for a given trip, ordered by day then createdAt.
///
/// Uses [AutoDisposeFamilyStreamNotifier] so the listener is released when the
/// screen that owns this provider is disposed.
class ItineraryNotifier
    extends AutoDisposeFamilyStreamNotifier<List<ItineraryItem>, String> {
  @override
  Stream<List<ItineraryItem>> build(String tripId) {
    return ref.watch(itineraryRepositoryProvider).watchTripItems(tripId);
  }
}

final itineraryProvider = StreamNotifierProvider.autoDispose
    .family<ItineraryNotifier, List<ItineraryItem>, String>(
  ItineraryNotifier.new,
);
