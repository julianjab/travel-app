import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vamos/core/theme/vamos_colors.dart';
import 'package:vamos/core/theme/vamos_spacing.dart';
import 'package:vamos/core/theme/vamos_typography.dart';
import 'package:vamos/core/utils/snackbar_utils.dart';
import 'package:vamos/data/models/expense.dart';
import 'package:vamos/data/models/trip.dart';
import 'package:vamos/features/expenses/application/expense_actions_notifier.dart';
import 'package:vamos/features/expenses/application/expenses_notifier.dart';
import 'package:vamos/features/expenses/domain/balance_calculator.dart';
import 'package:vamos/features/trips/application/my_trips_notifier.dart';
import 'package:vamos/shared/widgets/loading_indicator.dart';

/// F3-10/F3-11 — Balances screen.
///
/// Computes each member's net balance using [computeBalances] from the
/// domain layer, then shows [simplifyDebts] as suggested transfers.
/// A "Saldar" button next to each transfer calls [ExpenseActionsNotifier.settle].
class BalancesScreen extends ConsumerWidget {
  const BalancesScreen({
    super.key,
    required this.tripId,
    required this.trip,
  });

  final String tripId;
  final Trip trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider(tripId));
    final actionsState = ref.watch(expenseActionsProvider);

    ref.listen<AsyncValue<void>>(expenseActionsProvider, (prev, next) {
      next.whenOrNull(
        error: (e, _) {
          if (context.mounted) showErrorSnackBar(context);
        },
      );
      if (next.hasValue && prev?.isLoading == true) {
        if (context.mounted) showSuccessSnackBar(context, 'Deuda saldada');
      }
    });

    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        title: Text('Saldos del viaje', style: VamosTypography.headlineMedium),
      ),
      body: expensesAsync.when(
        loading: () => const VamosLoadingIndicator(),
        error: (err, _) => _ErrorState(
          onRetry: () => ref.invalidate(expensesProvider(tripId)),
        ),
        data: (expenses) => _BalancesBody(
          expenses: expenses,
          trip: trip,
          tripId: tripId,
          isSettling: actionsState.isLoading,
          onSettle: (transfer) {
            final currentUserId = ref.read(currentUserIdProvider);
            ref.read(expenseActionsProvider.notifier).settle(
                  tripId: tripId,
                  fromUserId: transfer.from,
                  toUserId: transfer.to,
                  amount: transfer.amount,
                  currency: trip.mainCurrency,
                  createdBy: currentUserId,
                );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body when data is loaded
// ---------------------------------------------------------------------------

class _BalancesBody extends StatelessWidget {
  const _BalancesBody({
    required this.expenses,
    required this.trip,
    required this.tripId,
    required this.isSettling,
    required this.onSettle,
  });

  final List<Expense> expenses;
  final Trip trip;
  final String tripId;
  final bool isSettling;
  final ValueChanged<Transfer> onSettle;

  @override
  Widget build(BuildContext context) {
    final balances = computeBalances(expenses, trip.memberIds);
    final transfers = simplifyDebts(balances);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(VamosSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Per-member balances ---
          Text('Balance por integrante', style: VamosTypography.caption),
          const SizedBox(height: VamosSpacing.sm),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(VamosSpacing.md),
              child: Column(
                children: trip.memberIds.map((uid) {
                  final balance = balances[uid] ?? 0.0;
                  return _BalanceRow(
                    uid: uid,
                    balance: balance,
                    currency: trip.mainCurrency,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: VamosSpacing.lg),

          // --- Suggested transfers ---
          // §5.8: header only shown when there are transfers pending.
          // §5.6: no expenses yet → "Acá no hay nada todavía."
          // §5.7: expenses exist but everyone is even → "Todos quedaron parejos."
          if (transfers.isNotEmpty) ...[
            Text(
              'Para que todos queden parejos, estas son las transferencias más cortas:',
              style: VamosTypography.caption,
            ),
            const SizedBox(height: VamosSpacing.sm),
          ],
          if (transfers.isEmpty)
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(VamosSpacing.md),
                child: Row(
                  children: [
                    Icon(
                      expenses.isEmpty
                          ? Icons.hourglass_empty_outlined
                          : Icons.check_circle_outline,
                      color: expenses.isEmpty
                          ? VamosColors.text3
                          : VamosColors.green,
                      size: VamosSpacing.md,
                    ),
                    const SizedBox(width: VamosSpacing.sm),
                    Expanded(
                      child: Text(
                        // §5.6 — no expenses at all (nothing to settle yet)
                        // §5.7 — expenses exist but everyone is even
                        expenses.isEmpty
                            ? 'Acá no hay nada todavía.\n\nCuando haya gastos para saldar, las transferencias aparecen acá.'
                            : 'Todos quedaron parejos.',
                        style: VamosTypography.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: VamosSpacing.xs),
                child: Column(
                  children: transfers.asMap().entries.map((entry) {
                    final i = entry.key;
                    final t = entry.value;
                    return Column(
                      children: [
                        _TransferRow(
                          transfer: t,
                          currency: trip.mainCurrency,
                          isSettling: isSettling,
                          onSettle: () => onSettle(t),
                        ),
                        if (i < transfers.length - 1)
                          const Divider(
                            height: 1,
                            indent: VamosSpacing.md,
                            endIndent: VamosSpacing.md,
                            color: VamosColors.border,
                          ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          const SizedBox(height: VamosSpacing.lg),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Balance row per member
// ---------------------------------------------------------------------------

class _BalanceRow extends StatelessWidget {
  const _BalanceRow({
    required this.uid,
    required this.balance,
    required this.currency,
  });

  final String uid;
  final double balance;
  final String currency;

  @override
  Widget build(BuildContext context) {
    const epsilon = 0.01;
    final isPositive = balance > epsilon;
    final isNegative = balance < -epsilon;

    final color = isPositive
        ? VamosColors.green
        : isNegative
            ? VamosColors.red
            : VamosColors.text3;

    final sign = isPositive ? '+' : '';
    final balanceStr = '$sign${balance.toStringAsFixed(2)} $currency';

    final statusLabel = isPositive
        ? 'te deben'
        : isNegative
            ? 'debés'
            : 'al día';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: VamosSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_shortenId(uid), style: VamosTypography.bodyMedium),
                Text(statusLabel, style: VamosTypography.overline),
              ],
            ),
          ),
          Text(
            balanceStr,
            style: VamosTypography.monoMedium.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  String _shortenId(String uid) =>
      uid.length > 16 ? uid.substring(0, 16) : uid;
}

// ---------------------------------------------------------------------------
// Transfer row with settle action
// ---------------------------------------------------------------------------

class _TransferRow extends StatelessWidget {
  const _TransferRow({
    required this.transfer,
    required this.currency,
    required this.isSettling,
    required this.onSettle,
  });

  final Transfer transfer;
  final String currency;
  final bool isSettling;
  final VoidCallback onSettle;

  @override
  Widget build(BuildContext context) {
    final amountStr = '${transfer.amount.toStringAsFixed(2)} $currency';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: VamosSpacing.md,
        vertical: VamosSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: RichText(
              text: TextSpan(
                style: VamosTypography.bodyMedium,
                children: [
                  TextSpan(text: _shortenId(transfer.from)),
                  const TextSpan(
                    text: ' le debe a ',
                    style: TextStyle(color: VamosColors.text3),
                  ),
                  TextSpan(text: _shortenId(transfer.to)),
                  const TextSpan(text: ': '),
                  TextSpan(
                    text: amountStr,
                    style: VamosTypography.monoMedium.copyWith(
                      color: VamosColors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: VamosSpacing.sm),
          FilledButton(
            onPressed: isSettling ? null : onSettle,
            style: FilledButton.styleFrom(
              backgroundColor: VamosColors.green,
              foregroundColor: VamosColors.textOnDark,
              disabledBackgroundColor: VamosColors.border,
              shape: const RoundedRectangleBorder(
                borderRadius: VamosRadius.brFull,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: VamosSpacing.md,
                vertical: VamosSpacing.xs,
              ),
              textStyle: VamosTypography.caption,
            ),
            child: const Text('Saldar'),
          ),
        ],
      ),
    );
  }

  String _shortenId(String uid) =>
      uid.length > 14 ? uid.substring(0, 14) : uid;
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
              'No se pudieron cargar los saldos.',
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
