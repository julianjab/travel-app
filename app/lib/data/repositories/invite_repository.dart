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
}
