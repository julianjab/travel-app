import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:vamos/core/utils/logger.dart';
import 'package:vamos/data/firebase/firebase_providers.dart';
import 'auth_repository.dart';

/// Firebase / social-SDK implementation of [AuthRepository].
///
/// This is the only file in the auth feature that talks to Firebase Auth
/// and the native sign-in SDKs. Notifiers and widgets only depend on
/// [AuthRepository].
///
/// NOTE (prod): for Google Sign-In to work on Android, the SHA-1 fingerprint
/// of the signing key must be added to the Firebase console under
/// Project Settings → Your apps → Android → SHA certificate fingerprints.
/// Debug SHA-1: run `./gradlew signingReport` inside `app/android/`.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);

  final FirebaseAuth _auth;

  @override
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  @override
  Future<UserCredential> signInWithGoogle() async {
    // Trigger the Google Authentication flow.
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      // The user cancelled the sign-in dialog.
      throw FirebaseAuthException(
        code: 'sign-in-cancelled',
        message: 'El inicio de sesión con Google fue cancelado.',
      );
    }

    // Obtain the Google auth credentials.
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    log.i('Google Sign-In: credential obtained for ${googleUser.email}');
    return _auth.signInWithCredential(credential);
  }

  @override
  Future<UserCredential> signInWithApple() async {
    // Request Apple credentials.
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    // Create an OAuthCredential from the Apple credential.
    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );

    log.i('Apple Sign-In: credential obtained');
    return _auth.signInWithCredential(oauthCredential);
  }

  @override
  Future<void> signOut() async {
    log.i('Signing out');
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }
}

/// Provider that exposes [AuthRepository].
///
/// Consumers depend on the abstract type. The concrete [FirebaseAuthRepository]
/// is wired here. Swap to a mock in tests by overriding this provider.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository(ref.watch(authProvider));
});
