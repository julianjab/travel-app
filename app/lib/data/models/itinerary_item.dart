/// Mirrors the `trips/{tripId}/items/{itemId}` Firestore document.
///
/// See `docs/05-modelo-datos-2.md` §2.2 for the canonical schema.
/// The [id] is the Firestore document ID and is NOT stored inside the document.
class ItineraryItem {
  const ItineraryItem({
    required this.id,
    required this.title,
    required this.day,
    required this.authorId,
    required this.status,
    required this.votes,
    required this.createdAt,
    required this.updatedAt,
    this.time,
    this.location,
    this.notes,
    this.estimatedCostPerPerson,
    this.estimatedCostCurrency,
    this.estimatedCostExchangeRate,
  });

  final String id;
  final String title;

  /// Day assigned to this item (date-only; time stored separately in [time]).
  final DateTime day;

  /// Optional time string, e.g. "20:00".
  final String? time;

  /// Free-text location (no geocoding in MVP).
  final String? location;

  final String? notes;
  final String authorId;

  /// "proposed" | "confirmed"
  final String status;

  /// Vote map: { userId: "yes" | "no" }.
  /// Counts are computed on the client from this map.
  final Map<String, String> votes;

  /// Optional estimated cost per person in [estimatedCostCurrency].
  final double? estimatedCostPerPerson;

  /// ISO 4217 currency for the estimated cost.
  final String? estimatedCostCurrency;

  /// Exchange rate to the trip's mainCurrency. 1.0 if same currency.
  final double? estimatedCostExchangeRate;

  final DateTime createdAt;
  final DateTime updatedAt;

  ItineraryItem copyWith({
    String? id,
    String? title,
    DateTime? day,
    String? time,
    String? location,
    String? notes,
    String? authorId,
    String? status,
    Map<String, String>? votes,
    double? estimatedCostPerPerson,
    String? estimatedCostCurrency,
    double? estimatedCostExchangeRate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ItineraryItem(
      id: id ?? this.id,
      title: title ?? this.title,
      day: day ?? this.day,
      time: time ?? this.time,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      authorId: authorId ?? this.authorId,
      status: status ?? this.status,
      votes: votes ?? this.votes,
      estimatedCostPerPerson:
          estimatedCostPerPerson ?? this.estimatedCostPerPerson,
      estimatedCostCurrency:
          estimatedCostCurrency ?? this.estimatedCostCurrency,
      estimatedCostExchangeRate:
          estimatedCostExchangeRate ?? this.estimatedCostExchangeRate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItineraryItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
