/// Mirrors the `trips/{tripId}/members/{userId}` Firestore document.
///
/// See `docs/05-modelo-datos-2.md` §2.2 for the canonical schema.
/// The [userId] is the Firestore document ID (not stored inside the document).
class Member {
  const Member({
    required this.userId,
    required this.alias,
    required this.tags,
    required this.joinedAt,
  });

  /// The Firestore document ID — same as the Firebase Auth UID.
  final String userId;

  /// Alias specific to this trip (may differ from the global user alias).
  final String alias;

  /// Member preference tags. Keys: "diet", "pace", "budget".
  /// See `docs/05-modelo-datos-2.md` §2.2 for valid values.
  final Map<String, dynamic> tags;

  final DateTime joinedAt;

  Member copyWith({
    String? userId,
    String? alias,
    Map<String, dynamic>? tags,
    DateTime? joinedAt,
  }) {
    return Member(
      userId: userId ?? this.userId,
      alias: alias ?? this.alias,
      tags: tags ?? this.tags,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Member &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          alias == other.alias &&
          joinedAt == other.joinedAt;

  @override
  int get hashCode => Object.hash(userId, alias, joinedAt);
}
