import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:vamos/core/theme/vamos_colors.dart';
import 'package:vamos/core/theme/vamos_spacing.dart';
import 'package:vamos/core/theme/vamos_typography.dart';
import 'package:vamos/data/models/expense.dart';
import 'package:vamos/data/models/trip.dart';
import 'package:vamos/features/expenses/application/expense_actions_notifier.dart';
import 'package:vamos/features/expenses/presentation/widgets/expense_form.dart';
import 'package:vamos/features/trips/application/my_trips_notifier.dart';

/// F3-03 — Create expense form.
///
/// Builds an [Expense] and dispatches [ExpenseActionsNotifier.create].
/// On success the screen pops. On error a SnackBar is shown.
class CreateExpenseScreen extends ConsumerWidget {
  const CreateExpenseScreen({
    super.key,
    required this.trip,
  });

  final Trip trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.read(currentUserIdProvider);
    final actionsState = ref.watch(expenseActionsProvider);

    ref.listen<AsyncValue<void>>(expenseActionsProvider, (prev, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al guardar el gasto. Intentá de nuevo.'),
          ),
        );
      } else if (next.hasValue && prev?.isLoading == true) {
        if (context.mounted) Navigator.of(context).pop();
      }
    });

    return Scaffold(
      backgroundColor: VamosColors.bg,
      appBar: AppBar(
        backgroundColor: VamosColors.surface,
        surfaceTintColor: Colors.transparent,
        title: Text('Nuevo gasto', style: VamosTypography.headlineMedium),
      ),
      body: ExpenseForm(
        trip: trip,
        isLoading: actionsState.isLoading,
        onSubmit: (expense) {
          final withCreator = expense.copyWith(
            createdBy: currentUserId,
            createdAt: DateTime.now(),
          );
          ref.read(expenseActionsProvider.notifier).create(
                tripId: trip.id,
                expense: withCreator,
              );
        },
      ),
    );
  }
}
