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
}
