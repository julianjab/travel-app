import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vamos/data/models/trip.dart';

// ---------------------------------------------------------------------------
// Helpers — fake Firestore snapshot
// ---------------------------------------------------------------------------

/// A minimal stand-in for DocumentSnapshot that satisfies [Trip.fromFirestore].
/// We only care about [id] and [data]; all other snapshot methods are unused.
class _FakeDoc implements DocumentSnapshot<Map<String, dynamic>> {
  _FakeDoc(this.id, this._data);

  @override
  final String id;
  final Map<String, dynamic> _data;

  @override
  Map<String, dynamic>? data() => _data;

  // ---- unused snapshot members (required by interface) ----
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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

  group('Trip.fromFirestore', () {
    Map<String, dynamic> buildData({String? coverPhotoURL}) => {
          'name': 'Brasil con los del barrio',
          'destination': 'Río de Janeiro',
          'startDate': Timestamp.fromDate(start),
          'endDate': Timestamp.fromDate(end),
          'mainCurrency': 'COP',
          if (coverPhotoURL != null) 'coverPhotoURL': coverPhotoURL,
          'facilitatorId': 'user_1',
          'memberIds': ['user_1', 'user_2'],
          'status': 'active',
          'createdAt': Timestamp.fromDate(created),
          'createdBy': 'user_1',
        };

    test('parses all fields from snapshot', () {
      final doc = _FakeDoc('trip_abc', buildData());
      final trip = Trip.fromFirestore(doc);

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
      final doc = _FakeDoc(
        'trip_abc',
        buildData(coverPhotoURL: 'https://example.com/photo.jpg'),
      );
      final trip = Trip.fromFirestore(doc);
      expect(trip.coverPhotoURL, 'https://example.com/photo.jpg');
    });
  });

  group('Trip roundtrip', () {
    test('toFirestore then fromFirestore preserves all fields', () {
      final original = baseTrip.copyWith(coverPhotoURL: 'https://example.com/photo.jpg');
      final map = original.toFirestore();
      final doc = _FakeDoc('trip_abc', map);
      final restored = Trip.fromFirestore(doc);

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
