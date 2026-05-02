import 'package:vamos/data/models/member.dart';

/// Abstract contract for the trip members data source.
///
/// Consumers (notifiers, widgets) depend on this type — never on
/// FirestoreMemberRepository. See `app/CLAUDE.md` §"Dependencias y override
/// pattern" for the override contract.
abstract class MemberRepository {
  /// Streams all members of the trip identified by [tripId].
  Stream<List<Member>> watchTripMembers(String tripId);

  /// Returns the member document for [userId] inside [tripId], or null if
  /// the user is not a member.
  Future<Member?> getMember({required String tripId, required String userId});
}
