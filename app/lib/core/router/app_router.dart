import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vamos/data/models/expense.dart';
import 'package:vamos/data/models/itinerary_item.dart';
import 'package:vamos/data/models/trip.dart';
import 'package:vamos/features/auth/application/auth_notifier.dart';
import 'package:vamos/features/auth/presentation/login_screen.dart';
import 'package:vamos/features/expenses/presentation/balances_screen.dart';
import 'package:vamos/features/expenses/presentation/create_expense_screen.dart';
import 'package:vamos/features/expenses/presentation/edit_expense_screen.dart';
import 'package:vamos/features/expenses/presentation/expense_detail_screen.dart';
import 'package:vamos/features/itinerary/presentation/create_item_screen.dart';
import 'package:vamos/features/itinerary/presentation/edit_item_screen.dart';
import 'package:vamos/features/itinerary/presentation/item_detail_screen.dart';
import 'package:vamos/features/trips/presentation/create_trip_screen.dart';
import 'package:vamos/features/trips/presentation/invite_screen.dart';
import 'package:vamos/features/trips/presentation/join_alias_screen.dart';
import 'package:vamos/features/trips/presentation/join_entry_screen.dart';
import 'package:vamos/features/trips/presentation/join_profile_screen.dart';
import 'package:vamos/features/trips/presentation/join_tags_screen.dart';
import 'package:vamos/features/trip_shell/presentation/trip_shell_screen.dart';
import 'package:vamos/features/trips/presentation/my_trips_screen.dart';

// ---------------------------------------------------------------------------
// Auth change notifier — bridges isAuthenticatedProvider to GoRouter
// ---------------------------------------------------------------------------

/// Listens to [isAuthenticatedProvider] via Riverpod and notifies GoRouter
/// whenever auth state changes.
///
/// Using Riverpod here (instead of FirebaseAuth.instance directly) means
/// the router works without a real Firebase instance in dev/test mode.
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen<bool>(isAuthenticatedProvider, (_, _) => notifyListeners());
  }

  final Ref _ref;

  String? redirect(BuildContext context, GoRouterState state) {
    final isLoggedIn = _ref.read(isAuthenticatedProvider);
    final isOnLogin = state.matchedLocation == '/login';

    if (!isLoggedIn && !isOnLogin) return '/login';
    if (isLoggedIn && isOnLogin) return '/trips';
    return null;
  }
}

// ---------------------------------------------------------------------------
// Router provider
// ---------------------------------------------------------------------------

/// Application router, exposed as a Riverpod [Provider] so it can read
/// auth state without touching Firebase directly.
///
/// Routes:
///   /login                                → [LoginScreen]    (unauthenticated)
///   /trips                                → [MyTripsScreen]  (F1.1)
///   /trips/new                            → [CreateTripScreen] (F1.2)
///   /trips/:id/invite                     → [InviteScreen]   (F1.3)
///   /trips/:id                            → [TripShellScreen] (F1.7/F4.1)
///   /trips/:id/expenses/new               → [CreateExpenseScreen] (F3.3)
///   /trips/:id/expenses/:expenseId        → [ExpenseDetailScreen] (F3.9)
///   /trips/:id/expenses/:expenseId/edit   → [EditExpenseScreen] (F3.9)
///   /trips/:id/balances                   → [BalancesScreen] (F3.10)
///   /join/:code                           → join onboarding flow (F1.4–F1.6)
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
  final goRouter = GoRouter(
    initialLocation: '/trips',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      // -----------------------------------------------------------------------
      // Login / splash (unauthenticated)
      // -----------------------------------------------------------------------
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // -----------------------------------------------------------------------
      // Authenticated home: Mis viajes (F1.1)
      // -----------------------------------------------------------------------
      GoRoute(
        path: '/trips',
        builder: (context, state) => const MyTripsScreen(),
        routes: [
          // F1.2 — Crear viaje form.
          GoRoute(
            path: 'new',
            builder: (context, state) => const CreateTripScreen(),
          ),
          // F1.7 / F4.1 — Trip shell with Itinerario, Gastos, Gente tabs.
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final tripId = state.pathParameters['id']!;
              return TripShellScreen(tripId: tripId);
            },
            routes: [
              // F1.3 — Success + invite-link screen.
              GoRoute(
                path: 'invite',
                builder: (context, state) {
                  final tripId = state.pathParameters['id']!;
                  return InviteScreen(tripId: tripId);
                },
              ),
              // F3 — Expenses: create
              GoRoute(
                path: 'expenses/new',
                builder: (context, state) {
                  final trip = state.extra as Trip;
                  return CreateExpenseScreen(trip: trip);
                },
              ),
              // F3 — Expenses: detail (with edit/delete)
              GoRoute(
                path: 'expenses/:expenseId',
                builder: (context, state) {
                  final tripId = state.pathParameters['id']!;
                  final extra = state.extra as Map<String, dynamic>;
                  return ExpenseDetailScreen(
                    tripId: tripId,
                    expense: extra['expense'] as Expense,
                    trip: extra['trip'] as Trip,
                  );
                },
                routes: [
                  // F3 — Expenses: edit
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) {
                      final tripId = state.pathParameters['id']!;
                      final extra = state.extra as Map<String, dynamic>;
                      return EditExpenseScreen(
                        tripId: tripId,
                        expense: extra['expense'] as Expense,
                        trip: extra['trip'] as Trip,
                      );
                    },
                  ),
                ],
              ),
              // F3 — Balances view
              GoRoute(
                path: 'balances',
                builder: (context, state) {
                  final tripId = state.pathParameters['id']!;
                  final trip = state.extra as Trip;
                  return BalancesScreen(tripId: tripId, trip: trip);
                },
              ),
              // F2 — Itinerary: create item
              GoRoute(
                path: 'items/new',
                builder: (context, state) {
                  final tripId = state.pathParameters['id']!;
                  final trip = state.extra as Trip;
                  return CreateItemScreen(tripId: tripId, trip: trip);
                },
              ),
              // F2 — Itinerary: item detail (with voting, confirm, delete, move)
              GoRoute(
                path: 'items/:itemId',
                builder: (context, state) {
                  final tripId = state.pathParameters['id']!;
                  final extra = state.extra as Map<String, dynamic>;
                  return ItemDetailScreen(
                    tripId: tripId,
                    item: extra['item'] as ItineraryItem,
                    trip: extra['trip'] as Trip,
                  );
                },
                routes: [
                  // F2 — Itinerary: edit item
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) {
                      final tripId = state.pathParameters['id']!;
                      final extra = state.extra as Map<String, dynamic>;
                      return EditItemScreen(
                        tripId: tripId,
                        item: extra['item'] as ItineraryItem,
                        trip: extra['trip'] as Trip,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // -----------------------------------------------------------------------
      // Join flow — F1.4 to F1.6 (deep link entry: /join/:code)
      // -----------------------------------------------------------------------
      GoRoute(
        path: '/join/:code',
        builder: (context, state) {
          final code = state.pathParameters['code']!;
          return JoinEntryScreen(inviteCode: code);
        },
        routes: [
          GoRoute(
            path: 'profile',
            builder: (context, state) {
              final code = state.pathParameters['code']!;
              return JoinProfileScreen(inviteCode: code);
            },
          ),
          GoRoute(
            path: 'alias',
            builder: (context, state) {
              final code = state.pathParameters['code']!;
              return JoinAliasScreen(inviteCode: code);
            },
          ),
          GoRoute(
            path: 'tags',
            builder: (context, state) {
              final code = state.pathParameters['code']!;
              return JoinTagsScreen(inviteCode: code);
            },
          ),
        ],
      ),
    ],
  );

  ref.onDispose(() {
    notifier.dispose();
    goRouter.dispose();
  });

  return goRouter;
});
