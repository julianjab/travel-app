import 'package:flutter_test/flutter_test.dart';
import 'package:vamos/data/models/trip.dart';
import 'package:vamos/dev/mocks/mock_trip_repository.dart';

// Unit tests for MockTripRepository covering the X-11 contract:
//   - create() round-trips memberAliases.
//   - addMember() extends both memberIds and memberAliases atomically and
//     keeps the invariant `memberAliases.length == memberIds.length`.

Trip _baseTrip({
  String id = 'trip_1',
  List<String> members = const ['user_1'],
  Map<String, String> aliases = const {'user_1': 'Andrés'},
}) {
  final now = DateTime(2026, 1, 1);
  return Trip(
    id: id,
    name: 'Test',
    destination: 'Río',
    startDate: now,
    endDate: now.add(const Duration(days: 5)),
    mainCurrency: 'COP',
    facilitatorId: members.first,
    memberIds: members,
    memberAliases: aliases,
    status: 'active',
    createdAt: now,
    createdBy: members.first,
  );
}

void main() {
  group('MockTripRepository.create', () {
    test('persists memberAliases passed in the trip', () async {
      final mock = MockTripRepository();
      final trip = _baseTrip();

      await mock.create(trip, 'Andrés');
      final stored = await mock.watchUserTrips('user_1').first;

      expect(stored.single.memberAliases, {'user_1': 'Andrés'});
    });
  });

  group('MockTripRepository.addMember', () {
    test('extends memberIds and memberAliases together', () async {
      final mock = MockTripRepository()..setTrips([_baseTrip()]);

      await mock.addMember(
        tripId: 'trip_1',
        userId: 'user_2',
        alias: 'Mati',
      );

      final stored = await mock.watchUserTrips('user_1').first;
      expect(stored.single.memberIds, ['user_1', 'user_2']);
      expect(stored.single.memberAliases, {
        'user_1': 'Andrés',
        'user_2': 'Mati',
      });
    });

    test('keeps invariant memberAliases.length == memberIds.length', () async {
      final mock = MockTripRepository()..setTrips([_baseTrip()]);

      await mock.addMember(
        tripId: 'trip_1',
        userId: 'user_2',
        alias: 'Mati',
      );
      await mock.addMember(
        tripId: 'trip_1',
        userId: 'user_3',
        alias: 'Cami',
      );

      final stored = (await mock.watchUserTrips('user_1').first).single;
      expect(stored.memberAliases.length, stored.memberIds.length);
    });

    test('is idempotent for an already-registered member', () async {
      final mock = MockTripRepository()..setTrips([_baseTrip()]);

      await mock.addMember(
        tripId: 'trip_1',
        userId: 'user_1',
        alias: 'Andrés v2',
      );

      final stored = (await mock.watchUserTrips('user_1').first).single;
      // Existing entry is preserved — second join is a no-op for the mock.
      expect(stored.memberIds, ['user_1']);
      expect(stored.memberAliases, {'user_1': 'Andrés'});
    });
  });
}
