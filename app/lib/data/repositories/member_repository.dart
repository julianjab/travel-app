import 'package:vamos/data/models/member.dart';

/// Abstract contract for the trip members data source.
///
/// Consumers (notifiers, widgets) depend on this type — never on
/// FirestoreMemberRepository. See `app/CLAUDE.md` §"Dependencias y override
/// pattern" for the override contract.
abstract class MemberRepository {
  /// Streams all members of the trip identified by [tripId].
  Stream<List<Member>> watchTripMembers(String tripId);

  /// Alias for [watchTripMembers] — used by onboarding screens to confirm
  /// the new member appears in the live list after joining.
  Stream<List<Member>> watchByTrip(String tripId);

  /// Returns the member document for [userId] inside [tripId], or null if
  /// the user is not a member.
  Future<Member?> getMember({required String tripId, required String userId});

  /// Validates the invite code and atomically adds the user as a member.
  ///
  /// Steps:
  ///   1. Read `invites/{inviteCode}` — throws [InviteLinkInactiveException]
  ///      if `active != true`.
  ///   2. In a single Firestore transaction:
  ///      - `arrayUnion` [member.userId] into `trips/{tripId}.memberIds`
  ///      - Write `trips/{tripId}/members/{member.userId}` with alias, tags,
  ///        joinedAt.
  ///
  /// The [tripId] must match the one stored in the invite document; it is read
  /// from Firestore to avoid trusting a client-provided value.
  Future<void> joinTrip({
    required String tripId,
    required String inviteCode,
    required Member member,
  });
}

/// Thrown when an invite link is no longer active (revoked by facilitator
/// or already used by a different flow).
class InviteLinkInactiveException implements Exception {
  const InviteLinkInactiveException();

  @override
  String toString() => 'InviteLinkInactiveException: el link ya no está activo';
}
