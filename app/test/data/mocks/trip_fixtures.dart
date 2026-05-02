import 'package:vamos/data/models/trip.dart';

/// Shared trip fixtures for tests and the dev entry point (main_dev.dart).
///
/// All dates are relative to [DateTime.now()] so the fixtures remain valid
/// regardless of when tests run. Do not use fixed calendar dates here.
abstract class TripFixtures {
  /// An ongoing trip: started 3 days ago, ends in 7 days.
  static Trip ongoing({String id = 'trip_ongoing'}) {
    final now = DateTime.now();
    return Trip(
      id: id,
      name: 'Brasil con los del barrio',
      destination: 'Río de Janeiro',
      startDate: now.subtract(const Duration(days: 3)),
      endDate: now.add(const Duration(days: 7)),
      mainCurrency: 'COP',
      facilitatorId: 'user_1',
      memberIds: ['user_1', 'user_2', 'user_3'],
      status: 'active',
      createdAt: now.subtract(const Duration(days: 30)),
      createdBy: 'user_1',
    );
  }

  /// An upcoming trip: starts in 60 days.
  static Trip upcoming({String id = 'trip_upcoming'}) {
    final now = DateTime.now();
    return Trip(
      id: id,
      name: 'Patagonia express',
      destination: 'Bariloche',
      startDate: now.add(const Duration(days: 60)),
      endDate: now.add(const Duration(days: 70)),
      mainCurrency: 'ARS',
      facilitatorId: 'user_2',
      memberIds: ['user_1', 'user_2'],
      status: 'active',
      createdAt: now.subtract(const Duration(days: 10)),
      createdBy: 'user_2',
    );
  }

  /// A finished trip: ended 20 days ago.
  static Trip finished({String id = 'trip_finished'}) {
    final now = DateTime.now();
    return Trip(
      id: id,
      name: 'CDMX crew',
      destination: 'Ciudad de México',
      startDate: now.subtract(const Duration(days: 30)),
      endDate: now.subtract(const Duration(days: 20)),
      mainCurrency: 'MXN',
      facilitatorId: 'user_3',
      memberIds: ['user_1', 'user_3'],
      status: 'active',
      createdAt: now.subtract(const Duration(days: 60)),
      createdBy: 'user_3',
    );
  }

  /// All three fixtures in the canonical status-sort order:
  /// ongoing → upcoming → finished.
  static List<Trip> sortedSet() => [ongoing(), upcoming(), finished()];
}
