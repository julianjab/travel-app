import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vamos/data/repositories/firestore_invite_repository.dart';
import 'package:vamos/features/trips/application/my_trips_notifier.dart';

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

/// Handles the invite-code generation triggered from the success screen (F1.3).
///
/// State is `String?`:
///   - null   → no code generated yet (idle)
///   - String → the 6-char code returned by [InviteRepository.create]
///
/// autoDispose: scoped to the InviteScreen lifecycle; released on pop.
/// family: keyed by [tripId] so the code is tied to a specific trip.
class GenerateInviteNotifier
    extends AutoDisposeFamilyAsyncNotifier<String?, String> {
  @override
  Future<String?> build(String tripId) async {
    // Eagerly generate the code when the screen mounts.
    return _generate(tripId);
  }

  Future<String?> _generate(String tripId) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId.isEmpty) throw StateError('No hay un usuario autenticado.');

    final code =
        await ref.read(inviteRepositoryProvider).create(tripId, userId);
    return code;
  }

  /// Allows the screen to retry if an error occurred.
  Future<void> retry() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _generate(arg));
  }

  /// Revokes the current active invite and generates a fresh code (F1-08).
  ///
  /// Sets [state] to [AsyncLoading] while the batch write is in flight, then
  /// updates to [AsyncData] with the new code (or [AsyncError] on failure).
  /// The UI picks up the new code automatically via the state update.
  Future<void> regenerate() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId.isEmpty) {
      state = AsyncError(
        StateError('No hay un usuario autenticado.'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final newCode = await ref
          .read(inviteRepositoryProvider)
          .revokeAndRegenerate(arg, userId);
      return newCode;
    });
  }
}

/// Riverpod provider for [GenerateInviteNotifier].
///
/// Keyed by [tripId] — the notifier auto-generates the invite on first build.
final generateInviteProvider = AsyncNotifierProvider.autoDispose
    .family<GenerateInviteNotifier, String?, String>(
  GenerateInviteNotifier.new,
);
