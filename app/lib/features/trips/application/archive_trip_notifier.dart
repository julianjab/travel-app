import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vamos/data/repositories/firestore_trip_repository.dart';

/// Mutation notifier for archiving a trip.
///
/// The facilitator triggers [archive]; the UI listens to state changes
/// to navigate away or show error feedback. Not safe for regular members
/// to call — Firestore rules reject unauthorized writes.
class ArchiveTripNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Sets the trip status to "archived" in Firestore.
  ///
  /// On success, [state] becomes [AsyncData]. On failure (e.g., network
  /// error or Firestore permission denied), [state] becomes [AsyncError].
  Future<void> archive(String tripId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(tripRepositoryProvider).archiveTrip(tripId);
    });
  }
}

final archiveTripProvider =
    AsyncNotifierProvider.autoDispose<ArchiveTripNotifier, void>(
  ArchiveTripNotifier.new,
);
