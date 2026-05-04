import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vamos/data/models/expense.dart';
import 'package:vamos/data/repositories/firestore_expense_repository.dart';

/// Handles one-off expense mutations: create, update, delete, and settle.
///
/// Each method sets [state] to [AsyncLoading] while in flight, then to
/// [AsyncData] or [AsyncError] upon completion. The calling screen listens
/// to [expenseActionsProvider] to react to success or show an error SnackBar.
///
/// autoDispose: the screen that triggered the action owns the lifecycle.
class ExpenseActionsNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Creates a new expense under [tripId].
  Future<void> create({
    required String tripId,
    required Expense expense,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(expenseRepositoryProvider).createExpense(
            tripId: tripId,
            expense: expense,
          ),
    );
  }

  /// Updates an existing expense. Caller must guard [Expense.hasSettlements].
  Future<void> update({
    required String tripId,
    required Expense expense,
  }) async {
    if (expense.hasSettlements) {
      state = AsyncError(
        Exception('No se puede editar un gasto que ya fue saldado.'),
        StackTrace.current,
      );
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(expenseRepositoryProvider).updateExpense(
            tripId: tripId,
            expense: expense,
          ),
    );
  }

  /// Deletes an expense. Caller must guard [Expense.hasSettlements] and
  /// verify the current user is [Expense.createdBy].
  Future<void> delete({
    required String tripId,
    required String expenseId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(expenseRepositoryProvider).deleteExpense(
            tripId: tripId,
            expenseId: expenseId,
          ),
    );
  }

  /// Records a debt settlement between two members.
  Future<void> settle({
    required String tripId,
    required String fromUserId,
    required String toUserId,
    required double amount,
    required String currency,
    required String createdBy,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(expenseRepositoryProvider).createSettlement(
            tripId: tripId,
            fromUserId: fromUserId,
            toUserId: toUserId,
            amount: amount,
            currency: currency,
            createdBy: createdBy,
          ),
    );
  }
}

final expenseActionsProvider =
    AsyncNotifierProvider.autoDispose<ExpenseActionsNotifier, void>(
  ExpenseActionsNotifier.new,
);
