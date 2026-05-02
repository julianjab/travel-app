import 'package:flutter/material.dart';
import 'package:vamos/core/theme/app_colors.dart';
import 'package:vamos/core/theme/app_radii.dart';
import 'package:vamos/core/theme/app_spacing.dart';
import 'package:vamos/data/models/trip.dart';
import 'package:vamos/features/trips/domain/trip_status.dart';
import 'package:vamos/features/trips/presentation/widgets/cover_placeholder.dart';

/// Card for one trip in the F1.1 "Mis viajes" list.
///
/// Renders the cover photo (or placeholder), trip name, date range,
/// member count, and the computed status badge.
/// Tapping the card triggers [onTap].
class TripCard extends StatelessWidget {
  const TripCard({
    super.key,
    required this.trip,
    required this.memberCount,
    required this.onTap,
  });

  final Trip trip;
  final int memberCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final now = DateTime.now();

    final status = computeStatus(
      start: trip.startDate,
      end: trip.endDate,
      isArchived: trip.status == 'archived',
      now: now,
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image / placeholder
            CoverPlaceholder(
              tripName: trip.name,
              coverPhotoURL: trip.coverPhotoURL,
              height: kTripCoverHeight,
            ),

            // Info section
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Trip name
                  Text(
                    trip.name,
                    style: text.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // Date range + member count
                  Text(
                    '${_formatDateRange(trip.startDate, trip.endDate)} · $memberCount ${_personLabel(memberCount)}',
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // Status badge
                  _StatusBadge(status: status, trip: trip, now: now),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateRange(DateTime start, DateTime end) {
    final startStr = _shortDate(start);
    // Show end year only when it differs from start year.
    if (start.year != end.year) {
      return '$startStr - ${_shortDate(end, includeYear: true)}';
    }
    return '$startStr - ${_shortDate(end)}';
  }

  String _shortDate(DateTime d, {bool includeYear = false}) {
    final months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    final base = '${d.day} ${months[d.month - 1]}';
    return includeYear ? '$base ${d.year}' : base;
  }

  String _personLabel(int count) => count == 1 ? 'persona' : 'personas';
}

// ---------------------------------------------------------------------------
// Status badge
// ---------------------------------------------------------------------------

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.status,
    required this.trip,
    required this.now,
  });

  final TripStatus status;
  final Trip trip;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    final (label, color) = switch (status) {
      TripStatus.ongoing => (
          'En curso · día ${_dayOfTrip()} de ${_tripDuration()}',
          AppColors.success,
        ),
      TripStatus.upcoming => (
          'Por planear · en ${_daysUntil()}',
          AppColors.warning,
        ),
      TripStatus.finished => ('Terminado', null),
      TripStatus.archived => ('Archivado', null),
    };

    final scheme = Theme.of(context).colorScheme;

    return Text(
      label,
      style: text.bodySmall?.copyWith(
        color: color ?? scheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// Returns "N" in "día N de M" for ongoing trips.
  String _dayOfTrip() {
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(trip.startDate.year, trip.startDate.month, trip.startDate.day);
    return '${today.difference(start).inDays + 1}';
  }

  /// Returns "M" in "día N de M": total duration in days.
  String _tripDuration() {
    final start = DateTime(trip.startDate.year, trip.startDate.month, trip.startDate.day);
    final end = DateTime(trip.endDate.year, trip.endDate.month, trip.endDate.day);
    return '${end.difference(start).inDays + 1}';
  }

  /// Returns a human-friendly "en X días/meses" for upcoming trips.
  String _daysUntil() {
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(trip.startDate.year, trip.startDate.month, trip.startDate.day);
    final days = start.difference(today).inDays;
    if (days == 1) return '1 día';
    if (days < 31) return '$days días';
    final months = (days / 30).round();
    return '$months ${months == 1 ? 'mes' : 'meses'}';
  }
}
