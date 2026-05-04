import 'package:vamos/data/repositories/invite_repository.dart';

/// In-memory [InviteRepository] for tests and dev stubs.
///
/// Returns a fixed fake code ("TEST01") from [create] and [revokeAndRegenerate].
/// Override [fakeCode] in the constructor if a test needs a specific value.
///
/// ```dart
/// final mock = MockInviteRepository(fakeCode: 'ABCDEF');
///
/// await tester.pumpWidget(
///   ProviderScope(
///     overrides: [
///       inviteRepositoryProvider.overrideWithValue(mock),
///     ],
///     child: MaterialApp.router(routerConfig: router),
///   ),
/// );
/// ```
class MockInviteRepository implements InviteRepository {
  MockInviteRepository({this.fakeCode = 'TEST01'});

  /// The code returned by all write operations.
  final String fakeCode;

  /// Maps invite codes to trip IDs for [getTripId] lookups.
  final Map<String, String> _codeToTripId = {};

  @override
  Future<String> create(String tripId, String createdBy) async {
    _codeToTripId[fakeCode] = tripId;
    return fakeCode;
  }

  @override
  Future<String?> getTripId(String code) async {
    return _codeToTripId[code];
  }

  @override
  Future<String> revokeAndRegenerate(String tripId, String createdBy) async {
    _codeToTripId[fakeCode] = tripId;
    return fakeCode;
  }
}
