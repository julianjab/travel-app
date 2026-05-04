import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vamos/data/firebase/firebase_providers.dart';
import 'package:vamos/data/models/expense.dart';
import 'package:vamos/data/repositories/expense_repository.dart';

/// Firestore implementation of [ExpenseRepository].
///
/// This is the ONLY file in the app that imports `cloud_firestore` for
/// expenses. All reads and writes go through the abstract [ExpenseRepository]
/// interface — notifiers and widgets never reference this class directly.
class FirestoreExpenseRepository implements ExpenseRepository {
  const FirestoreExpenseRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _expenses(String tripId) =>
      _firestore.collection('trips').doc(tripId).collection('expenses');

  CollectionReference<Map<String, dynamic>> _settlements(String tripId) =>
      _firestore.collection('trips').doc(tripId).collection('settlements');

  @override
  Stream<List<Expense>> watchTripExpenses(String tripId) {
    return _expenses(tripId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => Expense.fromFirestore(
                  doc as DocumentSnapshot<Map<String, dynamic>>,
                ),
              )
              .toList(),
        );
  }

  @override
  Future<void> createExpense({
    required String tripId,
    required Expense expense,
  }) async {
    final docRef = _expenses(tripId).doc(expense.id);
    await docRef.set(expense.toMap());
  }

  @override
  Future<void> updateExpense({
    required String tripId,
    required Expense expense,
  }) async {
    await _expenses(tripId).doc(expense.id).set(expense.toMap());
  }

  @override
  Future<void> deleteExpense({
    required String tripId,
    required String expenseId,
  }) async {
    await _expenses(tripId).doc(expenseId).delete();
  }

  @override
  Future<void> createSettlement({
    required String tripId,
    required String fromUserId,
    required String toUserId,
    required double amount,
    required String currency,
    required String createdBy,
  }) async {
    await _settlements(tripId).add({
      'from': fromUserId,
      'to': toUserId,
      'amount': amount,
      'currency': currency,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': createdBy,
    });
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
