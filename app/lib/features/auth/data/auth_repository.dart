import 'package:firebase_auth/firebase_auth.dart';

/// Contract for the auth layer.
///
/// The UI layer never touches Firebase directly — all auth operations are
/// channelled through this interface. The concrete [FirestoreAuthRepository]
/// (in `firestore_auth_repository.dart`) is the only file that imports
/// `firebase_auth` for actual sign-in calls.
abstract class AuthRepository {
  /// Stream that emits whenever the auth state changes.
  ///
  /// Emits [User] when the user is signed in, `null` when signed out.
  Stream<User?> authStateChanges();

  /// Sign in with a Google account.
  ///
  /// Throws [FirebaseAuthException] on failure.
  Future<UserCredential> signInWithGoogle();

  /// Sign in with an Apple account.
  ///
  /// Throws [SignInWithAppleException] or [FirebaseAuthException] on failure.
  Future<UserCredential> signInWithApple();

  /// Sign out the current user from Firebase and the social provider.
  Future<void> signOut();
}
