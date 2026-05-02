/// Trip lifecycle status used for display and ordering in F1.1.
///
/// Defined in `docs/04-wireframes-mvp-2.md` §F1.1 "Estados del viaje".
/// This enum is a pure value — no Flutter, no Firebase.
enum TripStatus {
  /// Trip has not started yet (today < startDate).
  upcoming,

  /// Trip is ongoing (startDate <= today <= endDate).
  ongoing,

  /// Trip has ended (today > endDate).
  finished,

  /// Facilitator explicitly archived the trip (status == "archived" in Firestore).
  archived,
}

/// Computes the display [TripStatus] for a trip.
///
/// Parameters:
/// - [start] and [end] are the trip date range (date parts only, times ignored).
/// - [isArchived] is true when the Firestore field `status == "archived"`.
/// - [now] is the reference moment (injected for testability; use [DateTime.now] in prod).
///
/// The archived flag takes priority over date comparisons — an archived trip
/// always renders as [TripStatus.archived] regardless of dates.
TripStatus computeStatus({
  required DateTime start,
  required DateTime end,
  required bool isArchived,
  required DateTime now,
}) {
  if (isArchived) return TripStatus.archived;

  // Normalize to date-only comparison (ignore hours/minutes/seconds).
  final today = DateTime(now.year, now.month, now.day);
  final startDay = DateTime(start.year, start.month, start.day);
  final endDay = DateTime(end.year, end.month, end.day);

  if (today.isBefore(startDay)) return TripStatus.upcoming;
  if (today.isAfter(endDay)) return TripStatus.finished;
  return TripStatus.ongoing;
}

/// Returns the sort key for ordering trips in the F1.1 list.
///
/// Order: ongoing (0) → upcoming (1) → finished (2) → archived (3).
int tripStatusSortKey(TripStatus status) {
  switch (status) {
    case TripStatus.ongoing:
      return 0;
    case TripStatus.upcoming:
      return 1;
    case TripStatus.finished:
      return 2;
    case TripStatus.archived:
      return 3;
  }
}
