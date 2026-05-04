import 'package:vamos/data/models/expense.dart';
import 'package:vamos/data/repositories/expense_repository.dart';

/// In-memory [ExpenseRepository] for tests and dev stubs.
///
/// Backed by a mutable list. Call [setExpenses] before your test to inject
/// the desired fixture set, then override the provider in [ProviderScope]:
///
/// ```dart
/// final mock = MockExpenseRepository();
/// mock.setExpenses([expense1, expense2]);
///
/// await tester.pumpWidget(
///   ProviderScope(
///     overrides: [
///       expenseRepositoryProvider.overrideWithValue(mock),
///     ],
///     child: MaterialApp.router(routerConfig: router),
///   ),
/// );
/// ```
///
/// [watchTripExpenses] emits [_expenses] once synchronously.
/// Call [setExpenses] again to push a new emission if your test mutates state.
class MockExpenseRepository implements ExpenseRepository {
  final List<Expense> _expenses = [];

  /// Replaces the current fixture set.
  void setExpenses(List<Expense> expenses) {
    _expenses
      ..clear()
      ..addAll(expenses);
  }

  @override
  Stream<List<Expense>> watchTripExpenses(String tripId) {
    return Stream.value(List<Expense>.from(_expenses));
  }

  @override
  Future<void> createExpense({
    required String tripId,
    required Expense expense,
  }) async {
    _expenses.add(expense);
  }

  @override
  Future<void> updateExpense({
    required String tripId,
    required Expense expense,
  }) async {
    final index = _expenses.indexWhere((e) => e.id == expense.id);
    if (index != -1) {
      _expenses[index] = expense;
    }
  }

  @override
  Future<void> deleteExpense({
    required String tripId,
    required String expenseId,
  }) async {
    _expenses.removeWhere((e) => e.id == expenseId);
  }

  /// No-op settlement — mock does not track settlement state.
  @override
  Future<void> createSettlement({
    required String tripId,
    required String fromUserId,
    required String toUserId,
    required double amount,
    required String currency,
    required String createdBy,
  }) async {}
}
