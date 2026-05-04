import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:vamos/core/theme/vamos_colors.dart';
import 'package:vamos/core/theme/vamos_spacing.dart';
import 'package:vamos/core/theme/vamos_typography.dart';
import 'package:vamos/data/models/itinerary_item.dart';
import 'package:vamos/data/models/trip.dart';
import 'package:vamos/features/itinerary/application/itinerary_notifier.dart';
import 'package:vamos/features/itinerary/presentation/widgets/item_card.dart';
import 'package:vamos/shared/widgets/empty_state.dart';
import 'package:vamos/shared/widgets/loading_indicator.dart';

/// F2.1 — Itinerary list grouped by day.
///
/// Receives [tripId] and [trip] from [TripShellScreen].
/// Groups items by day. Days without items are not shown per wireframe spec.
class ItineraryScreen extends ConsumerWidget {
  const ItineraryScreen({
    super.key,
    required this.tripId,
    required this.trip,
  });

  final String tripId;
  final Trip trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(itineraryProvider(tripId));

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: VamosColors.sol500,
        foregroundColor: VamosColors.textOnDark,
        onPressed: () => context.push('/trips/$tripId/items/new', extra: trip),
        child: const Icon(Icons.add),
      ),
      body: itemsAsync.when(
        loading: () => const VamosLoadingIndicator(),
        error: (e, _) => _ErrorState(tripId: tripId, trip: trip),
        data: (items) => _ItemsList(
          tripId: tripId,
          trip: trip,
          items: items,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Items grouped list
// ---------------------------------------------------------------------------

class _ItemsList extends StatelessWidget {
  const _ItemsList({
    required this.tripId,
    required this.trip,
    required this.items,
  });

  final String tripId;
  final Trip trip;
  final List<ItineraryItem> items;

  /// Groups items by date (day only, normalized to midnight).
  Map<DateTime, List<ItineraryItem>> _groupByDay(List<ItineraryItem> items) {
    final map = <DateTime, List<ItineraryItem>>{};
    for (final item in items) {
      final key = DateTime(item.day.year, item.day.month, item.day.day);
      (map[key] ??= []).add(item);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _EmptyState(tripId: tripId, trip: trip);
    }

    final grouped = _groupByDay(items);
    // Sort days ascending
    final sortedDays = grouped.keys.toList()..sort();

    // Compute day number (day 1 = startDate)
    final startDay = DateTime(
        trip.startDate.year, trip.startDate.month, trip.startDate.day);

    return ListView.builder(
      padding: const EdgeInsets.only(
        top: VamosSpacing.sm,
        bottom: VamosSpacing.xxxl,
        left: VamosSpacing.md,
        right: VamosSpacing.md,
      ),
      itemCount: sortedDays.length,
      itemBuilder: (context, index) {
        final day = sortedDays[index];
        final dayNumber = day.difference(startDay).inDays + 1;
        final dayItems = grouped[day]!;

        return _DaySection(
          day: day,
          dayNumber: dayNumber,
          items: dayItems,
          tripId: tripId,
          trip: trip,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Day section
// ---------------------------------------------------------------------------

class _DaySection extends StatelessWidget {
  const _DaySection({
    required this.day,
    required this.dayNumber,
    required this.items,
    required this.tripId,
    required this.trip,
  });

  final DateTime day;
  final int dayNumber;
  final List<ItineraryItem> items;
  final String tripId;
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd/MM').format(day);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: VamosSpacing.lg,
            bottom: VamosSpacing.sm,
          ),
          child: Row(
            children: [
              Text(
                'Día $dayNumber — $dateStr',
                style: VamosTypography.overline.copyWith(
                  color: VamosColors.text3,
                ),
              ),
              const SizedBox(width: VamosSpacing.sm),
              const Expanded(
                child: Divider(color: VamosColors.border, thickness: 1),
              ),
            ],
          ),
        ),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: VamosSpacing.sm),
            child: ItemCard(
              item: item,
              onTap: () => context.push(
                '/trips/$tripId/items/${item.id}',
                extra: {'item': item, 'trip': trip},
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state (F2.4 — validated microcopy from 06-identidad-y-tono.md §5.4)
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.tripId, required this.trip});

  final String tripId;
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    return VamosEmptyState(
      icon: Icons.map_outlined,
      // Exact copy from docs/06-identidad-y-tono.md §5.4
      message:
          'Acá no hay nada todavía.\n\nCualquiera puede tirar la primera idea — un vuelo, un restaurante, lo que sea. Después se vota.',
      actionLabel: '+ Agregar primer item',
      onAction: () => context.push('/trips/$tripId/items/new', extra: trip),
    );
  }
}

// ---------------------------------------------------------------------------
// Error state
// ---------------------------------------------------------------------------

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.tripId, required this.trip});

  final String tripId;
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(VamosSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: VamosSpacing.xxl,
              color: VamosColors.red,
            ),
            const SizedBox(height: VamosSpacing.md),
            Text(
              'Algo salió mal.',
              style: VamosTypography.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: VamosSpacing.sm),
            Text(
              'Intentá de nuevo.',
              style: VamosTypography.bodyMedium.copyWith(
                color: VamosColors.text3,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
