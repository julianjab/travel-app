import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vamos/data/models/itinerary_item.dart';
import 'package:vamos/data/repositories/firestore_itinerary_repository.dart';

/// Handles one-off mutations on itinerary items: create, update, delete, vote.
///
/// Each method sets state to [AsyncLoading] while the operation is in flight,
/// then to [AsyncData] or [AsyncError] on completion.
class ItemActionsNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> create({
    required String tripId,
    required ItineraryItem item,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(itineraryRepositoryProvider).createItem(
            tripId: tripId,
            item: item,
          );
    });
  }

  Future<void> updateItem({
    required String tripId,
    required ItineraryItem item,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(itineraryRepositoryProvider).updateItem(
            tripId: tripId,
            item: item,
          );
    });
  }

  Future<void> delete({
    required String tripId,
    required String itemId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(itineraryRepositoryProvider).deleteItem(
            tripId: tripId,
            itemId: itemId,
          );
    });
  }

  Future<void> castVote({
    required String tripId,
    required String itemId,
    required String userId,
    required String vote,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(itineraryRepositoryProvider).castVote(
            tripId: tripId,
            itemId: itemId,
            userId: userId,
            vote: vote,
          );
    });
  }
}

final itemActionsProvider =
    AsyncNotifierProvider.autoDispose<ItemActionsNotifier, void>(
  ItemActionsNotifier.new,
);
