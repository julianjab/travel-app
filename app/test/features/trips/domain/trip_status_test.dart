import 'package:flutter_test/flutter_test.dart';
import 'package:vamos/features/trips/domain/trip_status.dart';

void main() {
  // Reference trip: 12 Jun – 22 Jun 2026
  final tripStart = DateTime(2026, 6, 12);
  final tripEnd = DateTime(2026, 6, 22);

  TripStatus status({required DateTime now, bool archived = false}) {
    return computeStatus(
      start: tripStart,
      end: tripEnd,
      isArchived: archived,
      now: now,
    );
  }

  group('computeStatus — upcoming', () {
    test('day before start is upcoming', () {
      expect(status(now: DateTime(2026, 6, 11)), TripStatus.upcoming);
    });

    test('far before start is upcoming', () {
      expect(status(now: DateTime(2026, 1, 1)), TripStatus.upcoming);
    });
  });

  group('computeStatus — ongoing', () {
    test('exactly on start day is ongoing', () {
      expect(status(now: DateTime(2026, 6, 12)), TripStatus.ongoing);
    });

    test('middle of trip is ongoing', () {
      expect(status(now: DateTime(2026, 6, 17)), TripStatus.ongoing);
    });

    test('exactly on end day is ongoing', () {
      expect(status(now: DateTime(2026, 6, 22)), TripStatus.ongoing);
    });

    test('time of day on start is still ongoing (hours ignored)', () {
      // Even if "now" has a time component, only the date matters.
      expect(status(now: DateTime(2026, 6, 12, 23, 59)), TripStatus.ongoing);
    });
  });

  group('computeStatus — finished', () {
    test('day after end is finished', () {
      expect(status(now: DateTime(2026, 6, 23)), TripStatus.finished);
    });

    test('far after end is finished', () {
      expect(status(now: DateTime(2026, 12, 31)), TripStatus.finished);
    });
  });

  group('computeStatus — archived', () {
    test('archived flag overrides ongoing dates', () {
      expect(status(now: DateTime(2026, 6, 17), archived: true), TripStatus.archived);
    });

    test('archived flag overrides upcoming dates', () {
      expect(status(now: DateTime(2025, 1, 1), archived: true), TripStatus.archived);
    });

    test('archived flag overrides finished dates', () {
      expect(status(now: DateTime(2027, 1, 1), archived: true), TripStatus.archived);
    });
  });

  group('tripStatusSortKey', () {
    test('ongoing sorts first', () {
      expect(tripStatusSortKey(TripStatus.ongoing), 0);
    });

    test('upcoming sorts second', () {
      expect(tripStatusSortKey(TripStatus.upcoming), 1);
    });

    test('finished sorts third', () {
      expect(tripStatusSortKey(TripStatus.finished), 2);
    });

    test('archived sorts last', () {
      expect(tripStatusSortKey(TripStatus.archived), 3);
    });

    test('ongoing < upcoming < finished < archived (ordering relationship)', () {
      expect(
        tripStatusSortKey(TripStatus.ongoing),
        lessThan(tripStatusSortKey(TripStatus.upcoming)),
      );
      expect(
        tripStatusSortKey(TripStatus.upcoming),
        lessThan(tripStatusSortKey(TripStatus.finished)),
      );
      expect(
        tripStatusSortKey(TripStatus.finished),
        lessThan(tripStatusSortKey(TripStatus.archived)),
      );
    });
  });
}
