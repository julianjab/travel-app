import 'dart:math';

import 'package:vamos/data/models/trip.dart';

/// Fake trip data for the dev entry point and widget tests.
///
/// Uses curated LATAM data + [Random] so each run (or test) gets varied names,
/// destinations, and group compositions. Dates are always relative to
/// [DateTime.now] so fixtures never go stale.
abstract class TripFixtures {
  static final _rng = Random();

  // ---------------------------------------------------------------------------
  // Curated data pools
  // ---------------------------------------------------------------------------

  static const _destinations = [
    'Río de Janeiro, Brasil',
    'Buenos Aires, Argentina',
    'Ciudad de México, México',
    'Cartagena, Colombia',
    'Lima, Perú',
    'Santiago, Chile',
    'Medellín, Colombia',
    'Cancún, México',
    'Montevideo, Uruguay',
    'Cusco, Perú',
    'Florianópolis, Brasil',
    'Punta Cana, Rep. Dominicana',
    'Quito, Ecuador',
    'La Habana, Cuba',
    'Bogotá, Colombia',
    'São Paulo, Brasil',
    'Oaxaca, México',
    'Punta del Este, Uruguay',
    'Arequipa, Perú',
    'Barranquilla, Colombia',
  ];

  static const _tripNames = [
    'Los del barrio',
    'Crew de la u',
    'Viaje de promo',
    'El team de siempre',
    'Vacas del trabajo',
    'Los primos y más',
    'Aniversario gang',
    'Fin de año squad',
    'Mochileros 2025',
    'El plan de Año Nuevo',
    'La última del año',
    'Road trip LATAM',
    'Los del gym',
    'Familia extendida',
    'El reencuentro',
  ];

  static const _currencies = ['COP', 'MXN', 'ARS', 'BRL', 'PEN', 'CLP', 'UYU'];

  static const _userIds = [
    'user_ana',
    'user_carlos',
    'user_diana',
    'user_edgar',
    'user_fabi',
    'user_gabo',
    'user_hector',
    'user_ivan',
  ];

  // ---------------------------------------------------------------------------
  // Typed factories
  // ---------------------------------------------------------------------------

  /// An ongoing trip: started [daysAgo] days ago, ends in [daysLeft] days.
  static Trip ongoing({
    String? id,
    int daysAgo = 3,
    int daysLeft = 7,
  }) {
    final now = DateTime.now();
    final members = _pickMembers();
    return Trip(
      id: id ?? 'trip_ongoing_${_rng.nextInt(9999)}',
      name: '${_pick(_tripNames)} · ${_pick(_destinations).split(',')[0]}',
      destination: _pick(_destinations),
      startDate: now.subtract(Duration(days: daysAgo)),
      endDate: now.add(Duration(days: daysLeft)),
      mainCurrency: _pick(_currencies),
      facilitatorId: members.first,
      memberIds: members,
      status: 'active',
      createdAt: now.subtract(Duration(days: daysAgo + 10)),
      createdBy: members.first,
    );
  }

  /// An upcoming trip: starts in [daysAhead] days.
  static Trip upcoming({
    String? id,
    int daysAhead = 45,
  }) {
    final now = DateTime.now();
    final members = _pickMembers();
    return Trip(
      id: id ?? 'trip_upcoming_${_rng.nextInt(9999)}',
      name: '${_pick(_tripNames)} · ${_pick(_destinations).split(',')[0]}',
      destination: _pick(_destinations),
      startDate: now.add(Duration(days: daysAhead)),
      endDate: now.add(Duration(days: daysAhead + 10)),
      mainCurrency: _pick(_currencies),
      facilitatorId: members.first,
      memberIds: members,
      status: 'active',
      createdAt: now.subtract(const Duration(days: 7)),
      createdBy: members.first,
    );
  }

  /// A finished trip: ended [daysAgo] days ago.
  static Trip finished({
    String? id,
    int daysAgo = 20,
  }) {
    final now = DateTime.now();
    final members = _pickMembers();
    return Trip(
      id: id ?? 'trip_finished_${_rng.nextInt(9999)}',
      name: '${_pick(_tripNames)} · ${_pick(_destinations).split(',')[0]}',
      destination: _pick(_destinations),
      startDate: now.subtract(Duration(days: daysAgo + 10)),
      endDate: now.subtract(Duration(days: daysAgo)),
      mainCurrency: _pick(_currencies),
      facilitatorId: members.first,
      memberIds: members,
      status: 'active',
      createdAt: now.subtract(Duration(days: daysAgo + 40)),
      createdBy: members.first,
    );
  }

  // ---------------------------------------------------------------------------
  // Composite sets
  // ---------------------------------------------------------------------------

  /// One of each status type — canonical order for the Mis viajes list.
  static List<Trip> sortedSet() => [ongoing(), upcoming(), finished()];

  /// [count] random trips with mixed statuses.
  static List<Trip> random(int count) {
    const statuses = [_TripStatus.ongoing, _TripStatus.upcoming, _TripStatus.finished];
    return List.generate(count, (i) {
      final status = statuses[_rng.nextInt(statuses.length)];
      return switch (status) {
        _TripStatus.ongoing => ongoing(daysAgo: _rng.nextInt(10) + 1, daysLeft: _rng.nextInt(15) + 3),
        _TripStatus.upcoming => upcoming(daysAhead: _rng.nextInt(90) + 10),
        _TripStatus.finished => finished(daysAgo: _rng.nextInt(60) + 5),
      };
    });
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static T _pick<T>(List<T> list) => list[_rng.nextInt(list.length)];

  static List<String> _pickMembers() {
    final shuffled = List<String>.from(_userIds)..shuffle(_rng);
    return shuffled.take(_rng.nextInt(5) + 2).toList(); // 2–6 members
  }
}

enum _TripStatus { ongoing, upcoming, finished }
