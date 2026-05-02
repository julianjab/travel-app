/// Mirrors the `trips/{tripId}/expenses/{expenseId}` Firestore document.
///
/// See `docs/05-modelo-datos-2.md` §2.2 for the canonical schema.
/// The [id] is the Firestore document ID and is NOT stored inside the document.
class Expense {
  const Expense({
    required this.id,
    required this.amount,
    required this.currency,
    required this.exchangeRate,
    required this.amountInMainCurrency,
    required this.paidBy,
    required this.splitBetween,
    required this.splitType,
    required this.date,
    required this.createdAt,
    required this.createdBy,
    required this.hasSettlements,
    required this.editHistory,
    this.description,
    this.photoURL,
    this.splitDetails,
  });

  final String id;

  /// Amount in the original [currency].
  final double amount;

  /// ISO 4217, e.g. "BRL".
  final String currency;

  /// Exchange rate to the trip's mainCurrency. 1.0 if currency == mainCurrency.
  final double exchangeRate;

  /// Denormalized: amount * exchangeRate. Computed at write time.
  final double amountInMainCurrency;

  final String? description;
  final String? photoURL;

  /// userId of who paid.
  final String paidBy;

  /// userIds included in the split.
  final List<String> splitBetween;

  /// "equal" | "percentage" | "amount"
  final String splitType;

  /// Only populated when splitType != "equal".
  final Map<String, dynamic>? splitDetails;

  /// Day of the expense (may differ from [createdAt]).
  final DateTime date;

  final DateTime createdAt;
  final String createdBy;

  /// When true, edits are blocked (a settlement references this expense).
  final bool hasSettlements;

  /// Audit trail of edits. Each entry records who changed what and the old values.
  final List<Map<String, dynamic>> editHistory;

  Expense copyWith({
    String? id,
    double? amount,
    String? currency,
    double? exchangeRate,
    double? amountInMainCurrency,
    String? description,
    String? photoURL,
    String? paidBy,
    List<String>? splitBetween,
    String? splitType,
    Map<String, dynamic>? splitDetails,
    DateTime? date,
    DateTime? createdAt,
    String? createdBy,
    bool? hasSettlements,
    List<Map<String, dynamic>>? editHistory,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      amountInMainCurrency: amountInMainCurrency ?? this.amountInMainCurrency,
      description: description ?? this.description,
      photoURL: photoURL ?? this.photoURL,
      paidBy: paidBy ?? this.paidBy,
      splitBetween: splitBetween ?? this.splitBetween,
      splitType: splitType ?? this.splitType,
      splitDetails: splitDetails ?? this.splitDetails,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      hasSettlements: hasSettlements ?? this.hasSettlements,
      editHistory: editHistory ?? this.editHistory,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Expense &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
