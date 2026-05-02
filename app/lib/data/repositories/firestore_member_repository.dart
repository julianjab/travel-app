import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vamos/data/firebase/firebase_providers.dart';
import 'package:vamos/data/models/member.dart';
import 'package:vamos/data/repositories/member_repository.dart';

/// Firestore implementation of [MemberRepository].
///
/// This is the ONLY file in the app that imports `cloud_firestore` for members.
/// Skeleton: methods throw [UnimplementedError] until F1.x implements the
/// members flow. The interface is in place so that other repos and notifiers
/// can depend on [MemberRepository] without coupling to Firebase.
class FirestoreMemberRepository implements MemberRepository {
  const FirestoreMemberRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _members(String tripId) =>
      _firestore.collection('trips').doc(tripId).collection('members');

  @override
  Stream<List<Member>> watchTripMembers(String tripId) {
    // TODO(F1-x): implement when the members flow is built.
    throw UnimplementedError('watchTripMembers is not yet implemented');
  }

  @override
  Future<Member?> getMember({
    required String tripId,
    required String userId,
  }) async {
    // TODO(F1-x): implement when the members flow is built.
    throw UnimplementedError('getMember is not yet implemented');
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
