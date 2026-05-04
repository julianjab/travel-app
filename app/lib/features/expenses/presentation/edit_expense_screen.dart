import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vamos/core/theme/vamos_typography.dart';
import 'package:vamos/core/utils/snackbar_utils.dart';
import 'package:vamos/data/models/expense.dart';
import 'package:vamos/data/models/trip.dart';
import 'package:vamos/features/expenses/application/expense_actions_notifier.dart';
import 'package:vamos/features/expenses/presentation/widgets/expense_form.dart';
import 'package:vamos/features/trips/application/my_trips_notifier.dart';

/// F3-09 — Edit expense screen.
///
/// Re-uses [ExpenseForm] pre-filled with the existing [expense]. On submit
/// appends an [editHistory] entry before dispatching [ExpenseActionsNotifier.update].
class EditExpenseScreen extends ConsumerWidget {
  const EditExpenseScreen({
    super.key,
    required this.tripId,
    required this.expense,
    required this.trip,
  });

  final String tripId;
  final Expense expense;
  final Trip trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.read(currentUserIdProvider);
    final actionsState = ref.watch(expenseActionsProvider);

    ref.listen<AsyncValue<void>>(expenseActionsProvider, (prev, next) {
      next.whenOrNull(
        error: (e, _) {
          if (context.mounted) showErrorSnackBar(context);
        },
      );
      if (next.hasValue && prev?.isLoading == true) {
        // Pop edit screen and detail screen, back to the list.
        if (context.mounted) {
          Navigator.of(context).pop(); // pop edit
          Navigator.of(context).pop(); // pop detail
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        title: Text('Editar gasto', style: VamosTypography.headlineMedium),
      ),
      body: ExpenseForm(
        trip: trip,
        initial: expense,
        isLoading: actionsState.isLoading,
        onSubmit: (updated) {
          // Append an audit entry to the history.
          final historyEntry = <String, dynamic>{
            'changedBy': currentUserId,
            'changedAt': DateTime.now(),
            'field': 'full_update',
          };
          final withHistory = updated.copyWith(
            id: expense.id, // keep same document ID
            createdAt: expense.createdAt, // preserve original
            createdBy: expense.createdBy, // preserve original
            editHistory: [...expense.editHistory, historyEntry],
          );
          ref.read(expenseActionsProvider.notifier).save(
                tripId: tripId,
                expense: withHistory,
              );
        },
      ),
    );
  }
}
