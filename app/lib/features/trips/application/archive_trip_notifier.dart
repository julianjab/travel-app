import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vamos/data/repositories/firestore_trip_repository.dart';

/// Mutation notifier for archiving a trip.
///
/// State semantics:
///   AsyncData(null)  → idle (initial; no action taken yet)
///   AsyncLoading()   → archive in progress
///   AsyncData(true)  → archive completed successfully
///   AsyncError(...)  → archive failed
///
/// Using bool? instead of void prevents a false-positive listener trigger.
/// An AutoDisposeAsyncNotifier<void> transitions AsyncLoading → AsyncData
/// when build() completes, so any listener reacting to AsyncData would fire
/// immediately on mount — before the user taps "Archivar". The null sentinel
/// makes the idle state distinguishable from a successful archive.
class ArchiveTripNotifier extends AutoDisposeAsyncNotifier<bool?> {
  @override
  Future<bool?> build() async => null; // null = idle

  /// Sets the trip status to "archived" in Firestore.
  ///
  /// On success, [state] becomes [AsyncData(true)]. On failure (e.g., network
  /// error or Firestore permission denied), [state] becomes [AsyncError].
  Future<void> archive(String tripId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(tripRepositoryProvider).archiveTrip(tripId);
      return true;
    });
  }
}

final archiveTripProvider =
    AsyncNotifierProvider.autoDispose<ArchiveTripNotifier, bool?>(
  ArchiveTripNotifier.new,
);
