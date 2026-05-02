import 'package:cloud_firestore/cloud_firestore.dart';

/// Mirrors the `trips/{tripId}` Firestore document.
///
/// See `docs/05-modelo-datos-2.md` §2.2 for the canonical schema.
/// The [id] field is the Firestore document ID and is NOT stored inside the
/// document itself — it is injected when constructing from a snapshot.
class Trip {
  const Trip({
    required this.id,
    required this.name,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.mainCurrency,
    required this.facilitatorId,
    required this.memberIds,
    required this.status,
    required this.createdAt,
    required this.createdBy,
    this.coverPhotoURL,
  });

  final String id;
  final String name;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;

  /// ISO 4217 currency code, e.g. "COP", "BRL", "USD".
  final String mainCurrency;

  final String? coverPhotoURL;
  final String facilitatorId;

  /// Denormalized list of member user IDs for Firestore array-contains queries.
  final List<String> memberIds;

  /// "active" | "archived"
  final String status;

  final DateTime createdAt;
  final String createdBy;

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------

  /// Creates a [Trip] from a Firestore [DocumentSnapshot].
  factory Trip.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Trip(
      id: doc.id,
      name: data['name'] as String,
      destination: data['destination'] as String,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      mainCurrency: data['mainCurrency'] as String,
      coverPhotoURL: data['coverPhotoURL'] as String?,
      facilitatorId: data['facilitatorId'] as String,
      memberIds: List<String>.from(data['memberIds'] as List),
      status: data['status'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] as String,
    );
  }

  /// Serializes to a Firestore-compatible map.
  /// The document [id] is NOT included — it lives as the document key.
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'destination': destination,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'mainCurrency': mainCurrency,
      if (coverPhotoURL != null) 'coverPhotoURL': coverPhotoURL,
      'facilitatorId': facilitatorId,
      'memberIds': memberIds,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
    };
  }

  // ---------------------------------------------------------------------------
  // Equality / copy
  // ---------------------------------------------------------------------------

  Trip copyWith({
    String? id,
    String? name,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    String? mainCurrency,
    String? coverPhotoURL,
    bool clearCoverPhoto = false,
    String? facilitatorId,
    List<String>? memberIds,
    String? status,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return Trip(
      id: id ?? this.id,
      name: name ?? this.name,
      destination: destination ?? this.destination,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      mainCurrency: mainCurrency ?? this.mainCurrency,
      coverPhotoURL: clearCoverPhoto ? null : (coverPhotoURL ?? this.coverPhotoURL),
      facilitatorId: facilitatorId ?? this.facilitatorId,
      memberIds: memberIds ?? this.memberIds,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Trip &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          destination == other.destination &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          mainCurrency == other.mainCurrency &&
          coverPhotoURL == other.coverPhotoURL &&
          facilitatorId == other.facilitatorId &&
          memberIds == other.memberIds &&
          status == other.status &&
          createdAt == other.createdAt &&
          createdBy == other.createdBy;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        destination,
        startDate,
        endDate,
        mainCurrency,
        coverPhotoURL,
        facilitatorId,
        memberIds,
        status,
        createdAt,
        createdBy,
      );
}
