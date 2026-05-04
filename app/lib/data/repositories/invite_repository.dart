/// Abstract contract for the invites data source.
///
/// The UI and notifiers depend on this type — never on the concrete Firestore
/// implementation. See `app/CLAUDE.md` §"Dependencias y override pattern".
abstract class InviteRepository {
  /// Generates a unique 6-character invite code, writes the invite document
  /// to `invites/{code}`, and returns the code on success.
  ///
  /// Retries up to 3 times on the (extremely unlikely) event of a code
  /// collision in Firestore.
  Future<String> create(String tripId, String createdBy);

  /// Reads `invites/{code}` and returns the associated [tripId], or null if
  /// the document does not exist or is inactive (`active == false`).
  ///
  /// Used by [JoinEntryScreen] to resolve the invite code from the deep link
  /// into the Firestore trip ID before starting the onboarding flow.
  Future<String?> getTripId(String code);

  /// Revokes the current active invite for [tripId] and generates a new one.
  ///
  /// In a single [WriteBatch]:
  ///   1. Finds the active invite document for [tripId].
  ///   2. Sets `active: false` on that document.
  ///   3. Writes a new invite document with a fresh 6-char code.
  ///
  /// Returns the newly generated invite code.
  /// Throws [StateError] if no active invite is found for [tripId].
  Future<String> revokeAndRegenerate(String tripId, String createdBy);
}
