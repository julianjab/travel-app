import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vamos/core/theme/app_theme.dart';
import 'package:vamos/data/repositories/firestore_trip_repository.dart';
import 'package:vamos/features/trips/application/my_trips_notifier.dart';
import 'package:vamos/features/trips/presentation/my_trips_screen.dart';

import '../../../data/mocks/mock_trip_repository.dart';
import '../../../data/mocks/trip_fixtures.dart';

// ---------------------------------------------------------------------------
// Test router
// ---------------------------------------------------------------------------

/// Minimal GoRouter for widget tests.
/// Only declares /trips so that MyTripsScreen can call context.push('/trips/id')
/// without crashing; the target route renders a simple Scaffold.
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
// Helper
// ---------------------------------------------------------------------------

/// Pumps [MyTripsScreen] inside a [ProviderScope] that overrides both the
/// repository and the user ID, so no Firebase is needed.
Future<void> pumpMyTripsScreen(
  WidgetTester tester, {
  required MockTripRepository repo,
  String userId = 'user_1',
}) async {
  final testRouter = _buildTestRouter();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tripRepositoryProvider.overrideWithValue(repo),
        currentUserIdProvider.overrideWithValue(userId),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: testRouter,
      ),
    ),
  );

  // Allow the StreamNotifier to resolve its first emission.
  await tester.pump();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('MyTripsScreen — sorting + status badges', () {
    test('MockTripRepository emits the injected list', () async {
      // Verify the mock works independently before involving widgets.
      final mock = MockTripRepository();
      mock.setTrips(TripFixtures.sortedSet());

      final result = await mock.watchUserTrips('user_1').first;
      expect(result.length, 3);
      expect(result[0].name, 'Brasil con los del barrio');
      expect(result[1].name, 'Patagonia express');
      expect(result[2].name, 'CDMX crew');
    });

    testWidgets('renders all three trip names', (tester) async {
      final mock = MockTripRepository()
        ..setTrips(TripFixtures.sortedSet());

      await pumpMyTripsScreen(tester, repo: mock);

      expect(find.text('Brasil con los del barrio'), findsOneWidget);
      expect(find.text('Patagonia express'), findsOneWidget);
      expect(find.text('CDMX crew'), findsOneWidget);
    });

    testWidgets('ongoing trip shows "En curso" badge', (tester) async {
      final mock = MockTripRepository()
        ..setTrips([TripFixtures.ongoing()]);

      await pumpMyTripsScreen(tester, repo: mock);

      // The badge starts with "En curso". Use a prefix finder.
      expect(
        find.textContaining('En curso'),
        findsOneWidget,
      );
    });

    testWidgets('upcoming trip shows "Por planear" badge', (tester) async {
      final mock = MockTripRepository()
        ..setTrips([TripFixtures.upcoming()]);

      await pumpMyTripsScreen(tester, repo: mock);

      expect(
        find.textContaining('Por planear'),
        findsOneWidget,
      );
    });

    testWidgets('finished trip shows "Terminado" badge', (tester) async {
      final mock = MockTripRepository()
        ..setTrips([TripFixtures.finished()]);

      await pumpMyTripsScreen(tester, repo: mock);

      expect(find.text('Terminado'), findsOneWidget);
    });

    testWidgets('status sort order: ongoing before upcoming before finished',
        (tester) async {
      // Inject in the reverse order to confirm the notifier re-sorts.
      final mock = MockTripRepository()
        ..setTrips([
          TripFixtures.finished(),   // would be last after sort
          TripFixtures.upcoming(),   // would be second
          TripFixtures.ongoing(),    // would be first
        ]);

      await pumpMyTripsScreen(tester, repo: mock);

      // Collect all TripCard widgets via trip name Text widgets.
      // The vertical order in ListView reflects sort order.
      final ongoingOffset =
          tester.getTopLeft(find.text('Brasil con los del barrio')).dy;
      final upcomingOffset =
          tester.getTopLeft(find.text('Patagonia express')).dy;
      final finishedOffset =
          tester.getTopLeft(find.text('CDMX crew')).dy;

      expect(ongoingOffset, lessThan(upcomingOffset),
          reason: 'ongoing must appear before upcoming');
      expect(upcomingOffset, lessThan(finishedOffset),
          reason: 'upcoming must appear before finished');
    });

    testWidgets('empty list shows empty-state copy', (tester) async {
      final mock = MockTripRepository()..setTrips([]);

      await pumpMyTripsScreen(tester, repo: mock);

      expect(find.text('Acá no hay nada todavía.'), findsOneWidget);
      expect(
        find.textContaining('Creá un viaje'),
        findsOneWidget,
      );
    });
  });
}
