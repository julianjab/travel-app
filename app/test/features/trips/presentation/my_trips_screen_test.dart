import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vamos/core/theme/vamos_theme.dart';
import 'package:vamos/data/models/trip.dart';
import 'package:vamos/data/repositories/firestore_trip_repository.dart';
import 'package:vamos/features/trips/application/my_trips_notifier.dart';
import 'package:vamos/features/trips/presentation/my_trips_screen.dart';

import 'package:vamos/dev/mocks/mock_trip_repository.dart';
import 'package:vamos/dev/mocks/trip_fixtures.dart';

// ---------------------------------------------------------------------------
// Test router
// ---------------------------------------------------------------------------

GoRouter _buildTestRouter() => GoRouter(
      initialLocation: '/trips',
      routes: [
        GoRoute(
          path: '/trips',
          builder: (context, state) => const MyTripsScreen(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) => const Scaffold(body: Text('detail')),
            ),
            GoRoute(
              path: 'new',
              builder: (context, state) => const Scaffold(body: Text('new')),
            ),
          ],
        ),
      ],
    );

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Pumps [MyTripsScreen] with a tall viewport (1200px) so ListView.builder
/// renders all items without requiring scroll.
Future<void> pumpMyTripsScreen(
  WidgetTester tester, {
  required MockTripRepository repo,
  String userId = 'user_1',
}) async {
  await tester.binding.setSurfaceSize(const Size(400, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tripRepositoryProvider.overrideWithValue(repo),
        currentUserIdProvider.overrideWithValue(userId),
      ],
      child: MaterialApp.router(
        theme: VamosTheme.light,
        routerConfig: _buildTestRouter(),
      ),
    ),
  );

  // Allow the StreamNotifier to resolve its first emission.
  await tester.pump();
}

/// Creates a [Trip] with sensible defaults and only the fields you care about.
Trip _makeTrip({
  required String id,
  required String name,
  required DateTime startDate,
  required DateTime endDate,
}) {
  final now = DateTime.now();
  return Trip(
    id: id,
    name: name,
    destination: 'Destino test',
    startDate: startDate,
    endDate: endDate,
    mainCurrency: 'COP',
    facilitatorId: 'user_1',
    memberIds: const ['user_1'],
    status: 'active',
    createdAt: now.subtract(const Duration(days: 30)),
    createdBy: 'user_1',
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  final now = DateTime.now();

  group('MyTripsScreen — sorting + status badges', () {
    test('MockTripRepository emits the injected list', () async {
      final trips = TripFixtures.sortedSet();
      final mock = MockTripRepository()..setTrips(trips);

      final result = await mock.watchUserTrips('user_1').first;
      expect(result.length, 3);
    });

    testWidgets('renders all injected trip names', (tester) async {
      final mock = MockTripRepository()
        ..setTrips([
          _makeTrip(
            id: 'a',
            name: 'Viaje Alpha',
            startDate: now.subtract(const Duration(days: 2)),
            endDate: now.add(const Duration(days: 5)),
          ),
          _makeTrip(
            id: 'b',
            name: 'Viaje Beta',
            startDate: now.add(const Duration(days: 30)),
            endDate: now.add(const Duration(days: 40)),
          ),
          _makeTrip(
            id: 'c',
            name: 'Viaje Gamma',
            startDate: now.subtract(const Duration(days: 20)),
            endDate: now.subtract(const Duration(days: 10)),
          ),
        ]);

      await pumpMyTripsScreen(tester, repo: mock);

      expect(find.text('Viaje Alpha'), findsOneWidget);
      expect(find.text('Viaje Beta'), findsOneWidget);
      expect(find.text('Viaje Gamma'), findsOneWidget);
    });

    testWidgets('ongoing trip shows "En curso" badge', (tester) async {
      final mock = MockTripRepository()
        ..setTrips([TripFixtures.ongoing()]);

      await pumpMyTripsScreen(tester, repo: mock);

      expect(find.textContaining('En curso'), findsOneWidget);
    });

    testWidgets('upcoming trip shows "Por planear" badge', (tester) async {
      final mock = MockTripRepository()
        ..setTrips([TripFixtures.upcoming()]);

      await pumpMyTripsScreen(tester, repo: mock);

      expect(find.textContaining('Por planear'), findsOneWidget);
    });

    testWidgets('finished trip shows "Terminado" badge', (tester) async {
      final mock = MockTripRepository()
        ..setTrips([TripFixtures.finished()]);

      await pumpMyTripsScreen(tester, repo: mock);

      expect(find.text('Terminado'), findsOneWidget);
    });

    testWidgets('status sort order: ongoing before upcoming before finished',
        (tester) async {
      final ongoingTrip = _makeTrip(
        id: 'ongoing',
        name: 'Trip Ongoing',
        startDate: now.subtract(const Duration(days: 3)),
        endDate: now.add(const Duration(days: 7)),
      );
      final upcomingTrip = _makeTrip(
        id: 'upcoming',
        name: 'Trip Upcoming',
        startDate: now.add(const Duration(days: 60)),
        endDate: now.add(const Duration(days: 70)),
      );
      final finishedTrip = _makeTrip(
        id: 'finished',
        name: 'Trip Finished',
        startDate: now.subtract(const Duration(days: 30)),
        endDate: now.subtract(const Duration(days: 20)),
      );

      // Inject in reverse order — notifier must re-sort.
      final mock = MockTripRepository()
        ..setTrips([finishedTrip, upcomingTrip, ongoingTrip]);

      await pumpMyTripsScreen(tester, repo: mock);

      final ongoingDy = tester.getTopLeft(find.text('Trip Ongoing')).dy;
      final upcomingDy = tester.getTopLeft(find.text('Trip Upcoming')).dy;
      final finishedDy = tester.getTopLeft(find.text('Trip Finished')).dy;

      expect(ongoingDy, lessThan(upcomingDy),
          reason: 'ongoing must appear before upcoming');
      expect(upcomingDy, lessThan(finishedDy),
          reason: 'upcoming must appear before finished');
    });

    testWidgets('empty list shows empty-state copy', (tester) async {
      final mock = MockTripRepository()..setTrips([]);

      await pumpMyTripsScreen(tester, repo: mock);

      expect(find.text('Acá no hay nada todavía.'), findsOneWidget);
      expect(find.textContaining('Creá un viaje'), findsOneWidget);
    });
  });
}
