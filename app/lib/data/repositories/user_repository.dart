/// Abstract contract for the users data source.
///
/// The UI and notifiers depend on this type — never on the concrete Firestore
/// implementation. See `app/CLAUDE.md` §"Dependencias y override pattern".
abstract class UserRepository {
  /// Returns true if the `users/{userId}` document already exists in Firestore.
  ///
  /// Used during onboarding (F1.4) to decide whether to show the profile-setup
  /// screen (new user) or skip directly to the alias screen (returning user).
  Future<bool> profileExists(String userId);

  /// Creates or overwrites the `users/{userId}` document with the provided
  /// display name (and optional photo URL).
  ///
  /// Called once when a new user completes the profile step (F1.4). Safe to
  /// call multiple times — it is a set (not an update), so it is idempotent.
  Future<void> saveProfile({
    required String userId,
    required String displayName,
    String? photoURL,
  });
}
