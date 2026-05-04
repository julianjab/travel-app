import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vamos/app.dart';
import 'package:vamos/data/repositories/firestore_expense_repository.dart';
import 'package:vamos/data/repositories/firestore_invite_repository.dart';
import 'package:vamos/data/repositories/firestore_itinerary_repository.dart';
import 'package:vamos/data/repositories/firestore_member_repository.dart';
import 'package:vamos/data/repositories/firestore_trip_repository.dart';
import 'package:vamos/dev/mocks/mock_expense_repository.dart';
import 'package:vamos/dev/mocks/mock_invite_repository.dart';
import 'package:vamos/dev/mocks/mock_itinerary_repository.dart';
import 'package:vamos/dev/mocks/mock_member_repository.dart';
import 'package:vamos/dev/mocks/mock_trip_repository.dart';
import 'package:vamos/dev/mocks/trip_fixtures.dart';
import 'package:vamos/features/auth/application/auth_notifier.dart';
import 'package:vamos/features/trips/application/my_trips_notifier.dart';

/// Development entry point — runs the app without Firebase.
///
/// Overrides all data-layer providers with in-memory stubs so you can iterate
/// on UI without a Firebase project configured on the machine.
///
/// Usage:
///   flutter run -t lib/main_dev.dart
///
/// What's active:
///   - All repository providers → mock in-memory implementations
///   - currentUserIdProvider   → 'user_dev' (treated as authenticated)
///   - isAuthenticatedProvider → true (router skips /login, goes straight to /trips)
///   - authStateProvider       → Stream.value(null) (no Firebase Auth in dev mode)
///
/// What's NOT active:
///   - No real Firestore reads/writes
///   - No Firebase Auth
void main() {
  // Firebase.initializeApp() is intentionally absent.
  // All providers are overridden below so nothing touches Firebase.
  runApp(
    ProviderScope(
      overrides: [
        // Router uses isAuthenticatedProvider → stays on /trips, never redirects to /login.
        isAuthenticatedProvider.overrideWith((ref) => true),

        // authStateProvider normally streams FirebaseAuth.authStateChanges().
        // Override with a null stream so any code reading it gets null (no user),
        // and falls back to currentUserIdProvider ('user_dev') for display names.
        authStateProvider.overrideWith((ref) => Stream.value(null)),

        // Inject a fake user ID so notifiers that read currentUserIdProvider work correctly.
        currentUserIdProvider.overrideWithValue('user_dev'),

        // Replace Firestore repos with in-memory mocks. TripFixtures.random(n) picks
        // varied LATAM names/destinations/currencies each run for realistic test data.
        tripRepositoryProvider.overrideWithValue(
          MockTripRepository()..setTrips(TripFixtures.random(6)),
        ),
        expenseRepositoryProvider.overrideWithValue(MockExpenseRepository()),
        memberRepositoryProvider.overrideWithValue(MockMemberRepository()),
        itineraryRepositoryProvider.overrideWithValue(MockItineraryRepository()),
        inviteRepositoryProvider.overrideWithValue(MockInviteRepository()),
      ],
      child: const VamosApp(),
    ),
  );
}
