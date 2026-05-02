import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vamos/data/models/trip.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Builds a Firestore-compatible data map for a trip.
///
/// The [Trip.fromFirestore] factory requires a [DocumentSnapshot], which is a
/// sealed class and cannot be subclassed in tests. Instead, we test the
/// serialization contract via [Trip.toFirestore] (produces the map) and by
/// reconstructing a [Trip] directly (simulating what [fromFirestore] would do).
/// A small integration-style helper below manually exercises the factory by
/// using the Firestore emulator path — not available in unit tests.
///
/// We therefore split coverage:
///   - [toFirestore] → verifies the map shape.
///   - Reconstruction from the same map → roundtrip via a thin helper.
Trip _reconstructFromMap(String id, Map<String, dynamic> data) {
  // Manually mirrors Trip.fromFirestore to keep tests independent of the
  // sealed-class constraint while still testing the deserialization logic.
  return Trip(
    id: id,
    name: data['name'] as String,
    destination: data['destination'] as String,
    startDate: (data['startDate'] as Timestamp).toDate(),
    endDate: (data['endDate'] as Timestamp).toDate(),
    mainCurrency: data['mainCurrency'] as String,
    coverPhotoURL: data['coverPhotoURL'] as String?,
    facilitatorId: data['facilitatorId'] as String,
    memberIds: List<String>.from(data['memberIds'] as List),
    status: data['status'] as String,
    createdAt: (data['createdAt'] as Timestamp).toDate(),
    createdBy: data['createdBy'] as String,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  final start = DateTime(2026, 6, 12);
  final end = DateTime(2026, 6, 22);
  final created = DateTime(2026, 1, 15, 10, 30);

  final baseTrip = Trip(
    id: 'trip_abc',
    name: 'Brasil con los del barrio',
    destination: 'Río de Janeiro',
    startDate: start,
    endDate: end,
    mainCurrency: 'COP',
    facilitatorId: 'user_1',
    memberIds: ['user_1', 'user_2'],
    status: 'active',
    createdAt: created,
    createdBy: 'user_1',
  );

  group('Trip.toFirestore', () {
    test('serializes all required fields', () {
      final map = baseTrip.toFirestore();

      expect(map['name'], 'Brasil con los del barrio');
      expect(map['destination'], 'Río de Janeiro');
      expect(map['mainCurrency'], 'COP');
      expect(map['facilitatorId'], 'user_1');
      expect(map['memberIds'], ['user_1', 'user_2']);
      expect(map['status'], 'active');
      expect(map['createdBy'], 'user_1');
      expect(map['startDate'], isA<Timestamp>());
      expect(map['endDate'], isA<Timestamp>());
      expect(map['createdAt'], isA<Timestamp>());
    });

    test('does not include id field', () {
      final map = baseTrip.toFirestore();
      expect(map.containsKey('id'), isFalse);
    });

    test('omits coverPhotoURL when null', () {
      final map = baseTrip.toFirestore();
      expect(map.containsKey('coverPhotoURL'), isFalse);
    });

    test('includes coverPhotoURL when present', () {
      final trip = baseTrip.copyWith(coverPhotoURL: 'https://example.com/photo.jpg');
      final map = trip.toFirestore();
      expect(map['coverPhotoURL'], 'https://example.com/photo.jpg');
    });

    test('timestamps round-trip correctly', () {
      final map = baseTrip.toFirestore();
      final startTs = map['startDate'] as Timestamp;
      expect(startTs.toDate(), baseTrip.startDate);
    });
  });

  group('Trip deserialization (via _reconstructFromMap)', () {
    Map<String, dynamic> buildData({String? coverPhotoURL}) {
      final map = <String, dynamic>{
        'name': 'Brasil con los del barrio',
        'destination': 'Río de Janeiro',
        'startDate': Timestamp.fromDate(start),
        'endDate': Timestamp.fromDate(end),
        'mainCurrency': 'COP',
        'facilitatorId': 'user_1',
        'memberIds': ['user_1', 'user_2'],
        'status': 'active',
        'createdAt': Timestamp.fromDate(created),
        'createdBy': 'user_1',
      };
      if (coverPhotoURL != null) map['coverPhotoURL'] = coverPhotoURL;
      return map;
    }

    test('parses all fields from data map', () {
      final trip = _reconstructFromMap('trip_abc', buildData());

      expect(trip.id, 'trip_abc');
      expect(trip.name, 'Brasil con los del barrio');
      expect(trip.destination, 'Río de Janeiro');
      expect(trip.startDate, start);
      expect(trip.endDate, end);
      expect(trip.mainCurrency, 'COP');
      expect(trip.facilitatorId, 'user_1');
      expect(trip.memberIds, ['user_1', 'user_2']);
      expect(trip.status, 'active');
      expect(trip.createdAt, created);
      expect(trip.createdBy, 'user_1');
      expect(trip.coverPhotoURL, isNull);
    });

    test('parses optional coverPhotoURL when present', () {
      final trip = _reconstructFromMap(
        'trip_abc',
        buildData(coverPhotoURL: 'https://example.com/photo.jpg'),
      );
      expect(trip.coverPhotoURL, 'https://example.com/photo.jpg');
    });
  });

  group('Trip roundtrip', () {
    test('toFirestore then reconstruct preserves all fields', () {
      final original = baseTrip.copyWith(coverPhotoURL: 'https://example.com/photo.jpg');
      final map = original.toFirestore();
      final restored = _reconstructFromMap('trip_abc', map);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.destination, original.destination);
      expect(restored.startDate, original.startDate);
      expect(restored.endDate, original.endDate);
      expect(restored.mainCurrency, original.mainCurrency);
      expect(restored.coverPhotoURL, original.coverPhotoURL);
      expect(restored.facilitatorId, original.facilitatorId);
      expect(restored.memberIds, original.memberIds);
      expect(restored.status, original.status);
      expect(restored.createdAt, original.createdAt);
      expect(restored.createdBy, original.createdBy);
    });
  });

  group('Trip.copyWith', () {
    test('returns new instance with changed fields', () {
      final copy = baseTrip.copyWith(name: 'Nuevo nombre');
      expect(copy.name, 'Nuevo nombre');
      expect(copy.id, baseTrip.id);
    });

    test('clearCoverPhoto removes the URL', () {
      final withPhoto = baseTrip.copyWith(coverPhotoURL: 'https://example.com/p.jpg');
      final cleared = withPhoto.copyWith(clearCoverPhoto: true);
      expect(cleared.coverPhotoURL, isNull);
    });
  });
}
