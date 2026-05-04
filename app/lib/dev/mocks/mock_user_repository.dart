import 'package:vamos/data/repositories/user_repository.dart';

/// In-memory [UserRepository] for tests and dev stubs.
///
/// [profileExists] returns [_profileExists] (true by default — skips the
/// profile-setup screen in the join flow). Call [setProfileExists] if a test
/// needs to simulate a new user.
///
/// ```dart
/// final mock = MockUserRepository();
///
/// await tester.pumpWidget(
///   ProviderScope(
///     overrides: [
///       userRepositoryProvider.overrideWithValue(mock),
///     ],
///     child: MaterialApp.router(routerConfig: router),
///   ),
/// );
/// ```
class MockUserRepository implements UserRepository {
  MockUserRepository({bool profileExists = true})
      : _profileExists = profileExists;

  bool _profileExists;

  /// Overrides the return value of [profileExists].
  void setProfileExists(bool exists) => _profileExists = exists;

  @override
  Future<bool> profileExists(String userId) async => _profileExists;

  @override
  Future<void> saveProfile({
    required String userId,
    required String displayName,
    String? photoURL,
  }) async {}
}
