import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vamos/core/theme/vamos_colors.dart';
import 'package:vamos/core/theme/vamos_typography.dart';
import 'package:vamos/data/models/itinerary_item.dart';
import 'package:vamos/data/models/trip.dart';
import 'package:vamos/features/itinerary/application/item_actions_notifier.dart';
import 'package:vamos/features/itinerary/presentation/widgets/item_form.dart';
import 'package:vamos/features/trips/application/my_trips_notifier.dart';

/// F2.2 — Create item form.
///
/// Builds an [ItineraryItem] and sends it to [ItemActionsNotifier.create].
class CreateItemScreen extends ConsumerWidget {
  const CreateItemScreen({
    super.key,
    required this.tripId,
    required this.trip,
  });

  final String tripId;
  final Trip trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionsState = ref.watch(itemActionsProvider);
    final isLoading = actionsState.isLoading;

    // Listen for success or error
    ref.listen<AsyncValue<void>>(itemActionsProvider, (prev, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al guardar. Intentá de nuevo.'),
          ),
        );
      } else if (next.hasValue && prev?.isLoading == true) {
        // Successfully created — pop back
        if (context.mounted) Navigator.of(context).pop();
      }
    });

    return Scaffold(
      backgroundColor: VamosColors.bg,
      appBar: AppBar(
        backgroundColor: VamosColors.surface,
        surfaceTintColor: Colors.transparent,
        title: Text('Nuevo item', style: VamosTypography.headlineMedium),
      ),
      body: ItemForm(
        trip: trip,
        isLoading: isLoading,
        onSubmit: (formData) async {
          final userId = ref.read(currentUserIdProvider);
          final now = DateTime.now();
          final item = ItineraryItem(
            id: '',
            title: formData.title,
            day: formData.day,
            time: formData.time,
            location: formData.location,
            notes: formData.notes,
            authorId: userId,
            status: 'proposed',
            votes: const {},
            createdAt: now,
            updatedAt: now,
          );
          await ref.read(itemActionsProvider.notifier).create(
                tripId: tripId,
                item: item,
              );
        },
      ),
    );
  }
}
