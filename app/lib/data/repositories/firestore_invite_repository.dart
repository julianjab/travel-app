import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vamos/data/firebase/firebase_providers.dart';
import 'package:vamos/data/models/invite.dart';
import 'package:vamos/data/repositories/invite_repository.dart';

/// Firestore implementation of [InviteRepository].
///
/// This is the ONLY file in the app that imports `cloud_firestore` for invites.
/// Widgets, notifiers, and tests never reference this class directly — they
/// depend on the [InviteRepository] abstract type via [inviteRepositoryProvider].
///
/// Code generation charset excludes visually ambiguous characters
/// (0, O, 1, I, L) to prevent read errors when the code is shared verbally.
/// With 30 chars and length 6 → 30^6 = 729 million combinations.
class FirestoreInviteRepository implements InviteRepository {
  const FirestoreInviteRepository(this._firestore);

  final FirebaseFirestore _firestore;

  // Charset excludes: 0, O, 1, I, L for readability when shared verbally.
  static const String _charset = '23456789ABCDEFGHJKMNPQRSTVWXYZ';

  CollectionReference<Map<String, dynamic>> get _invites =>
      _firestore.collection('invites');

  // ---------------------------------------------------------------------------
  // Code generation
  // ---------------------------------------------------------------------------

  String _generateCode() {
    final rng = Random.secure();
    return List.generate(6, (_) => _charset[rng.nextInt(_charset.length)])
        .join();
  }

  // ---------------------------------------------------------------------------
  // Write
  // ---------------------------------------------------------------------------

  /// Creates an invite document at `invites/{code}`.
  ///
  /// Retries up to 3 times on code collision (document already exists).
  /// Throws [StateError] if all 3 attempts fail (should never happen in
  /// practice given 729M possible codes).
  // ---------------------------------------------------------------------------
  // Read
  // ---------------------------------------------------------------------------

  /// Reads `invites/{code}` and returns the trip ID, or null if missing/inactive.
  @override
  Future<String?> getTripId(String code) async {
    final snap = await _invites.doc(code).get();
    if (!snap.exists) return null;
    final data = snap.data()!;
    final isActive = data['active'] as bool? ?? false;
    if (!isActive) return null;
    return data['tripId'] as String?;
  }

  // ---------------------------------------------------------------------------
  // Write
  // ---------------------------------------------------------------------------

  @override
  Future<String> revokeAndRegenerate(String tripId, String createdBy) async {
    // Find the current active invite for this trip.
    final activeSnap = await _invites
        .where('tripId', isEqualTo: tripId)
        .where('active', isEqualTo: true)
        .limit(1)
        .get();

    if (activeSnap.docs.isEmpty) {
      throw StateError(
        'No se encontró un link activo para el viaje $tripId.',
      );
    }

    final existingDoc = activeSnap.docs.first;
    final newCode = _generateCode();
    final newDocRef = _invites.doc(newCode);

    final newInvite = Invite(
      code: newCode,
      tripId: tripId,
      createdBy: createdBy,
      createdAt: DateTime.now(),
      active: true,
    );

    final batch = _firestore.batch();
    // Revoke the existing invite.
    batch.update(existingDoc.reference, {'active': false});
    // Write the new invite.
    batch.set(newDocRef, newInvite.toFirestore());

    await batch.commit();
    return newCode;
  }

  @override
  Future<String> create(String tripId, String createdBy) async {
    const maxRetries = 3;

    for (var attempt = 0; attempt < maxRetries; attempt++) {
      final code = _generateCode();
      final docRef = _invites.doc(code);

      // Use a transaction to atomically check existence + write.
      bool written = false;
      await _firestore.runTransaction((tx) async {
        final snapshot = await tx.get(docRef);
        if (snapshot.exists) return; // collision — retry

        final invite = Invite(
          code: code,
          tripId: tripId,
          createdBy: createdBy,
          createdAt: DateTime.now(),
          active: true,
        );
        tx.set(docRef, invite.toFirestore());
        written = true;
      });

      if (written) return code;
    }

    throw StateError(
      'No se pudo generar un código de invitación único tras $maxRetries intentos.',
    );
  }
}

// ---------------------------------------------------------------------------
// Riverpod provider
// ---------------------------------------------------------------------------

/// Provides the [InviteRepository] implementation.
///
/// Returns the abstract [InviteRepository] type — callers never see
/// [FirestoreInviteRepository]. To override in tests or dev mode:
///
/// ```dart
/// ProviderScope(
///   overrides: [
///     inviteRepositoryProvider.overrideWithValue(MockInviteRepository()),
///   ],
///   child: MyApp(),
/// )
/// ```
///
/// Not autoDispose — the repository is stateless and cheap to keep alive.
final inviteRepositoryProvider = Provider<InviteRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return FirestoreInviteRepository(firestore);
});
