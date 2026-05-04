import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vamos/features/auth/presentation/login_screen.dart';
import 'package:vamos/features/trips/presentation/my_trips_screen.dart';

// ---------------------------------------------------------------------------
// Auth change notifier — bridges Firebase Auth stream to GoRouter
// ---------------------------------------------------------------------------

/// A thin [ChangeNotifier] that listens to [FirebaseAuth.authStateChanges]
/// and calls [notifyListeners] on every emission.
///
/// Used as [GoRouter.refreshListenable] so the router re-evaluates the
/// redirect whenever auth state changes (sign-in, sign-out, token refresh).
/// Accessing [FirebaseAuth] here directly is acceptable — this is router
/// config, not UI or business logic.
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier() {
    _subscription = FirebaseAuth.instance.authStateChanges().listen(
      (_) => notifyListeners(),
    );
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Router
// ---------------------------------------------------------------------------

/// Application router.
///
/// Routes:
///   /login          → [LoginScreen]    (unauthenticated)
///   /trips          → [MyTripsScreen]  (authenticated home, F1.1)
///   /trips/new      → stub for F1.2
///   /trips/:id      → stub for F2.1
///
/// Redirect logic:
///   - Not signed in → /login (from any route)
///   - Signed in on /login → /trips
final router = GoRouter(
  initialLocation: '/trips',
  refreshListenable: _AuthChangeNotifier(),
  redirect: (context, state) {
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    final isOnLogin = state.matchedLocation == '/login';

    if (!isLoggedIn && !isOnLogin) return '/login';
    if (isLoggedIn && isOnLogin) return '/trips';
    return null;
  },
  routes: [
    // -------------------------------------------------------------------------
    // Login / splash (unauthenticated)
    // -------------------------------------------------------------------------
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),

    // -------------------------------------------------------------------------
    // Authenticated home: Mis viajes (F1.1)
    // -------------------------------------------------------------------------
    GoRoute(
      path: '/trips',
      builder: (context, state) => const MyTripsScreen(),
      routes: [
        // TODO(F1-02): replace stub with CreateTripScreen when F1.2 is built.
        GoRoute(
          path: 'new',
          builder: (context, state) => const _StubScreen(title: 'Nuevo viaje'),
        ),
        // TODO(F2-01): replace stub with TripShellScreen when F2.1 is built.
        GoRoute(
          path: ':id',
          builder: (context, state) {
            final tripId = state.pathParameters['id']!;
            return _StubScreen(title: 'Viaje $tripId');
          },
        ),
      ],
    ),
  ],
);

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
