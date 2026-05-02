import 'package:flutter/material.dart';
import 'package:vamos/core/theme/vamos_colors.dart';
import 'package:vamos/core/theme/vamos_logo.dart';
import 'package:vamos/core/theme/vamos_spacing.dart';
import 'package:vamos/core/theme/vamos_typography.dart';
import 'package:vamos/data/models/trip.dart';
import 'package:vamos/features/trips/domain/trip_status.dart';

/// Trip card — Variación B (hero grafito).
///
/// Header full-bleed colored by trip status, title in Space Grotesk +
/// brand orange dot, mono meta row. Body: status notification + member
/// pills + "Abrir →". Defined in wireframe F1.1.
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

    // Card shape + border come from CardThemeData in vamos_theme.dart.
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(trip: trip, status: status, now: now),
            _Body(
              trip: trip,
              status: status,
              now: now,
              memberCount: memberCount,
              onTap: onTap,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.trip, required this.status, required this.now});

  final Trip trip;
  final TripStatus status;
  final DateTime now;

  // All headers share the dark background — the ongoing state is signaled by
  // the orange overline, not by flooding the entire header with sol500.
  Color get _bg => VamosColors.bgDark;

  Color get _titleColor => switch (status) {
    TripStatus.finished || TripStatus.archived => VamosColors.text3Dark,
    _ => VamosColors.textDark,
  };

  // Ongoing overline is sol500 (orange accent); all others are graphite-muted.
  Color get _metaColor =>
      status == TripStatus.ongoing ? VamosColors.sol500 : VamosColors.text3Dark;

  // Brand dot always orange on the dark header.
  Color get _dotColor => VamosColors.sol500;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _bg,
      padding: const EdgeInsets.all(VamosSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _statusLabel(now),
            style: VamosTypography.overline.copyWith(color: _metaColor),
          ),
          const SizedBox(height: VamosSpacing.xs),
          _TripTitle(
            name: trip.name,
            textColor: _titleColor,
            dotColor: _dotColor,
          ),
          const SizedBox(height: VamosSpacing.xs),
          _MetaRow(trip: trip, status: status, now: now, color: _metaColor),
        ],
      ),
    );
  }

  String _statusLabel(DateTime now) {
    switch (status) {
      case TripStatus.upcoming:
        return 'PRÓXIMO VIAJE · EN ARMADO';
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
        return 'EN VIAJE · DÍA $day DE $total';
      case TripStatus.finished:
        return 'CERRADO · ${_monthYear(trip.endDate)}';
      case TripStatus.archived:
        return 'ARCHIVADO · ${_monthYear(trip.endDate)}';
    }
  }

  static String _monthYear(DateTime d) {
    const months = [
      'ENE',
      'FEB',
      'MAR',
      'ABR',
      'MAY',
      'JUN',
      'JUL',
      'AGO',
      'SEP',
      'OCT',
      'NOV',
      'DIC',
    ];
    return '${months[d.month - 1]} ${d.year}';
  }
}

// Trip name + brand dot (the "O" mark of vam◯s applied to the trip title).
//
// If the name contains an "o"/"O", the LAST one is painted dotColor — connecting
// visually with the VamosLogoMark circle. Rule: opportunistic, never forced.
// If the title would truncate (measured via TextPainter), the coloring is skipped
// to avoid a painted "o" disappearing mid-word in the ellipsis.
class _TripTitle extends StatelessWidget {
  const _TripTitle({
    required this.name,
    required this.textColor,
    required this.dotColor,
  });

  final String name;
  final Color textColor;
  final Color dotColor;

  static const _dotSize = 24.0;
  // Space the logo mark takes from available row width.
  static const _dotReserved = _dotSize + VamosSpacing.xs;

  @override
  Widget build(BuildContext context) {
    final style = VamosTypography.displayMedium.copyWith(color: textColor);
    final lastO = name.lastIndexOf(RegExp(r'[oO]'));

    final logoMark = Padding(
      padding: const EdgeInsets.only(left: VamosSpacing.xs),
      child: VamosLogoMark(size: _dotSize, color: dotColor),
    );

    if (lastO == -1) {
      // No "o" in name — plain title.
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(name, style: style, maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
          logoMark,
        ],
      );
    }

    // Use LayoutBuilder to know the available text width before deciding.
    return LayoutBuilder(
      builder: (context, constraints) {
        final textWidth = constraints.maxWidth - _dotReserved;
        final painter = TextPainter(
          text: TextSpan(text: name, style: style),
          maxLines: 2,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: textWidth);

        final titleWidget = painter.didExceedMaxLines
            // Truncated — skip coloring to avoid a painted "o" cut mid-word.
            ? Text(name, style: style, maxLines: 2, overflow: TextOverflow.ellipsis)
            : RichText(
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  children: [
                    if (lastO > 0) TextSpan(text: name.substring(0, lastO), style: style),
                    TextSpan(
                      text: name[lastO],
                      style: style.copyWith(color: dotColor),
                    ),
                    if (lastO < name.length - 1)
                      TextSpan(text: name.substring(lastO + 1), style: style),
                  ],
                ),
              );

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: titleWidget),
            logoMark,
          ],
        );
      },
    );
  }
}

// Dates + destination meta row (format varies by status).
class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.trip,
    required this.status,
    required this.now,
    required this.color,
  });

  final Trip trip;
  final TripStatus status;
  final DateTime now;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      _meta(),
      style: VamosTypography.monoMedium.copyWith(color: color),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  String _meta() {
    final dest = trip.destination;
    switch (status) {
      case TripStatus.upcoming:
        return '${_dateRange()}  ·  $dest';
      case TripStatus.ongoing:
        return 'Hasta ${_shortDate(trip.endDate)}  ·  $dest';
      case TripStatus.finished:
      case TripStatus.archived:
        final days = _durationDays();
        return '$days días  ·  $dest';
    }
  }

  String _dateRange() {
    final s = trip.startDate;
    final e = trip.endDate;
    const m = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    if (s.month == e.month && s.year == e.year) {
      return '${s.day} — ${e.day} ${m[e.month - 1]}';
    }
    return '${s.day} ${m[s.month - 1]} — ${e.day} ${m[e.month - 1]}';
  }

  String _shortDate(DateTime d) {
    const m = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return '${d.day} ${m[d.month - 1]}';
  }

  String _durationDays() {
    final s = DateTime(
      trip.startDate.year,
      trip.startDate.month,
      trip.startDate.day,
    );
    final e = DateTime(trip.endDate.year, trip.endDate.month, trip.endDate.day);
    return '${e.difference(s).inDays + 1}';
  }
}

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------

class _Body extends StatelessWidget {
  const _Body({
    required this.trip,
    required this.status,
    required this.now,
    required this.memberCount,
    required this.onTap,
  });

  final Trip trip;
  final TripStatus status;
  final DateTime now;
  final int memberCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(VamosSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusRow(status: status),
          const SizedBox(height: VamosSpacing.sm),
          Row(
            children: [
              _MemberPills(memberIds: trip.memberIds),
              const Spacer(),
              GestureDetector(
                onTap: onTap,
                child: Text(
                  'Abrir →',
                  style: VamosTypography.titleMedium.copyWith(
                    color: VamosColors.sol500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.status});

  final TripStatus status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final mutedColor = isDark ? VamosColors.text2Dark : VamosColors.text2;

    final (dotColor, boldText, rest) = switch (status) {
      TripStatus.upcoming => (
        VamosColors.warning,
        'Por confirmar',
        ' · todavía no hay gastos.',
      ),
      TripStatus.ongoing => (VamosColors.green, 'En curso', ' · viaje activo.'),
      TripStatus.finished => (
        isDark ? VamosColors.text3Dark : VamosColors.text3,
        'Terminado',
        ' · revisá los saldos.',
      ),
      TripStatus.archived => (VamosColors.textMuted, 'Archivado', ''),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
        ),
        const SizedBox(width: VamosSpacing.xs),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: boldText,
                  style: VamosTypography.bodyMedium.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (rest.isNotEmpty)
                  TextSpan(
                    text: rest,
                    style: VamosTypography.bodyMedium.copyWith(color: mutedColor),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Overlapping colored circles — one per member, max 4 visible + overflow chip.
class _MemberPills extends StatelessWidget {
  const _MemberPills({required this.memberIds});

  final List<String> memberIds;

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
          // Sized box so Stack has width.
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
                decoration: BoxDecoration(
                  color: _colorFromId(e.value),
                  shape: BoxShape.circle,
                  border: Border.all(color: circleBorder, width: 2),
                ),
              ),
            ),
          ),
          if (extra > 0)
            Positioned(
              left: visible.length * (_size - _overlap),
              child: Container(
                height: _size,
                padding: const EdgeInsets.symmetric(
                  horizontal: VamosSpacing.xs,
                ),
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
