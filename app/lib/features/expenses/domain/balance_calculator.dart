import 'package:vamos/data/models/expense.dart';

/// Represents a suggested debt transfer between two trip members.
class Transfer {
  const Transfer({
    required this.from,
    required this.to,
    required this.amount,
  });

  /// userId who owes money.
  final String from;

  /// userId who is owed money.
  final String to;

  /// Amount owed in the trip's main currency.
  final double amount;
}

/// Computes each member's net balance across all [expenses].
///
/// A positive balance means the member is owed money.
/// A negative balance means the member owes money.
/// Zero means the member is square.
///
/// Note: this is a placeholder stub. The real implementation from F3-01
/// (domain-logic agent) will replace this when its PR merges. The stub returns
/// an empty map so the UI can compile and render gracefully until then.
Map<String, double> computeBalances(
  List<Expense> expenses,
  List<String> memberIds,
) {
  // Initialize all members to zero.
  final balances = <String, double>{
    for (final id in memberIds) id: 0.0,
  };

  for (final expense in expenses) {
    final splitCount = expense.splitBetween.length;
    if (splitCount == 0) continue;

    if (expense.splitType == 'equal') {
      final share = expense.amountInMainCurrency / splitCount;
      // Payer receives credit for the full amount.
      balances[expense.paidBy] =
          (balances[expense.paidBy] ?? 0) + expense.amountInMainCurrency;
      // Each participant (including payer) owes their share.
      for (final uid in expense.splitBetween) {
        balances[uid] = (balances[uid] ?? 0) - share;
      }
    } else if (expense.splitType == 'percentage') {
      final details = expense.splitDetails ?? {};
      balances[expense.paidBy] =
          (balances[expense.paidBy] ?? 0) + expense.amountInMainCurrency;
      for (final uid in expense.splitBetween) {
        final pct = (details[uid] as num?)?.toDouble() ?? 0.0;
        final share = expense.amountInMainCurrency * pct / 100;
        balances[uid] = (balances[uid] ?? 0) - share;
      }
    } else if (expense.splitType == 'amount') {
      final details = expense.splitDetails ?? {};
      balances[expense.paidBy] =
          (balances[expense.paidBy] ?? 0) + expense.amountInMainCurrency;
      for (final uid in expense.splitBetween) {
        final share = (details[uid] as num?)?.toDouble() ?? 0.0;
        balances[uid] = (balances[uid] ?? 0) - share;
      }
    }
  }

  return balances;
}

/// Simplifies the net balances into a minimal list of [Transfer]s.
///
/// Uses the greedy creditor-debtor algorithm: at each step, the largest
/// debtor pays the largest creditor. This minimizes the number of transfers.
///
/// Note: placeholder stub — the real implementation (F3-01) replaces this.
List<Transfer> simplifyDebts(Map<String, double> balances) {
  const epsilon = 0.01; // ignore rounding noise below 1 cent

  final creditors = <MapEntry<String, double>>[];
  final debtors = <MapEntry<String, double>>[];

  for (final entry in balances.entries) {
    if (entry.value > epsilon) {
      creditors.add(entry);
    } else if (entry.value < -epsilon) {
      debtors.add(entry);
    }
  }

  // Sort: largest creditor first, largest debtor first.
  creditors.sort((a, b) => b.value.compareTo(a.value));
  debtors.sort((a, b) => a.value.compareTo(b.value));

  final transfers = <Transfer>[];
  final creditAmounts = {for (final e in creditors) e.key: e.value};
  final debtAmounts = {for (final e in debtors) e.key: e.value};

  final creditQueue = List<String>.from(creditors.map((e) => e.key));
  final debtQueue = List<String>.from(debtors.map((e) => e.key));

  var ci = 0;
  var di = 0;

  while (ci < creditQueue.length && di < debtQueue.length) {
    final creditor = creditQueue[ci];
    final debtor = debtQueue[di];
    final credit = creditAmounts[creditor]!;
    final debt = -debtAmounts[debtor]!;

    final settled = credit < debt ? credit : debt;
    transfers.add(Transfer(from: debtor, to: creditor, amount: settled));

    creditAmounts[creditor] = credit - settled;
    debtAmounts[debtor] = debtAmounts[debtor]! + settled;

    if (creditAmounts[creditor]! < epsilon) ci++;
    if (-debtAmounts[debtor]! < epsilon) di++;
  }

  return transfers;
}
