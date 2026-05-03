import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vamos/features/auth/data/firestore_auth_repository.dart';

// ---------------------------------------------------------------------------
// Auth state stream — global, no autoDispose
// ---------------------------------------------------------------------------

/// Streams the current [User] from Firebase Auth.
///
/// Emits `null` when the user is not signed in.
/// Not autoDispose — the auth state must outlive any individual screen
/// so the router redirect stays alive throughout the app lifecycle.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

// ---------------------------------------------------------------------------
// Sign-in / sign-out actions
// ---------------------------------------------------------------------------

/// Handles Google Sign-In, Apple Sign-In, and Sign-Out mutations.
///
/// Each action sets [state] to [AsyncLoading] while in flight, then to
/// [AsyncData] or [AsyncError] upon completion. The router redirect reacts
/// to [authStateProvider], so there is no need for the screen to navigate
/// manually after a successful sign-in.
///
/// autoDispose: the login screen owns the lifecycle. When the user navigates
/// away (because they are now authenticated), the notifier is disposed.
class AuthActionsNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signInWithGoogle(),
    );
  }

  Future<void> signInWithApple() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signInWithApple(),
    );
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signOut(),
    );
  }
}

final authActionsProvider =
    AsyncNotifierProvider.autoDispose<AuthActionsNotifier, void>(
  AuthActionsNotifier.new,
);
