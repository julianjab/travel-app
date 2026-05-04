import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vamos/data/firebase/firebase_providers.dart';
import 'package:vamos/data/repositories/user_repository.dart';

/// Firestore implementation of [UserRepository].
///
/// This is the ONLY file in the app that imports `cloud_firestore` for users.
/// Widgets, notifiers, and tests never reference this class directly — they
/// depend on the [UserRepository] abstract type via [userRepositoryProvider].
///
/// See `app/CLAUDE.md` §Hard rules — rule 1.
class FirestoreUserRepository implements UserRepository {
  const FirestoreUserRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  // ---------------------------------------------------------------------------
  // Read
  // ---------------------------------------------------------------------------

  /// Returns true if the `users/{userId}` document exists in Firestore.
  ///
  /// A single document get is used instead of a stream — this is a one-shot
  /// check during onboarding, not a live listener.
  @override
  Future<bool> profileExists(String userId) async {
    final snap = await _users.doc(userId).get();
    return snap.exists;
  }

  // ---------------------------------------------------------------------------
  // Write
  // ---------------------------------------------------------------------------

  /// Creates or overwrites the `users/{userId}` document.
  ///
  /// Uses [SetOptions.merge] so that a concurrent call (e.g., from a retry)
  /// does not wipe out future fields added by later schema versions.
  @override
  Future<void> saveProfile({
    required String userId,
    required String displayName,
    String? photoURL,
  }) async {
    final data = <String, dynamic>{
      'displayName': displayName,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (photoURL != null) data['photoURL'] = photoURL;

    await _users.doc(userId).set(data, SetOptions(merge: true));
  }
}

// ---------------------------------------------------------------------------
// Riverpod provider
// ---------------------------------------------------------------------------

/// Provides the [UserRepository] implementation.
///
/// Returns the abstract [UserRepository] type — callers never see
/// [FirestoreUserRepository]. To override in tests or dev mode:
///
/// ```dart
/// ProviderScope(
///   overrides: [
///     userRepositoryProvider.overrideWithValue(MockUserRepository()),
///   ],
///   child: MyApp(),
/// )
/// ```
///
/// Not autoDispose — the repository is stateless and cheap to keep alive.
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return FirestoreUserRepository(firestore);
});
