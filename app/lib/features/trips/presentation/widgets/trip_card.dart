import 'package:flutter/material.dart';
import 'package:vamos/core/theme/vamos_colors.dart';
import 'package:vamos/core/theme/vamos_spacing.dart';
import 'package:vamos/core/theme/vamos_typography.dart';
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
    final now = DateTime.now();

    final status = computeStatus(
      start: trip.startDate,
      end: trip.endDate,
      isArchived: trip.status == 'archived',
      now: now,
    );

    // Card shape comes from CardThemeData in vamos_theme.dart — no override here.
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CoverPlaceholder(
              tripName: trip.name,
              coverPhotoURL: trip.coverPhotoURL,
              height: kTripCoverHeight,
            ),

            Padding(
              padding: const EdgeInsets.all(VamosSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.name,
                    style: VamosTypography.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: VamosSpacing.xs),

                  // Dates and counts are data → monoMedium per design-kit rule 4.
                  Text(
                    '${_formatDateRange(trip.startDate, trip.endDate)} · $memberCount ${_personLabel(memberCount)}',
                    style: VamosTypography.monoMedium.copyWith(color: VamosColors.text3),
                  ),
                  const SizedBox(height: VamosSpacing.xs),

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
    final (label, color) = switch (status) {
      TripStatus.ongoing => (
          'En curso · día ${_dayOfTrip()} de ${_tripDuration()}',
          VamosColors.green,
        ),
      TripStatus.upcoming => (
          'Por planear · en ${_daysUntil()}',
          VamosColors.warning,
        ),
      TripStatus.finished => ('Terminado', VamosColors.text3),
      TripStatus.archived => ('Archivado', VamosColors.textMuted),
    };

    // Status labels are overline: mono, uppercase, letter-spaced — design-kit §typography.
    return Text(
      label,
      style: VamosTypography.overline.copyWith(color: color),
    );
  }

  String _dayOfTrip() {
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(trip.startDate.year, trip.startDate.month, trip.startDate.day);
    return '${today.difference(start).inDays + 1}';
  }

  String _tripDuration() {
    final start = DateTime(trip.startDate.year, trip.startDate.month, trip.startDate.day);
    final end = DateTime(trip.endDate.year, trip.endDate.month, trip.endDate.day);
    return '${end.difference(start).inDays + 1}';
  }

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
