import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vamos/data/models/expense.dart';
import 'package:vamos/data/repositories/firestore_expense_repository.dart';

/// Streams all expenses for a given trip ID in real time.
///
/// Backed by [ExpenseRepository.watchTripExpenses]. Uses autoDispose + family
/// so each TripShellScreen tab has its own live subscription that is released
/// when the screen is popped.
class ExpensesNotifier
    extends AutoDisposeFamilyStreamNotifier<List<Expense>, String> {
  @override
  Stream<List<Expense>> build(String tripId) {
    return ref.watch(expenseRepositoryProvider).watchTripExpenses(tripId);
  }
}

final expensesProvider = StreamNotifierProvider.autoDispose
    .family<ExpensesNotifier, List<Expense>, String>(ExpensesNotifier.new);
