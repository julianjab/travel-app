import 'package:flutter/material.dart';
import 'package:vamos/core/theme/vamos_colors.dart';
import 'package:vamos/core/theme/vamos_spacing.dart';
import 'package:vamos/core/theme/vamos_typography.dart';

/// Standard empty-state widget for all list screens.
///
/// Follows the pattern defined in `docs/06-identidad-y-tono.md` §4:
///   icon (sol500, size 48) + message (bodyMedium, text3) + optional FilledButton.
///
/// Used in 4+ list screens (MyTrips, Itinerary, Expenses, Members) so it
/// qualifies for `shared/widgets/` per the 2-feature rule.
class VamosEmptyState extends StatelessWidget {
  const VamosEmptyState({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.icon = Icons.travel_explore_outlined,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(VamosSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: VamosSpacing.xxl, // 48
              color: VamosColors.sol500,
            ),
            const SizedBox(height: VamosSpacing.md),
            Text(
              message,
              style: VamosTypography.bodyMedium.copyWith(
                color: VamosColors.text3,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: VamosSpacing.lg),
              FilledButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
