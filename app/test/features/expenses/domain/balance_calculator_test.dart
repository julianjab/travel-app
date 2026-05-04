import 'package:flutter_test/flutter_test.dart';
import 'package:vamos/data/models/expense.dart';
import 'package:vamos/features/expenses/domain/balance_calculator.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Expense _makeExpense({
  required String id,
  required double amount,
  required String paidBy,
  required List<String> splitBetween,
  String splitType = 'equal',
  Map<String, dynamic>? splitDetails,
  double exchangeRate = 1.0,
  double? amountInMainCurrency,
}) {
  return Expense(
    id: id,
    amount: amount,
    currency: 'COP',
    exchangeRate: exchangeRate,
    amountInMainCurrency: amountInMainCurrency ?? amount * exchangeRate,
    paidBy: paidBy,
    splitBetween: splitBetween,
    splitType: splitType,
    splitDetails: splitDetails,
    date: DateTime(2025, 6, 1),
    createdAt: DateTime(2025, 6, 1),
    createdBy: paidBy,
    hasSettlements: false,
    editHistory: const [],
  );
}

// ---------------------------------------------------------------------------
// computeBalances — equal split
// ---------------------------------------------------------------------------

void main() {
  group('computeBalances — equal split', () {
    test('single expense: payer credited, others debited equally', () {
      // A paid 90, split evenly between A, B, C.
      // Each share = 30.
      // A net = +90 - 30 = +60
      // B net = -30
      // C net = -30
      final expense = _makeExpense(
        id: 'e1',
        amount: 90,
        paidBy: 'A',
        splitBetween: ['A', 'B', 'C'],
      );

      final balances = computeBalances([expense], ['A', 'B', 'C']);

      expect(balances['A'], closeTo(60.0, 0.01));
      expect(balances['B'], closeTo(-30.0, 0.01));
      expect(balances['C'], closeTo(-30.0, 0.01));
    });

    test('all members in result even when they have no expenses', () {
      final expense = _makeExpense(
        id: 'e1',
        amount: 100,
        paidBy: 'A',
        splitBetween: ['A', 'B'],
      );

      final balances = computeBalances([expense], ['A', 'B', 'C', 'D']);

      expect(balances.containsKey('C'), isTrue);
      expect(balances.containsKey('D'), isTrue);
      expect(balances['C'], 0.0);
      expect(balances['D'], 0.0);
    });

    test('two cross-payment expenses settle to a single net transfer', () {
      // Expense 1: A paid 60, split A+B → each owes 30.
      //   A net so far: +60-30 = +30, B net so far: -30
      // Expense 2: B paid 40, split A+B → each owes 20.
      //   A net: +30-20 = +10, B net: -30+40-20 = -10
      final e1 = _makeExpense(
        id: 'e1',
        amount: 60,
        paidBy: 'A',
        splitBetween: ['A', 'B'],
      );
      final e2 = _makeExpense(
        id: 'e2',
        amount: 40,
        paidBy: 'B',
        splitBetween: ['A', 'B'],
      );

      final balances = computeBalances([e1, e2], ['A', 'B']);

      expect(balances['A'], closeTo(10.0, 0.01));
      expect(balances['B'], closeTo(-10.0, 0.01));
    });

    test('payer not in splitBetween: full amount is a net credit', () {
      // C paid 120 but is not in the split; A and B each owe 60.
      final expense = _makeExpense(
        id: 'e1',
        amount: 120,
        paidBy: 'C',
        splitBetween: ['A', 'B'],
      );

      final balances = computeBalances([expense], ['A', 'B', 'C']);

      expect(balances['C'], closeTo(120.0, 0.01));
      expect(balances['A'], closeTo(-60.0, 0.01));
      expect(balances['B'], closeTo(-60.0, 0.01));
    });

    test('empty expense list returns zero balances for all members', () {
      final balances = computeBalances([], ['A', 'B', 'C']);

      expect(balances['A'], 0.0);
      expect(balances['B'], 0.0);
      expect(balances['C'], 0.0);
    });

    test('single member group: paid and owes same → net zero', () {
      final expense = _makeExpense(
        id: 'e1',
        amount: 50,
        paidBy: 'A',
        splitBetween: ['A'],
      );

      final balances = computeBalances([expense], ['A']);

      expect(balances['A'], closeTo(0.0, 0.01));
    });

    test('zero-amount expense produces no net movement', () {
      final expense = _makeExpense(
        id: 'e1',
        amount: 0,
        paidBy: 'A',
        splitBetween: ['A', 'B'],
      );

      final balances = computeBalances([expense], ['A', 'B']);

      expect(balances['A'], 0.0);
      expect(balances['B'], 0.0);
    });
  });

  // ---------------------------------------------------------------------------
  // computeBalances — percentage split
  // ---------------------------------------------------------------------------

  group('computeBalances — percentage split', () {
    test('70/30 percentage split produces correct net balances', () {
      // A paid 100. A owes 70%, B owes 30%.
      // A net = +100 - 70 = +30, B net = -30.
      final expense = _makeExpense(
        id: 'e1',
        amount: 100,
        paidBy: 'A',
        splitBetween: ['A', 'B'],
        splitType: 'percentage',
        splitDetails: {'A': 70.0, 'B': 30.0},
      );

      final balances = computeBalances([expense], ['A', 'B']);

      expect(balances['A'], closeTo(30.0, 0.01));
      expect(balances['B'], closeTo(-30.0, 0.01));
    });

    test('unequal three-way percentage split', () {
      // A paid 200. A:50%, B:30%, C:20%.
      // A net = +200 - 100 = +100, B net = -60, C net = -40.
      final expense = _makeExpense(
        id: 'e1',
        amount: 200,
        paidBy: 'A',
        splitBetween: ['A', 'B', 'C'],
        splitType: 'percentage',
        splitDetails: {'A': 50.0, 'B': 30.0, 'C': 20.0},
      );

      final balances = computeBalances([expense], ['A', 'B', 'C']);

      expect(balances['A'], closeTo(100.0, 0.01));
      expect(balances['B'], closeTo(-60.0, 0.01));
      expect(balances['C'], closeTo(-40.0, 0.01));
    });
  });

  // ---------------------------------------------------------------------------
  // computeBalances — amount split
  // ---------------------------------------------------------------------------

  group('computeBalances — amount split', () {
    test('explicit amounts produce correct net balances', () {
      // A paid 150. A owes 80, B owes 70 (explicit amounts).
      // A net = +150 - 80 = +70, B net = -70.
      final expense = _makeExpense(
        id: 'e1',
        amount: 150,
        paidBy: 'A',
        splitBetween: ['A', 'B'],
        splitType: 'amount',
        splitDetails: {'A': 80.0, 'B': 70.0},
      );

      final balances = computeBalances([expense], ['A', 'B']);

      expect(balances['A'], closeTo(70.0, 0.01));
      expect(balances['B'], closeTo(-70.0, 0.01));
    });
  });

  // ---------------------------------------------------------------------------
  // computeBalances — currency conversion via amountInMainCurrency
  // ---------------------------------------------------------------------------

  group('computeBalances — currency via amountInMainCurrency', () {
    test('expense in foreign currency uses amountInMainCurrency for arithmetic',
        () {
      // Expense: 100 BRL at 0.5 COP/BRL → amountInMainCurrency = 50 COP.
      // A paid, split equally between A and B → each share 25 COP.
      // A net = +50 - 25 = +25, B net = -25.
      final expense = _makeExpense(
        id: 'e1',
        amount: 100,
        paidBy: 'A',
        splitBetween: ['A', 'B'],
        exchangeRate: 0.5,
        amountInMainCurrency: 50.0,
      );

      final balances = computeBalances([expense], ['A', 'B']);

      expect(balances['A'], closeTo(25.0, 0.01));
      expect(balances['B'], closeTo(-25.0, 0.01));
    });
  });

  // ---------------------------------------------------------------------------
  // computeBalances — error cases
  // ---------------------------------------------------------------------------

  group('computeBalances — errors', () {
    test('unknown splitType throws ArgumentError', () {
      final expense = _makeExpense(
        id: 'e1',
        amount: 100,
        paidBy: 'A',
        splitBetween: ['A', 'B'],
        splitType: 'invalid_type',
      );

      expect(
        () => computeBalances([expense], ['A', 'B']),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('null splitDetails for percentage split throws ArgumentError', () {
      final expense = _makeExpense(
        id: 'e1',
        amount: 100,
        paidBy: 'A',
        splitBetween: ['A', 'B'],
        splitType: 'percentage',
        splitDetails: null,
      );

      expect(
        () => computeBalances([expense], ['A', 'B']),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // simplifyDebts
  // ---------------------------------------------------------------------------

  group('simplifyDebts — happy path', () {
    test('single expense equal split: two direct transfers', () {
      // After computeBalances: A +60, B -30, C -30.
      // Simplified: B→A 30, C→A 30.
      final balances = {'A': 60.0, 'B': -30.0, 'C': -30.0};
      final transfers = simplifyDebts(balances);

      expect(transfers.length, 2);
      expect(transfers.every((t) => t.to == 'A'), isTrue);
      final froms = transfers.map((t) => t.from).toSet();
      expect(froms, containsAll(['B', 'C']));
      expect(transfers.every((t) => (t.amount - 30.0).abs() < 0.01), isTrue);
    });

    test('two-expense cross-payments: one net transfer', () {
      // A +10, B -10 → B→A 10.
      final balances = {'A': 10.0, 'B': -10.0};
      final transfers = simplifyDebts(balances);

      expect(transfers.length, 1);
      expect(transfers.first.from, 'B');
      expect(transfers.first.to, 'A');
      expect(transfers.first.amount, closeTo(10.0, 0.01));
    });

    test('already balanced: empty transfer list', () {
      final balances = {'A': 0.0, 'B': 0.0, 'C': 0.0};
      final transfers = simplifyDebts(balances);

      expect(transfers, isEmpty);
    });

    test('empty balances map: empty transfer list', () {
      final transfers = simplifyDebts({});
      expect(transfers, isEmpty);
    });

    test('four members: minimizes transfer count', () {
      // A +30, B +10, C -20, D -20.
      // Greedy (sorted desc):
      //   creditors: A(30), B(10) — debtors: C(20), D(20)
      //   Step 1: C(-20) vs A(+30) → C→A 20, A residual +10, C done.
      //   Step 2: D(-20) vs A(+10) → D→A 10, A done, D residual -10.
      //   Step 3: D(-10) vs B(+10) → D→B 10, both done.
      //   Total: 3 transfers.
      final balances = {'A': 30.0, 'B': 10.0, 'C': -20.0, 'D': -20.0};
      final transfers = simplifyDebts(balances);

      expect(transfers.length, 3);

      // Verify the net flow is correct for each recipient.
      double aReceives = transfers
          .where((t) => t.to == 'A')
          .fold(0.0, (sum, t) => sum + t.amount);
      double bReceives = transfers
          .where((t) => t.to == 'B')
          .fold(0.0, (sum, t) => sum + t.amount);
      double cPays = transfers
          .where((t) => t.from == 'C')
          .fold(0.0, (sum, t) => sum + t.amount);
      double dPays = transfers
          .where((t) => t.from == 'D')
          .fold(0.0, (sum, t) => sum + t.amount);

      expect(aReceives, closeTo(30.0, 0.01));
      expect(bReceives, closeTo(10.0, 0.01));
      expect(cPays, closeTo(20.0, 0.01));
      expect(dPays, closeTo(20.0, 0.01));
    });

    test('circular debt (A→B→C→A) resolves without hanging', () {
      // Circular debts can arise when A overpays relative to B, B relative to C,
      // and C relative to A. Net balances will still be consistent.
      // e.g. A +10, B 0, C -10 → C→A 10 (1 transfer).
      final balances = {'A': 10.0, 'B': 0.0, 'C': -10.0};
      final transfers = simplifyDebts(balances);

      expect(transfers.length, 1);
      expect(transfers.first.from, 'C');
      expect(transfers.first.to, 'A');
      expect(transfers.first.amount, closeTo(10.0, 0.01));
    });

    test('percentage split end-to-end: computeBalances → simplifyDebts', () {
      // A paid 100, 70% A / 30% B → B→A 30.
      final expense = _makeExpense(
        id: 'e1',
        amount: 100,
        paidBy: 'A',
        splitBetween: ['A', 'B'],
        splitType: 'percentage',
        splitDetails: {'A': 70.0, 'B': 30.0},
      );

      final balances = computeBalances([expense], ['A', 'B']);
      final transfers = simplifyDebts(balances);

      expect(transfers.length, 1);
      expect(transfers.first.from, 'B');
      expect(transfers.first.to, 'A');
      expect(transfers.first.amount, closeTo(30.0, 0.01));
    });

    test('all transfers have positive amounts', () {
      final balances = {'A': 50.0, 'B': -20.0, 'C': -30.0};
      final transfers = simplifyDebts(balances);

      for (final t in transfers) {
        expect(t.amount, greaterThan(0.0));
      }
    });

    test('single creditor single debtor: one direct transfer', () {
      final balances = {'A': 75.0, 'B': -75.0};
      final transfers = simplifyDebts(balances);

      expect(transfers.length, 1);
      expect(transfers.first.from, 'B');
      expect(transfers.first.to, 'A');
      expect(transfers.first.amount, closeTo(75.0, 0.01));
    });
  });
}
