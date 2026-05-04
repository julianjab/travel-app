import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vamos/core/theme/vamos_colors.dart';
import 'package:vamos/core/theme/vamos_typography.dart';
import 'package:vamos/core/utils/snackbar_utils.dart';
import 'package:vamos/data/models/itinerary_item.dart';
import 'package:vamos/data/models/trip.dart';
import 'package:vamos/features/itinerary/application/item_actions_notifier.dart';
import 'package:vamos/features/itinerary/presentation/widgets/item_form.dart';

/// F2.7 — Edit item form.
///
/// Pre-fills [ItemForm] with the existing [item] values. On submit, calls
/// [ItemActionsNotifier.update] and pops on success.
class EditItemScreen extends ConsumerWidget {
  const EditItemScreen({
    super.key,
    required this.tripId,
    required this.item,
    required this.trip,
  });

  final String tripId;
  final ItineraryItem item;
  final Trip trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionsState = ref.watch(itemActionsProvider);
    final isLoading = actionsState.isLoading;

    ref.listen<AsyncValue<void>>(itemActionsProvider, (prev, next) {
      next.whenOrNull(
        error: (e, _) {
          if (context.mounted) showErrorSnackBar(context);
        },
      );
      if (next.hasValue && prev?.isLoading == true) {
        if (context.mounted) Navigator.of(context).pop();
      }
    });

    return Scaffold(
      backgroundColor: VamosColors.bg,
      appBar: AppBar(
        backgroundColor: VamosColors.surface,
        surfaceTintColor: Colors.transparent,
        title: Text('Editar item', style: VamosTypography.headlineMedium),
      ),
      body: ItemForm(
        trip: trip,
        isLoading: isLoading,
        initialTitle: item.title,
        initialDay: item.day,
        initialTime: item.time,
        initialLocation: item.location,
        initialNotes: item.notes,
        onSubmit: (formData) async {
          final updated = item.copyWith(
            title: formData.title,
            day: formData.day,
            time: formData.time,
            location: formData.location,
            notes: formData.notes,
            updatedAt: DateTime.now(),
          );
          await ref.read(itemActionsProvider.notifier).updateItem(
                tripId: tripId,
                item: updated,
              );
        },
      ),
    );
  }
}
