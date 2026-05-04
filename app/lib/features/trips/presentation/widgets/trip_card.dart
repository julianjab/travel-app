import 'package:flutter/material.dart';
import 'package:vamos/core/theme/vamos_colors.dart';
import 'package:vamos/core/theme/vamos_spacing.dart';
import 'package:vamos/core/theme/vamos_typography.dart';
import 'package:vamos/data/models/trip.dart';
import 'package:vamos/features/trips/domain/trip_status.dart';

/// Trip card — layout plano, sin split header/body.
///
/// ┌──────────────────────────────────────────┐
/// │ 🟢 EN CURSO · DÍA 9 DE 18                │  status chip (mono)
/// │ Familia extendida                         │  nombre del viaje (display)
/// │ Barranquilla, Colombia                    │  destino (title)
/// │ 🔵🟡🟢  +2              15 abr — 3 may   │  pills + rango de fechas
/// └──────────────────────────────────────────┘
///
/// La card entera es el área tappable — sin botón "Abrir →".
/// Para viajes activos, el fondo lleva un degradado sutil sol500 en esquina.
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
    final cs = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: _cardDecoration(status, cs),
          child: Padding(
            padding: const EdgeInsets.all(VamosSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatusChip(status: status, trip: trip, now: now),
                const SizedBox(height: VamosSpacing.sm),
                _TripName(name: trip.name, status: status),
                const SizedBox(height: VamosSpacing.xs),
                _DestinationLine(destination: trip.destination),
                const SizedBox(height: VamosSpacing.sm),
                _BottomRow(trip: trip),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static BoxDecoration _cardDecoration(TripStatus status, ColorScheme cs) {
    if (status != TripStatus.ongoing) {
      return BoxDecoration(color: cs.surface);
    }
    return BoxDecoration(
      gradient: RadialGradient(
        center: Alignment.bottomRight,
        radius: 0.85,
        colors: [
          Color.lerp(cs.surface, VamosColors.sol500, 0.28)!,
          cs.surface,
        ],
        stops: const [0.0, 1.0],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status chip — dot + mono label
// ---------------------------------------------------------------------------

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.trip, required this.now});

  final TripStatus status;
  final Trip trip;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;
    final dotColor = _dotColor(isDark);
    final labelColor = status == TripStatus.ongoing
        ? VamosColors.sol500
        : (isDark ? VamosColors.text3Dark : VamosColors.text3);

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: VamosSpacing.xs),
        Text(
          _label(),
          style: VamosTypography.overline.copyWith(color: labelColor),
        ),
      ],
    );
  }

  Color _dotColor(bool isDark) => switch (status) {
    TripStatus.upcoming => VamosColors.warning,
    TripStatus.ongoing => VamosColors.green,
    TripStatus.finished => isDark ? VamosColors.text3Dark : VamosColors.text3,
    TripStatus.archived => VamosColors.textMuted,
  };

  String _label() {
    switch (status) {
      case TripStatus.upcoming:
        return 'PRÓXIMO';
      case TripStatus.ongoing:
        final today = DateTime(now.year, now.month, now.day);
        final s = DateTime(
          trip.startDate.year,
          trip.startDate.month,
          trip.startDate.day,
        );
        final e = DateTime(
          trip.endDate.year,
          trip.endDate.month,
          trip.endDate.day,
        );
        final day = today.difference(s).inDays + 1;
        final total = e.difference(s).inDays + 1;
        return 'EN CURSO · DÍA $day DE $total';
      case TripStatus.finished:
        return 'CERRADO · ${_monthYear(trip.endDate)}';
      case TripStatus.archived:
        return 'ARCHIVADO · ${_monthYear(trip.endDate)}';
    }
  }

  static String _monthYear(DateTime d) {
    const months = [
      'ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN',
      'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC',
    ];
    return '${months[d.month - 1]} ${d.year}';
  }
}

// ---------------------------------------------------------------------------
// Trip name — Space Grotesk display, plain
// ---------------------------------------------------------------------------

class _TripName extends StatelessWidget {
  const _TripName({required this.name, required this.status});

  final String name;
  final TripStatus status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final textColor = switch (status) {
      TripStatus.finished || TripStatus.archived =>
        isDark ? VamosColors.text3Dark : VamosColors.text3,
      _ => cs.onSurface,
    };

    return Text(
      name,
      style: VamosTypography.displayMedium.copyWith(color: textColor),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

// ---------------------------------------------------------------------------
// Destination — second line, clear but subordinate to the name
// ---------------------------------------------------------------------------

class _DestinationLine extends StatelessWidget {
  const _DestinationLine({required this.destination});

  final String destination;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;
    return Text(
      destination,
      style: VamosTypography.titleMedium.copyWith(
        color: isDark ? VamosColors.text2Dark : VamosColors.text2,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom row — member pills (left) + date range (right)
// ---------------------------------------------------------------------------

class _BottomRow extends StatelessWidget {
  const _BottomRow({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;
    return Row(
      children: [
        _MemberPills(
          memberIds: trip.memberIds,
          memberAliases: trip.memberAliases,
        ),
        const Spacer(),
        Text(
          _dateRange(),
          style: VamosTypography.monoMedium.copyWith(
            color: isDark ? VamosColors.text3Dark : VamosColors.text3,
          ),
        ),
      ],
    );
  }

  String _dateRange() {
    final s = trip.startDate;
    final e = trip.endDate;
    const m = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    if (s.year != e.year) {
      return '${s.day} ${m[s.month - 1]} ${s.year} — ${e.day} ${m[e.month - 1]} ${e.year}';
    }
    if (s.month != e.month) {
      return '${s.day} ${m[s.month - 1]} — ${e.day} ${m[e.month - 1]}';
    }
    return '${s.day} — ${e.day} ${m[e.month - 1]}';
  }
}

// ---------------------------------------------------------------------------
// Member pills — overlapping circles, max 4 + overflow chip
// ---------------------------------------------------------------------------

class _MemberPills extends StatelessWidget {
  const _MemberPills({
    required this.memberIds,
    required this.memberAliases,
  });

  final List<String> memberIds;

  /// Denormalized lookup `userId -> alias` from the trip doc (X-11). Used to
  /// paint the initial inside each circle. May be empty for legacy trips.
  final Map<String, String> memberAliases;

  static const _maxVisible = 4;
  static const _size = 28.0;
  static const _overlap = 8.0;

  Color _colorFromId(String id) {
    var hash = 5381;
    for (final c in id.codeUnits) {
      hash = ((hash << 5) + hash) + c;
      hash &= 0xFFFFFFFF;
    }
    const hues = [200.0, 340.0, 120.0, 270.0, 30.0, 180.0, 300.0, 60.0];
    return HSLColor.fromAHSL(
      1.0,
      hues[hash.abs() % hues.length],
      0.45,
      0.48,
    ).toColor();
  }

  /// First non-whitespace letter of the alias, uppercased. Falls back to the
  /// first character of the uid for legacy trips without a denormalized
  /// alias.
  String _initial(String uid) {
    final alias = memberAliases[uid];
    final source = (alias != null && alias.trim().isNotEmpty) ? alias.trim() : uid;
    return source.runes.isEmpty
        ? '?'
        : String.fromCharCode(source.runes.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final circleBorder = isDark ? VamosColors.surfaceDark : VamosColors.surface;
    final chipBg = isDark ? VamosColors.surface2Dark : VamosColors.surface2;
    final chipBorder = isDark ? VamosColors.borderDark : VamosColors.border;
    final chipText = isDark ? VamosColors.text2Dark : VamosColors.text2;

    final visible = memberIds.take(_maxVisible).toList();
    final extra = memberIds.length - _maxVisible;

    return SizedBox(
      height: _size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            width:
                visible.length * (_size - _overlap) +
                _overlap +
                (extra > 0 ? 32 : 0),
          ),
          ...visible.asMap().entries.map(
            (e) => Positioned(
              left: e.key * (_size - _overlap),
              child: Container(
                width: _size,
                height: _size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _colorFromId(e.value),
                  shape: BoxShape.circle,
                  border: Border.all(color: circleBorder, width: 2),
                ),
                child: Text(
                  _initial(e.value),
                  style: VamosTypography.caption.copyWith(
                    color: VamosColors.textOnDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          if (extra > 0)
            Positioned(
              left: visible.length * (_size - _overlap),
              child: Container(
                height: _size,
                padding: const EdgeInsets.symmetric(horizontal: VamosSpacing.xs),
                decoration: BoxDecoration(
                  color: chipBg,
                  borderRadius: VamosRadius.brFull,
                  border: Border.all(color: chipBorder),
                ),
                alignment: Alignment.center,
                child: Text(
                  '+$extra',
                  style: VamosTypography.caption.copyWith(color: chipText),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
