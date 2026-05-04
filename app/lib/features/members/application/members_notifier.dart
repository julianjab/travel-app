import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vamos/data/models/member.dart';
import 'package:vamos/data/repositories/firestore_member_repository.dart';

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

/// Streams the members of the trip identified by [tripId] in real time.
///
/// Pattern: [AutoDisposeFamilyStreamNotifier] — the family arg is the tripId.
/// The Firestore listener is released as soon as the screen that owns this
/// notifier is popped from the navigator stack.
class MembersNotifier
    extends AutoDisposeFamilyStreamNotifier<List<Member>, String> {
  @override
  Stream<List<Member>> build(String tripId) {
    return ref.watch(memberRepositoryProvider).watchByTrip(tripId);
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

/// Provides the live member list for a given [tripId].
///
/// Usage:
/// ```dart
/// final members = ref.watch(membersProvider(tripId));
/// ```
final membersProvider = StreamNotifierProvider.autoDispose
    .family<MembersNotifier, List<Member>, String>(MembersNotifier.new);
