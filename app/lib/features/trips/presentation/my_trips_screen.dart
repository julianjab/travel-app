import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vamos/core/theme/app_spacing.dart';
import 'package:vamos/features/trips/application/my_trips_notifier.dart';
import 'package:vamos/features/trips/presentation/widgets/trip_card.dart';

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
        loading: () => const _LoadingState(),
        error: (error, stack) => _ErrorState(error: error),
        data: (trips) => trips.isEmpty
            ? const _EmptyState()
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
    final text = Theme.of(context).textTheme;
    return AppBar(
      title: Text('Mis viajes', style: text.titleLarge),
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

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error});
  final Object error;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          'No se pudo cargar tus viajes. Verificá tu conexión.',
          style: text.bodyMedium?.copyWith(color: scheme.error),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Empty state using the exact copy from `docs/06-identidad-y-tono.md` §5.1.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Acá no hay nada todavía.',
              style: text.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Creá un viaje, o pedile el link a quien ya armó uno.',
              style: text.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Non-empty list of trip cards.
class _TripList extends StatelessWidget {
  const _TripList({required this.trips});
  final List<dynamic> trips;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      itemCount: trips.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
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
