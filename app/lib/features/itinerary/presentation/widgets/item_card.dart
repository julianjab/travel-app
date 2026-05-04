import 'package:flutter/material.dart';
import 'package:vamos/core/theme/vamos_colors.dart';
import 'package:vamos/core/theme/vamos_spacing.dart';
import 'package:vamos/core/theme/vamos_typography.dart';
import 'package:vamos/data/models/itinerary_item.dart';

/// Card for a single itinerary item in the list view (F2.1).
///
/// Shows: title, time (if set), location (if set), status chip, vote counts.
class ItemCard extends StatelessWidget {
  const ItemCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  final ItineraryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final yesCount =
        item.votes.values.where((v) => v == 'yes').length;
    final noCount =
        item.votes.values.where((v) => v == 'no').length;
    final isConfirmed = item.status == 'confirmed';

    return Card(
      child: InkWell(
        borderRadius: VamosRadius.brLg,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(VamosSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status icon + title row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isConfirmed ? '✓' : '💭',
                    style: VamosTypography.bodyMedium,
                  ),
                  const SizedBox(width: VamosSpacing.xs),
                  Expanded(
                    child: Text(
                      item.title,
                      style: VamosTypography.titleMedium,
                    ),
                  ),
                  const SizedBox(width: VamosSpacing.xs),
                  _StatusChip(confirmed: isConfirmed),
                ],
              ),

              // Time + location
              if (item.time != null || item.location != null) ...[
                const SizedBox(height: VamosSpacing.xs),
                _MetaRow(item: item),
              ],

              // Vote counts (only for proposed items)
              if (!isConfirmed) ...[
                const SizedBox(height: VamosSpacing.sm),
                Row(
                  children: [
                    const Icon(
                      Icons.thumb_up_outlined,
                      size: 14,
                      color: VamosColors.green,
                    ),
                    const SizedBox(width: VamosSpacing.xs),
                    Text(
                      '$yesCount',
                      style: VamosTypography.monoMedium.copyWith(
                        color: VamosColors.green,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: VamosSpacing.md),
                    const Icon(
                      Icons.thumb_down_outlined,
                      size: 14,
                      color: VamosColors.red,
                    ),
                    const SizedBox(width: VamosSpacing.xs),
                    Text(
                      '$noCount',
                      style: VamosTypography.monoMedium.copyWith(
                        color: VamosColors.red,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status chip
// ---------------------------------------------------------------------------

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.confirmed});

  final bool confirmed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VamosSpacing.sm,
        vertical: VamosSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: confirmed
            ? VamosColors.green.withAlpha(26)
            : VamosColors.warning.withAlpha(26),
        borderRadius: VamosRadius.brFull,
      ),
      child: Text(
        confirmed ? 'Confirmado' : 'Propuesto',
        style: VamosTypography.overline.copyWith(
          color: confirmed ? VamosColors.green : VamosColors.warning,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Meta row (time + location)
// ---------------------------------------------------------------------------

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.item});

  final ItineraryItem item;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];
    if (item.time != null) parts.add(item.time!);
    if (item.location != null) parts.add(item.location!);

    return Text(
      parts.join(' · '),
      style: VamosTypography.caption,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

