import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vamos/features/auth/presentation/login_screen.dart';
import 'package:vamos/features/trips/presentation/create_trip_screen.dart';
import 'package:vamos/features/trips/presentation/invite_screen.dart';
import 'package:vamos/features/trips/presentation/join_alias_screen.dart';
import 'package:vamos/features/trips/presentation/join_entry_screen.dart';
import 'package:vamos/features/trips/presentation/join_profile_screen.dart';
import 'package:vamos/features/trips/presentation/join_tags_screen.dart';
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
///   /login                    → [LoginScreen]    (unauthenticated)
///   /trips                    → [MyTripsScreen]  (authenticated home, F1.1)
///   /trips/new                → [CreateTripScreen] (create trip form, F1.2)
///   /trips/:id/invite         → [InviteScreen]   (success + share link, F1.3)
///   /trips/:id                → stub for F2.1
///   /join/:code               → stub for F1.6 (deep link entry point)
///
/// Redirect logic:
///   - Not signed in → /login (from any route except /join/:code)
///   - Signed in on /login → /trips
///
/// Deep links handled:
///   - https://vamos.app/j/{code}  (Universal Links / App Links)
///   - vamos://join/{code}         (custom URL scheme fallback)
///
/// Both resolve to /join/:code in the router. The platform layer passes the
/// initial URL to GoRouter via the [GoRouter.initialLocation] resolution;
/// go_router picks it up automatically via the platform channel.
final router = GoRouter(
  initialLocation: '/trips',
  refreshListenable: _AuthChangeNotifier(),
  // Handle malformed or unrecognized deep links gracefully.
  onException: (context, state, router) {
    router.go('/trips');
  },
  redirect: (context, state) {
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    final isOnLogin = state.matchedLocation == '/login';
    // Allow the join flow through even when not signed in — F1-06 handles
    // authentication as part of the onboarding; do not short-circuit it.
    final isOnJoin = state.matchedLocation.startsWith('/join/');

    if (!isLoggedIn && !isOnLogin && !isOnJoin) return '/login';
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
    // Deep link entry: join a trip via invite code (F1.4 / F1.4b / F1.5)
    //
    // Receives the invite code from:
    //   - Universal Link:  https://vamos.app/j/{code}  → /join/{code}
    //   - Custom scheme:   vamos://join/{code}          → /join/{code}
    //
    // /join/:code          → JoinEntryScreen (resolves invite → profile check)
    // /join/:code/profile  → JoinProfileScreen (F1.4, new users only)
    // /join/:code/alias    → JoinAliasScreen   (F1.4b, all users)
    // /join/:code/tags     → JoinTagsScreen    (F1.5, all users)
    // -------------------------------------------------------------------------
    GoRoute(
      path: '/join/:code',
      builder: (context, state) {
        final code = state.pathParameters['code']!;
        return JoinEntryScreen(inviteCode: code);
      },
      routes: [
        // F1.4 — Profile setup (new users only)
        GoRoute(
          path: 'profile',
          builder: (context, state) {
            final code = state.pathParameters['code']!;
            final extra = state.extra as Map<String, dynamic>? ?? {};
            final tripId = extra['tripId'] as String? ?? '';
            final defaultName = extra['defaultName'] as String? ?? '';
            return JoinProfileScreen(
              inviteCode: code,
              tripId: tripId,
              defaultName: defaultName,
            );
          },
        ),
        // F1.4b — Alias selection (all users)
        GoRoute(
          path: 'alias',
          builder: (context, state) {
            final code = state.pathParameters['code']!;
            final extra = state.extra as Map<String, dynamic>? ?? {};
            final tripId = extra['tripId'] as String? ?? '';
            final isNewUser = extra['isNewUser'] as bool? ?? false;
            final defaultName = extra['defaultName'] as String? ?? '';
            return JoinAliasScreen(
              inviteCode: code,
              tripId: tripId,
              isNewUser: isNewUser,
              defaultName: defaultName,
            );
          },
        ),
        // F1.5 — Preference tags (all users)
        GoRoute(
          path: 'tags',
          builder: (context, state) {
            final code = state.pathParameters['code']!;
            final extra = state.extra as Map<String, dynamic>? ?? {};
            final tripId = extra['tripId'] as String? ?? '';
            final isNewUser = extra['isNewUser'] as bool? ?? false;
            return JoinTagsScreen(
              inviteCode: code,
              tripId: tripId,
              isNewUser: isNewUser,
            );
          },
        ),
      ],
    ),

    // -------------------------------------------------------------------------
    // Authenticated home: Mis viajes (F1.1)
    // -------------------------------------------------------------------------
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
