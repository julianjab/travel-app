import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:vamos/core/theme/vamos_colors.dart';
import 'package:vamos/core/theme/vamos_spacing.dart';
import 'package:vamos/core/theme/vamos_typography.dart';
import 'package:vamos/data/models/expense.dart';
import 'package:vamos/data/models/trip.dart';
import 'package:vamos/features/expenses/application/expenses_notifier.dart';

/// F3-02 — Expenses list screen.
///
/// Displays all expenses for the trip, ordered by date descending.
/// Handles loading, empty, error, and data states.
/// FAB navigates to CreateExpenseScreen; tapping a row goes to detail.
class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({
    super.key,
    required this.tripId,
    required this.trip,
  });

  final String tripId;
  final Trip trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider(tripId));

    return Scaffold(
      backgroundColor: VamosColors.bg,
      // No AppBar here — it lives in TripShellScreen.
      // Actions are provided via the shell but we surface the balances nav
      // as a floating text button at the top for simplicity within the tab.
      body: expensesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorState(onRetry: () => ref.invalidate(expensesProvider(tripId))),
        data: (expenses) => expenses.isEmpty
            ? _EmptyState(
                onAdd: () => context.push(
                  '/trips/${trip.id}/expenses/new',
                  extra: trip,
                ),
              )
            : _ExpensesList(
                expenses: expenses,
                trip: trip,
              ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: VamosColors.sol500,
        foregroundColor: VamosColors.textOnDark,
        onPressed: () => context.push(
          '/trips/${trip.id}/expenses/new',
          extra: trip,
        ),
        tooltip: 'Agregar gasto',
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// List body
// ---------------------------------------------------------------------------

class _ExpensesList extends StatelessWidget {
  const _ExpensesList({required this.expenses, required this.trip});

  final List<Expense> expenses;
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Balances shortcut banner at the top.
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              VamosSpacing.md,
              VamosSpacing.md,
              VamosSpacing.md,
              VamosSpacing.xs,
            ),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: VamosColors.sol500,
                side: const BorderSide(color: VamosColors.sol500),
                shape: const RoundedRectangleBorder(
                  borderRadius: VamosRadius.brFull,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: VamosSpacing.md,
                  vertical: VamosSpacing.sm,
                ),
              ),
              icon: const Icon(Icons.balance, size: VamosSpacing.md),
              label: Text('Ver saldos', style: VamosTypography.bodyMedium.copyWith(color: VamosColors.sol500)),
              onPressed: () => context.push(
                '/trips/${trip.id}/balances',
                extra: trip,
              ),
            ),
          ),
        ),
        SliverList.separated(
          itemCount: expenses.length,
          separatorBuilder: (_, __) => const SizedBox(height: VamosSpacing.xs),
          itemBuilder: (context, index) {
            final expense = expenses[index];
            return _ExpenseCard(expense: expense, trip: trip);
          },
        ),
        // Bottom padding so FAB doesn't overlap last item.
        const SliverToBoxAdapter(
          child: SizedBox(height: VamosSpacing.xxxl),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Expense card
// ---------------------------------------------------------------------------

class _ExpenseCard extends StatelessWidget {
  const _ExpenseCard({required this.expense, required this.trip});

  final Expense expense;
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd MMM', 'es').format(expense.date);
    final amountStr =
        '${expense.currency} ${expense.amount.toStringAsFixed(2)}';
    final description = expense.description?.isNotEmpty == true
        ? expense.description!
        : 'Gasto';
    final splitCount = expense.splitBetween.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: VamosSpacing.md),
      child: InkWell(
        borderRadius: VamosRadius.brLg,
        onTap: () => context.push(
          '/trips/${trip.id}/expenses/${expense.id}',
          extra: {'expense': expense, 'trip': trip},
        ),
        child: Card(
          margin: EdgeInsets.zero,
          shape: const RoundedRectangleBorder(
            borderRadius: VamosRadius.brLg,
            side: BorderSide(color: VamosColors.border),
          ),
          elevation: 0,
          color: VamosColors.surface,
          child: Padding(
            padding: const EdgeInsets.all(VamosSpacing.md),
            child: Row(
              children: [
                // Date badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: VamosSpacing.sm,
                    vertical: VamosSpacing.xs,
                  ),
                  decoration: const BoxDecoration(
                    color: VamosColors.bg,
                    borderRadius: VamosRadius.brMd,
                  ),
                  child: Text(dateStr, style: VamosTypography.overline),
                ),
                const SizedBox(width: VamosSpacing.md),
                // Description + split
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(description, style: VamosTypography.titleMedium),
                      const SizedBox(height: VamosSpacing.xs),
                      Text(
                        'Pagó · ${_shortenId(expense.paidBy)} · $splitCount personas',
                        style: VamosTypography.caption,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: VamosSpacing.sm),
                // Amount
                Text(amountStr, style: VamosTypography.monoMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Shows only the first 8 chars of a userId for brevity in MVP.
  /// In v1.1 this will be replaced by member aliases.
  String _shortenId(String uid) =>
      uid.length > 8 ? uid.substring(0, 8) : uid;
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(VamosSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: VamosSpacing.xxxl,
              color: VamosColors.textMuted,
            ),
            const SizedBox(height: VamosSpacing.md),
            Text(
              'Acá no hay gastos todavía.',
              style: VamosTypography.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: VamosSpacing.sm),
            Text(
              'Agregá el primer gasto del viaje y el grupo lo va a ver al instante.',
              style: VamosTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: VamosSpacing.lg),
            FilledButton(
              onPressed: onAdd,
              style: FilledButton.styleFrom(
                backgroundColor: VamosColors.sol500,
                foregroundColor: VamosColors.textOnDark,
                shape: const RoundedRectangleBorder(
                  borderRadius: VamosRadius.brFull,
                ),
              ),
              child: const Text('Agregar gasto'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error state
// ---------------------------------------------------------------------------

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

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
              'No se pudieron cargar los gastos.',
              style: VamosTypography.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: VamosSpacing.sm),
            Text(
              'Verificá tu conexión e intentá de nuevo.',
              style: VamosTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: VamosSpacing.lg),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                shape: const RoundedRectangleBorder(
                  borderRadius: VamosRadius.brFull,
                ),
              ),
              child: const Text('Intentá de nuevo'),
            ),
          ],
        ),
      ),
    );
  }
}
