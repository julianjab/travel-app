import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vamos/data/firebase/firebase_providers.dart';
import 'package:vamos/data/models/member.dart';
import 'package:vamos/data/repositories/member_repository.dart';

/// Firestore implementation of [MemberRepository].
///
/// This is the ONLY file in the app that imports `cloud_firestore` for members.
/// Widgets, notifiers, and tests never reference this class directly — they
/// depend on the [MemberRepository] abstract type via [memberRepositoryProvider].
///
/// See `app/CLAUDE.md` §Hard rules — rule 1.
class FirestoreMemberRepository implements MemberRepository {
  const FirestoreMemberRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _members(String tripId) =>
      _firestore.collection('trips').doc(tripId).collection('members');

  DocumentReference<Map<String, dynamic>> _trip(String tripId) =>
      _firestore.collection('trips').doc(tripId);

  DocumentReference<Map<String, dynamic>> _invite(String code) =>
      _firestore.collection('invites').doc(code);

  // ---------------------------------------------------------------------------
  // Read
  // ---------------------------------------------------------------------------

  @override
  Stream<List<Member>> watchTripMembers(String tripId) =>
      watchByTrip(tripId);

  @override
  Stream<List<Member>> watchByTrip(String tripId) {
    return _members(tripId).snapshots().map((snap) {
      return snap.docs.map((doc) {
        final data = doc.data();
        return Member(
          userId: doc.id,
          alias: data['alias'] as String,
          tags: Map<String, dynamic>.from(data['tags'] as Map? ?? {}),
          joinedAt: (data['joinedAt'] as Timestamp).toDate(),
        );
      }).toList();
    });
  }

  @override
  Future<Member?> getMember({
    required String tripId,
    required String userId,
  }) async {
    final snap = await _members(tripId).doc(userId).get();
    if (!snap.exists) return null;
    final data = snap.data()!;
    return Member(
      userId: snap.id,
      alias: data['alias'] as String,
      tags: Map<String, dynamic>.from(data['tags'] as Map? ?? {}),
      joinedAt: (data['joinedAt'] as Timestamp).toDate(),
    );
  }

  // ---------------------------------------------------------------------------
  // Write
  // ---------------------------------------------------------------------------

  /// Validates [inviteCode] and atomically registers [member] in the trip.
  ///
  /// Pre-check (outside transaction): reads `invites/{inviteCode}` to verify
  /// `active == true`. This is done outside the transaction deliberately — it
  /// is a read-only guard and Firestore transactions have limited read capacity.
  ///
  /// Transaction (atomic):
  ///   - `arrayUnion` [member.userId] into `trips/{tripId}.memberIds`
  ///   - Write `trips/{tripId}/members/{member.userId}` with alias, tags,
  ///     joinedAt
  ///
  /// Throws [InviteLinkInactiveException] if the invite is inactive or missing.
  @override
  Future<void> joinTrip({
    required String tripId,
    required String inviteCode,
    required Member member,
  }) async {
    // Step 1 — validate invite (outside transaction, read-only guard).
    final inviteSnap = await _invite(inviteCode).get();
    if (!inviteSnap.exists) throw const InviteLinkInactiveException();
    final isActive = inviteSnap.data()?['active'] as bool? ?? false;
    if (!isActive) throw const InviteLinkInactiveException();

    // Step 2 — atomic write: memberIds arrayUnion + member doc.
    await _firestore.runTransaction((tx) async {
      final tripRef = _trip(tripId);
      final memberRef = _members(tripId).doc(member.userId);

      // arrayUnion is safe even if the uid is already present (idempotent).
      tx.update(tripRef, {
        'memberIds': FieldValue.arrayUnion([member.userId]),
      });

      tx.set(memberRef, member.toFirestore());
    });
  }
}

// ---------------------------------------------------------------------------
// Riverpod provider
// ---------------------------------------------------------------------------

/// Provides the [MemberRepository] implementation.
///
/// Returns the abstract [MemberRepository] type. Override in tests/dev mode:
///
/// ```dart
/// ProviderScope(
///   overrides: [
///     memberRepositoryProvider.overrideWithValue(MockMemberRepository()),
///   ],
///   child: MyApp(),
/// )
/// ```
final memberRepositoryProvider = Provider<MemberRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return FirestoreMemberRepository(firestore);
});
