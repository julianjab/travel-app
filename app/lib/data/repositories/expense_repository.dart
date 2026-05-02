import 'package:vamos/data/models/expense.dart';

/// Abstract contract for the expenses data source.
///
/// Consumers (notifiers, widgets) depend on this type — never on
/// FirestoreExpenseRepository. See `app/CLAUDE.md` §"Dependencias y override
/// pattern" for the override contract.
///
/// Business rules enforced at this boundary:
/// - Update is only allowed when [Expense.hasSettlements] is false.
///   The Firestore security rule also enforces this; the client should
///   guard before calling [updateExpense] to give fast feedback.
/// - Delete is only allowed for the creator ([Expense.createdBy]) when
///   [Expense.hasSettlements] is false.
abstract class ExpenseRepository {
  /// Streams all expenses for [tripId], ordered by [date] descending.
  ///
  /// The compound index `(date desc, createdAt desc)` declared in
  /// `firestore.indexes.json` backs this query.
  Stream<List<Expense>> watchTripExpenses(String tripId);

  /// Streams all expenses for [tripId], ordered by [date] descending.
  Future<void> createExpense({
    required String tripId,
    required Expense expense,
  });

  /// Updates an existing expense. The caller must verify
  /// [Expense.hasSettlements] == false before invoking this.
  /// Each call appends an entry to [Expense.editHistory].
  Future<void> updateExpense({
    required String tripId,
    required Expense expense,
  });

  /// Deletes an expense. The caller must verify the current user is
  /// [Expense.createdBy] and [Expense.hasSettlements] == false.
  Future<void> deleteExpense({
    required String tripId,
    required String expenseId,
  });
}
