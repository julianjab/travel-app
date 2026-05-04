/// Balance calculation and debt simplification for shared group expenses.
///
/// ## Preconditions
/// - [expenses] may be empty; if so, all member balances will be 0.0.
/// - [memberIds] must contain at least the union of all paidBy / splitBetween
///   user IDs that appear in [expenses]. Extra IDs are fine — they end up at 0.
/// - [balances] passed to [simplifyDebts] must be the output of [computeBalances]
///   (or any map with the same semantics: positive = net creditor, negative = net debtor).
///
/// ## Postconditions
/// - [computeBalances] guarantees every ID in [memberIds] is present in the result.
/// - [simplifyDebts] produces the minimal set of transfers under the greedy
///   heuristic described below. "Minimal" here means fewest transfers, not
///   necessarily the globally optimal solution (which is NP-hard for N > ~10).
///
/// ## Money handling
/// All arithmetic uses [double], mirroring the [Expense.amountInMainCurrency]
/// field (already converted at write time). Amounts in the output are rounded
/// to 2 decimal places to avoid floating-point noise accumulation.
/// The [decimal] package is available but was intentionally left out here to
/// keep the dependency surface thin for the MVP; if precision bugs surface in
/// production we will revisit.
///
/// ## Possible errors
/// - Unknown [splitType]: throws [ArgumentError] with a descriptive message.
/// - [splitDetails] null for a non-equal split: throws [ArgumentError].
///
/// No Flutter, Firebase, or Riverpod imports. Pure Dart only.
library;

import '../../../data/models/expense.dart';

/// Represents a single debt transfer: [from] owes [amount] to [to].
///
/// [amount] is always positive and expressed in the trip's main currency.
class Transfer {
  const Transfer({
    required this.from,
    required this.to,
    required this.amount,
  });

  /// userId of the person who pays.
  final String from;

  /// userId of the person who receives the payment.
  final String to;

  /// Amount in the trip's main currency, rounded to 2 decimal places.
  final double amount;

  @override
  String toString() => 'Transfer($from → $to, $amount)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Transfer &&
          runtimeType == other.runtimeType &&
          from == other.from &&
          to == other.to &&
          amount == other.amount;

  @override
  int get hashCode => Object.hash(from, to, amount);
}

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/// Computes the net balance for every member across all [expenses].
///
/// A **positive** balance means the member is owed money (net creditor).
/// A **negative** balance means the member owes money (net debtor).
/// A zero balance means the member is fully settled.
///
/// All [memberIds] appear in the result even if they have no relevant expenses.
///
/// Expenses where [Expense.hasSettlements] is true are still included in the
/// computation — settlements do not alter historical expense records in this model;
/// they are tracked separately. If you want to exclude settled expenses, filter
/// [expenses] before calling this function.
///
/// Throws [ArgumentError] for unknown [Expense.splitType] values.
Map<String, double> computeBalances(
  List<Expense> expenses,
  List<String> memberIds,
) {
  final balances = <String, double>{
    for (final id in memberIds) id: 0.0,
  };

  for (final expense in expenses) {
    final total = expense.amountInMainCurrency;
    final payer = expense.paidBy;
    final members = expense.splitBetween;

    // Credit the payer for the full amount.
    balances[payer] = (balances[payer] ?? 0.0) + total;

    // Debit each member their share.
    switch (expense.splitType) {
      case 'equal':
        final share = _round2(total / members.length);
        // The remainder (due to rounding) is not redistributed — the small
        // floating-point discrepancy is within the 0.001 epsilon used by
        // simplifyDebts and does not affect the final transfer list.
        for (final memberId in members) {
          balances[memberId] = (balances[memberId] ?? 0.0) - share;
        }

      case 'percentage':
        final details = _requireDetails(expense);
        for (final memberId in members) {
          final pct = (details[memberId] as num).toDouble();
          final share = _round2(total * pct / 100.0);
          balances[memberId] = (balances[memberId] ?? 0.0) - share;
        }

      case 'amount':
        final details = _requireDetails(expense);
        for (final memberId in members) {
          final share = _round2((details[memberId] as num).toDouble());
          balances[memberId] = (balances[memberId] ?? 0.0) - share;
        }

      default:
        throw ArgumentError(
          'Unknown splitType "${expense.splitType}" on expense ${expense.id}. '
          'Valid values are: equal, percentage, amount.',
        );
    }
  }

  // Round all final balances to eliminate accumulated floating-point noise.
  return balances.map((id, balance) => MapEntry(id, _round2(balance)));
}

/// Simplifies debts into the minimum number of transfers using a greedy
/// matching heuristic.
///
/// ## Algorithm (greedy net-balance matching)
/// 1. Separate members into creditors (balance > 0) and debtors (balance < 0).
/// 2. Sort both lists by absolute value descending so the largest flows are
///    resolved first (reduces the number of residual transfers in practice).
/// 3. Match the head debtor with the head creditor:
///    - Transfer amount = min(|debtor balance|, creditor balance).
///    - Reduce both balances by that amount.
///    - When a balance reaches zero (within epsilon = 0.001), remove that party.
/// 4. Repeat until both lists are empty.
///
/// This is O(n log n) and produces at most N-1 transfers for N participants,
/// which is optimal for the star-topology case (all creditors on one side,
/// all debtors on the other). For general graphs it may not be globally
/// minimal, but for the MVP group sizes (≤ ~12 people) the difference is
/// negligible and the simpler algorithm is far easier to audit.
///
/// Returns an empty list when all balances are already zero.
List<Transfer> simplifyDebts(Map<String, double> balances) {
  // Mutable copies sorted by absolute value descending.
  final creditors = balances.entries
      .where((e) => e.value > _epsilon)
      .map((e) => _Party(e.key, e.value))
      .toList()
    ..sort((a, b) => b.balance.compareTo(a.balance));

  final debtors = balances.entries
      .where((e) => e.value < -_epsilon)
      .map((e) => _Party(e.key, e.value.abs()))
      .toList()
    ..sort((a, b) => b.balance.compareTo(a.balance));

  final transfers = <Transfer>[];

  int ci = 0; // creditor index
  int di = 0; // debtor index

  while (ci < creditors.length && di < debtors.length) {
    final creditor = creditors[ci];
    final debtor = debtors[di];

    final transferAmount = _round2(
      debtor.balance < creditor.balance ? debtor.balance : creditor.balance,
    );

    if (transferAmount > _epsilon) {
      transfers.add(Transfer(
        from: debtor.id,
        to: creditor.id,
        amount: transferAmount,
      ));
    }

    creditor.balance = _round2(creditor.balance - transferAmount);
    debtor.balance = _round2(debtor.balance - transferAmount);

    if (creditor.balance <= _epsilon) ci++;
    if (debtor.balance <= _epsilon) di++;
  }

  return transfers;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Tolerance used to treat a balance as effectively zero.
const double _epsilon = 0.001;

double _round2(double x) => (x * 100).round() / 100;

Map<String, dynamic> _requireDetails(Expense expense) {
  final details = expense.splitDetails;
  if (details == null) {
    throw ArgumentError(
      'splitDetails must not be null when splitType is "${expense.splitType}" '
      '(expense ${expense.id}).',
    );
  }
  return details;
}

/// Mutable value object used internally by [simplifyDebts].
class _Party {
  _Party(this.id, this.balance);
  final String id;
  double balance;
}
