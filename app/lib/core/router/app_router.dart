import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vamos/features/trips/presentation/my_trips_screen.dart';

/// Application router.
///
/// Routes declared here:
///   /trips          → [MyTripsScreen]  (authenticated home, F1.1)
///   /trips/new      → stub for F1.2 (create trip form)
///   /trips/:id      → stub for F2.1 (trip shell with tabs)
///
/// Auth redirect is not wired yet — it will be added when E0-06 (auth) lands.
/// TODO(F1-01): add redirect in refreshListenable once authStateProvider exists.
final router = GoRouter(
  initialLocation: '/trips',
  routes: [
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
