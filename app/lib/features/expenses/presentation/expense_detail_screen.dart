import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:vamos/core/theme/vamos_colors.dart';
import 'package:vamos/core/theme/vamos_spacing.dart';
import 'package:vamos/core/theme/vamos_typography.dart';
import 'package:vamos/data/models/expense.dart';
import 'package:vamos/data/models/trip.dart';
import 'package:vamos/features/expenses/application/expense_actions_notifier.dart';
import 'package:vamos/features/trips/application/my_trips_notifier.dart';

/// F3-09 — Expense detail screen.
///
/// Shows all fields of an expense. Allows editing and deletion based on
/// the current user's role (creator or facilitator for edit; creator-only
/// for delete). Guards against editing expenses that have settlements.
class ExpenseDetailScreen extends ConsumerWidget {
  const ExpenseDetailScreen({
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

    // React to delete success/error.
    ref.listen<AsyncValue<void>>(expenseActionsProvider, (prev, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al eliminar el gasto. Intentá de nuevo.'),
          ),
        );
      } else if (next.hasValue && prev?.isLoading == true) {
        if (context.mounted) Navigator.of(context).pop();
      }
    });

    final canEdit = !expense.hasSettlements &&
        (currentUserId == expense.createdBy ||
            currentUserId == trip.facilitatorId);
    final canDelete = !expense.hasSettlements &&
        currentUserId == expense.createdBy;

    return Scaffold(
      backgroundColor: VamosColors.bg,
      appBar: AppBar(
        backgroundColor: VamosColors.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          expense.description?.isNotEmpty == true
              ? expense.description!
              : 'Gasto',
          style: VamosTypography.headlineMedium,
        ),
        actions: [
          if (canEdit)
            TextButton(
              onPressed: actionsState.isLoading
                  ? null
                  : () => context.push(
                        '/trips/$tripId/expenses/${expense.id}/edit',
                        extra: {'expense': expense, 'trip': trip},
                      ),
              child: Text(
                'Editar',
                style: VamosTypography.bodyMedium.copyWith(
                  color: VamosColors.sol500,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(VamosSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Settlement warning banner ---
            if (expense.hasSettlements)
              _WarningBanner(
                text: 'Este gasto ya fue saldado y no se puede editar.',
              ),

            // --- Main info card ---
            _InfoCard(expense: expense, trip: trip),
            const SizedBox(height: VamosSpacing.md),

            // --- Split breakdown ---
            _SplitCard(expense: expense),
            const SizedBox(height: VamosSpacing.md),

            // --- Edit history ---
            if (expense.editHistory.isNotEmpty) ...[
              _EditHistoryCard(history: expense.editHistory),
              const SizedBox(height: VamosSpacing.md),
            ],

            // --- Destructive action ---
            if (canDelete) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: actionsState.isLoading
                      ? null
                      : () => _confirmDelete(context, ref),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: VamosColors.red,
                    side: const BorderSide(color: VamosColors.red),
                    shape: const RoundedRectangleBorder(
                      borderRadius: VamosRadius.brFull,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: VamosSpacing.md,
                    ),
                  ),
                  child: actionsState.isLoading
                      ? const SizedBox(
                          height: VamosSpacing.md,
                          width: VamosSpacing.md,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Eliminar gasto'),
                ),
              ),
              const SizedBox(height: VamosSpacing.lg),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: VamosColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: VamosRadius.brDialog,
        ),
        title: Text('¿Eliminar gasto?', style: VamosTypography.titleMedium),
        content: Text(
          'Esta acción no se puede deshacer. El gasto se va a eliminar para todo el grupo.',
          style: VamosTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: VamosColors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(expenseActionsProvider.notifier).delete(
            tripId: tripId,
            expenseId: expense.id,
          );
    }
  }
}

// ---------------------------------------------------------------------------
// Info card
// ---------------------------------------------------------------------------

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.expense, required this.trip});

  final Expense expense;
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final dateStr =
        DateFormat('dd/MM/yyyy', 'es').format(expense.date);
    final showConversion = expense.currency != trip.mainCurrency;

    return Card(
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(
        borderRadius: VamosRadius.brLg,
        side: BorderSide(color: VamosColors.border),
      ),
      elevation: 0,
      color: VamosColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(VamosSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Row(
              label: 'Monto',
              value:
                  '${expense.currency} ${expense.amount.toStringAsFixed(2)}',
              valueStyle: VamosTypography.monoLarge,
            ),
            if (showConversion) ...[
              const SizedBox(height: VamosSpacing.xs),
              _Row(
                label: 'En ${trip.mainCurrency}',
                value: expense.amountInMainCurrency.toStringAsFixed(2),
              ),
              const SizedBox(height: VamosSpacing.xs),
              _Row(
                label: 'Tasa',
                value: expense.exchangeRate.toString(),
              ),
            ],
            const SizedBox(height: VamosSpacing.sm),
            _Row(label: 'Pagó', value: _shortenId(expense.paidBy)),
            const SizedBox(height: VamosSpacing.xs),
            _Row(label: 'Fecha', value: dateStr),
          ],
        ),
      ),
    );
  }

  String _shortenId(String uid) =>
      uid.length > 16 ? uid.substring(0, 16) : uid;
}

// ---------------------------------------------------------------------------
// Split breakdown card
// ---------------------------------------------------------------------------

class _SplitCard extends StatelessWidget {
  const _SplitCard({required this.expense});

  final Expense expense;

  @override
  Widget build(BuildContext context) {
    final splitLabel = switch (expense.splitType) {
      'percentage' => 'Por porcentajes',
      'amount' => 'Por montos',
      _ => 'Partes iguales',
    };

    return Card(
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(
        borderRadius: VamosRadius.brLg,
        side: BorderSide(color: VamosColors.border),
      ),
      elevation: 0,
      color: VamosColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(VamosSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('División', style: VamosTypography.caption),
                const SizedBox(width: VamosSpacing.sm),
                Text(splitLabel, style: VamosTypography.overline),
              ],
            ),
            const SizedBox(height: VamosSpacing.sm),
            ...expense.splitBetween.map((uid) {
              String detail = '';
              if (expense.splitType == 'percentage') {
                final pct =
                    expense.splitDetails?[uid]?.toString() ?? '-';
                detail = '$pct%';
              } else if (expense.splitType == 'amount') {
                final amt =
                    expense.splitDetails?[uid]?.toString() ?? '-';
                detail = amt;
              } else {
                final share =
                    expense.amountInMainCurrency / expense.splitBetween.length;
                detail = share.toStringAsFixed(2);
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: VamosSpacing.xs),
                child: _Row(
                  label: _shortenId(uid),
                  value: detail,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _shortenId(String uid) =>
      uid.length > 16 ? uid.substring(0, 16) : uid;
}

// ---------------------------------------------------------------------------
// Edit history card
// ---------------------------------------------------------------------------

class _EditHistoryCard extends StatelessWidget {
  const _EditHistoryCard({required this.history});

  final List<Map<String, dynamic>> history;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(
        borderRadius: VamosRadius.brLg,
        side: BorderSide(color: VamosColors.border),
      ),
      elevation: 0,
      color: VamosColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(VamosSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Historial de ediciones', style: VamosTypography.caption),
            const SizedBox(height: VamosSpacing.sm),
            ...history.map((entry) {
              final by = (entry['changedBy'] as String?) ?? '-';
              final at = entry['changedAt'];
              String dateStr = '-';
              if (at is DateTime) {
                dateStr = DateFormat('dd/MM/yyyy HH:mm').format(at);
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: VamosSpacing.xs),
                child: Text(
                  'Editado por ${_shortenId(by)} · $dateStr',
                  style: VamosTypography.caption,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _shortenId(String uid) =>
      uid.length > 16 ? uid.substring(0, 16) : uid;
}

// ---------------------------------------------------------------------------
// Warning banner
// ---------------------------------------------------------------------------

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: VamosSpacing.md),
      padding: const EdgeInsets.all(VamosSpacing.md),
      decoration: const BoxDecoration(
        color: VamosColors.surface2,
        borderRadius: VamosRadius.brLg,
        border: Border.fromBorderSide(
          BorderSide(color: VamosColors.warning),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: VamosColors.warning, size: VamosSpacing.md),
          const SizedBox(width: VamosSpacing.sm),
          Expanded(
            child: Text(text, style: VamosTypography.caption),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Label–value row helper
// ---------------------------------------------------------------------------

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.valueStyle});

  final String label;
  final String value;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: VamosSpacing.xxxl + VamosSpacing.md,
          child: Text(label, style: VamosTypography.caption),
        ),
        Expanded(
          child: Text(
            value,
            style: valueStyle ?? VamosTypography.monoMedium,
          ),
        ),
      ],
    );
  }
}
