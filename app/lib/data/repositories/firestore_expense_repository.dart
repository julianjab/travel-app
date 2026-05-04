import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vamos/data/firebase/firebase_providers.dart';
import 'package:vamos/data/models/expense.dart';
import 'package:vamos/data/repositories/expense_repository.dart';

/// Firestore implementation of [ExpenseRepository].
///
/// This is the ONLY file in the app that imports `cloud_firestore` for
/// expenses. Skeleton: methods throw [UnimplementedError] until F3.x
/// implements the expenses flow. The interface is in place so that notifiers
/// can depend on [ExpenseRepository] without coupling to Firebase.
class FirestoreExpenseRepository implements ExpenseRepository {
  const FirestoreExpenseRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _expenses(String tripId) =>
      _firestore.collection('trips').doc(tripId).collection('expenses');

  @override
  Stream<List<Expense>> watchTripExpenses(String tripId) {
    // TODO(F3-x): implement when the expenses flow is built.
    // ignore: unused_local_variable
    final col = _expenses(tripId);
    throw UnimplementedError('watchTripExpenses is not yet implemented');
  }

  @override
  Future<void> createExpense({
    required String tripId,
    required Expense expense,
  }) async {
    // TODO(F3-x): implement when the expenses flow is built.
    throw UnimplementedError('createExpense is not yet implemented');
  }

  @override
  Future<void> updateExpense({
    required String tripId,
    required Expense expense,
  }) async {
    // TODO(F3-x): implement when the expenses flow is built.
    throw UnimplementedError('updateExpense is not yet implemented');
  }

  @override
  Future<void> deleteExpense({
    required String tripId,
    required String expenseId,
  }) async {
    // TODO(F3-x): implement when the expenses flow is built.
    throw UnimplementedError('deleteExpense is not yet implemented');
  }
}

// ---------------------------------------------------------------------------
// Riverpod provider
// ---------------------------------------------------------------------------

/// Provides the [ExpenseRepository] implementation.
///
/// Returns the abstract [ExpenseRepository] type. Override in tests/dev mode:
///
/// ```dart
/// ProviderScope(
///   overrides: [
///     expenseRepositoryProvider.overrideWithValue(MockExpenseRepository()),
///   ],
///   child: MyApp(),
/// )
/// ```
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return FirestoreExpenseRepository(firestore);
});
