import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:vamos/core/theme/vamos_colors.dart';
import 'package:vamos/core/theme/vamos_spacing.dart';
import 'package:vamos/core/theme/vamos_typography.dart';

/// Standard error-state widget for screens that fail to load.
///
/// Renders a friendly user-facing message and, in debug mode, surfaces the
/// underlying [error] (and optional [stackTrace]) so the cause is visible
/// without attaching a debugger. Production builds never show the raw error.
///
/// Used in 4+ screens (MyTrips, Itinerary, Expenses, Balances, Members) so it
/// qualifies for `shared/widgets/` per the 2-feature rule.
///
/// ```dart
/// asyncValue.when(
///   loading: ...,
///   error: (e, st) => VamosErrorState(
///     error: e,
///     stackTrace: st,
///     debugLabel: 'ItineraryScreen',
///     onRetry: () => ref.invalidate(itineraryProvider(tripId)),
///   ),
///   data: ...,
/// );
/// ```
class VamosErrorState extends StatelessWidget {
  const VamosErrorState({
    super.key,
    this.title = 'Algo salió mal.',
    this.message = 'Intentá de nuevo.',
    this.error,
    this.stackTrace,
    this.debugLabel,
    this.onRetry,
    this.retryLabel = 'Reintentar',
  });

  /// Headline shown in both debug and release.
  final String title;

  /// Sub-line shown in both debug and release.
  final String message;

  /// Underlying error. Logged via [debugPrint] and shown in-screen in debug.
  final Object? error;

  /// Optional stack trace, shown collapsed below [error] in debug.
  final StackTrace? stackTrace;

  /// Identifier prefixed to the debug log line — e.g. "MyTripsScreen".
  /// Helps grep the console when several screens are erroring.
  final String? debugLabel;

  /// If non-null, renders a "Reintentar" button under the message.
  final VoidCallback? onRetry;

  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      final tag = debugLabel != null ? '[$debugLabel] ' : '';
      debugPrint('${tag}error: $error');
      if (stackTrace != null) debugPrint(stackTrace.toString());
    }

    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(VamosSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: VamosSpacing.xxl,
              color: VamosColors.red,
            ),
            const SizedBox(height: VamosSpacing.md),
            Text(
              title,
              style: VamosTypography.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: VamosSpacing.sm),
            Text(
              message,
              style: VamosTypography.bodyMedium.copyWith(
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: VamosSpacing.lg),
              OutlinedButton(onPressed: onRetry, child: Text(retryLabel)),
            ],
            if (kDebugMode && error != null) ...[
              const SizedBox(height: VamosSpacing.lg),
              _DebugDetails(error: error!, stackTrace: stackTrace),
            ],
          ],
        ),
      ),
    );
  }
}

/// Collapsible debug block. Closed by default to avoid noise on small screens.
class _DebugDetails extends StatelessWidget {
  const _DebugDetails({required this.error, this.stackTrace});

  final Object error;
  final StackTrace? stackTrace;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(maxWidth: 560),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: VamosRadius.brMd,
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Theme(
        // ExpansionTile splits its divider color from the surrounding theme;
        // suppress it so the card edge stays clean.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: VamosSpacing.md,
            vertical: VamosSpacing.xs,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            VamosSpacing.md,
            0,
            VamosSpacing.md,
            VamosSpacing.md,
          ),
          title: Text(
            'Debug',
            style: VamosTypography.overline.copyWith(color: cs.onSurfaceVariant),
          ),
          subtitle: Text(
            error.toString(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: VamosTypography.caption.copyWith(color: cs.onSurface),
          ),
          children: [
            SelectableText(
              error.toString(),
              style: VamosTypography.caption.copyWith(color: cs.onSurface),
            ),
            if (stackTrace != null) ...[
              const SizedBox(height: VamosSpacing.sm),
              SelectableText(
                stackTrace.toString(),
                style: VamosTypography.caption.copyWith(
                  color: cs.onSurfaceVariant,
                  fontFamily: VamosTypography.fontMono,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
