import 'package:cloud_firestore/cloud_firestore.dart';

/// Mirrors the `invites/{code}` Firestore document.
///
/// See `docs/05-modelo-datos-2.md` for the canonical schema.
/// The [code] is the Firestore document ID — it doubles as the URL slug
/// (`vamos.app/j/{code}`) and is NOT stored inside the document itself.
class Invite {
  const Invite({
    required this.code,
    required this.tripId,
    required this.createdBy,
    required this.createdAt,
    required this.active,
  });

  /// 6-character invite code, also the Firestore document ID.
  final String code;
  final String tripId;
  final String createdBy;
  final DateTime createdAt;

  /// False when the facilitator has revoked the link (F1-08, not in MVP).
  final bool active;

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------

  /// Creates an [Invite] from a Firestore [DocumentSnapshot].
  factory Invite.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Invite(
      code: doc.id,
      tripId: data['tripId'] as String,
      createdBy: data['createdBy'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      active: data['active'] as bool,
    );
  }

  /// Serializes to a Firestore-compatible map.
  /// The document [code] is NOT included — it lives as the document key.
  Map<String, dynamic> toFirestore() {
    return {
      'tripId': tripId,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'active': active,
    };
  }
}
