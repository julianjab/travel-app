import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vamos/app.dart';
import 'package:vamos/data/repositories/firestore_trip_repository.dart';
import 'package:vamos/features/trips/application/my_trips_notifier.dart';

import '../test/data/mocks/mock_trip_repository.dart';
import '../test/data/mocks/trip_fixtures.dart';

/// Development entry point — runs the app without Firebase.
///
/// Overrides all data-layer providers with in-memory stubs so you can iterate
/// on UI without a Firebase project configured on the machine.
///
/// Usage:
///   flutter run -t lib/main_dev.dart
///
/// What's active:
///   - tripRepositoryProvider → MockTripRepository with 3 fixture trips
///   - currentUserIdProvider  → 'user_dev' (treated as authenticated)
///
/// What's NOT active:
///   - No real Firestore reads/writes
///   - No Firebase Auth (auth state is faked via currentUserIdProvider)
///   - Any feature that calls an UnimplementedError repo (Member, Itinerary,
///     Expense) will throw at runtime — add their mock overrides here when
///     those flows are being developed.
void main() {
  // Firebase.initializeApp() is intentionally absent.
  // Only firestoreProvider + authProvider are skipped; they are not needed
  // because all repos are overridden below before they are read.
  runApp(
    ProviderScope(
      overrides: [
        // Inject a fake user ID so MyTripsNotifier skips the empty-string path.
        currentUserIdProvider.overrideWithValue('user_dev'),

        // Replace Firestore trips repo with the in-memory mock.
        tripRepositoryProvider.overrideWithValue(
          MockTripRepository()..setTrips(TripFixtures.sortedSet()),
        ),
      ],
      child: const VamosApp(),
    ),
  );
}
