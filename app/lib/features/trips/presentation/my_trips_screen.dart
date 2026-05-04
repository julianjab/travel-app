import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vamos/core/theme/vamos_spacing.dart';
import 'package:vamos/features/trips/application/my_trips_notifier.dart';
import 'package:vamos/features/trips/presentation/widgets/trip_card.dart';
import 'package:vamos/shared/widgets/empty_state.dart';
import 'package:vamos/shared/widgets/error_state.dart';
import 'package:vamos/shared/widgets/loading_indicator.dart';

/// F1.1 — "Mis viajes" home screen.
///
/// Shows the list of trips the current user belongs to, ordered by status:
///   ongoing → upcoming → finished → archived.
/// When the list is empty, renders the empty state with the validated
/// microcopy from `docs/06-identidad-y-tono.md` §5.1.
class MyTripsScreen extends ConsumerWidget {
  const MyTripsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(myTripsProvider);

    return Scaffold(
      appBar: _buildAppBar(context),
      body: tripsAsync.when(
        loading: () => const VamosLoadingIndicator(),
        error: (error, stack) => VamosErrorState(
          title: 'No se pudo cargar tus viajes.',
          message: 'Verificá tu conexión e intentá de nuevo.',
          error: error,
          stackTrace: stack,
          debugLabel: 'MyTripsScreen',
          onRetry: () => ref.invalidate(myTripsProvider),
        ),
        data: (trips) => trips.isEmpty
            ? VamosEmptyState(
                // Exact copy from docs/06-identidad-y-tono.md §5.1
                message:
                    'Acá no hay nada todavía.\n\nCreá un viaje, o pedile el link a quien ya armó uno.',
                actionLabel: '+ Nuevo viaje',
                onAction: () => context.push('/trips/new'),
                icon: Icons.travel_explore_outlined,
              )
            : _TripList(trips: trips),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/trips/new'),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo viaje'),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Mis viajes'),
      actions: [
        IconButton(
          // TODO(F1-01): navigate to profile screen when F4.x is implemented.
          onPressed: () {},
          icon: const Icon(Icons.account_circle_outlined),
          tooltip: 'Perfil',
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------

/// Non-empty list of trip cards.
class _TripList extends StatelessWidget {
  const _TripList({required this.trips});
  final List<dynamic> trips;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: VamosSpacing.md,
        vertical: VamosSpacing.md,
      ),
      itemCount: trips.length,
      separatorBuilder: (context, index) => const SizedBox(height: VamosSpacing.md),
      itemBuilder: (context, index) {
        final trip = trips[index];
        return TripCard(
          trip: trip,
          // memberIds.length is the member count.
          // TODO(F1-01): once members sub-collection is queried, use real count.
          memberCount: trip.memberIds.length,
          onTap: () => context.push('/trips/${trip.id}'),
        );
      },
    );
  }
}
