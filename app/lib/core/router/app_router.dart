import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vamos/features/auth/application/auth_notifier.dart';
import 'package:vamos/features/auth/presentation/login_screen.dart';
import 'package:vamos/features/trips/presentation/create_trip_screen.dart';
import 'package:vamos/features/trips/presentation/invite_screen.dart';
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
///   /login                    → [LoginScreen]    (unauthenticated)
///   /trips                    → [MyTripsScreen]  (authenticated home, F1.1)
///   /trips/new                → [CreateTripScreen] (create trip form, F1.2)
///   /trips/:id/invite         → [InviteScreen]   (success + share link, F1.3)
///   /trips/:id                → stub for F2.1
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
          // TODO(F2-01): replace stub with TripShellScreen when F2.1 is built.
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final tripId = state.pathParameters['id']!;
              return _StubScreen(title: 'Viaje $tripId');
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
            ],
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

// ---------------------------------------------------------------------------
// Stub screen — temporary placeholder until flow screens are built
// ---------------------------------------------------------------------------

/// Temporary screen shown for routes that are not yet implemented.
/// Remove route by route as screens are added to the app.
class _StubScreen extends StatelessWidget {
  const _StubScreen({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          'Próximamente',
          style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
