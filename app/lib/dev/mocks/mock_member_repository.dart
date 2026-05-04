import 'package:vamos/data/models/member.dart';
import 'package:vamos/data/repositories/member_repository.dart';

/// In-memory [MemberRepository] for tests and dev stubs.
///
/// Backed by a mutable list. Call [setMembers] before your test to inject
/// the desired fixture set, then override the provider in [ProviderScope]:
///
/// ```dart
/// final mock = MockMemberRepository();
/// mock.setMembers([member1, member2]);
///
/// await tester.pumpWidget(
///   ProviderScope(
///     overrides: [
///       memberRepositoryProvider.overrideWithValue(mock),
///     ],
///     child: MaterialApp.router(routerConfig: router),
///   ),
/// );
/// ```
///
/// [watchTripMembers] and [watchByTrip] both emit [_members] once synchronously.
class MockMemberRepository implements MemberRepository {
  final List<Member> _members = [];

  /// Replaces the current fixture set.
  void setMembers(List<Member> members) {
    _members
      ..clear()
      ..addAll(members);
  }

  @override
  Stream<List<Member>> watchTripMembers(String tripId) {
    return Stream.value(List<Member>.from(_members));
  }

  @override
  Stream<List<Member>> watchByTrip(String tripId) {
    return Stream.value(List<Member>.from(_members));
  }

  @override
  Future<Member?> getMember({
    required String tripId,
    required String userId,
  }) async {
    return _members.where((m) => m.userId == userId).firstOrNull;
  }

  /// No-op join — mock does not enforce invite validation.
  @override
  Future<void> joinTrip({
    required String tripId,
    required String inviteCode,
    required Member member,
  }) async {
    if (!_members.any((m) => m.userId == member.userId)) {
      _members.add(member);
    }
  }
}
