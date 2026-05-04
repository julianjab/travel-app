import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vamos/core/theme/vamos_colors.dart';
import 'package:vamos/core/theme/vamos_spacing.dart';
import 'package:vamos/core/theme/vamos_typography.dart';
import 'package:vamos/data/models/trip.dart';
import 'package:vamos/data/repositories/firestore_trip_repository.dart';
import 'package:vamos/features/trips/application/generate_invite_notifier.dart';

/// F1.3 — "Tu viaje está listo" — invite-link screen.
///
/// Shows the trip name + dates, the generated short link, and three
/// sharing actions: copy to clipboard, WhatsApp, native share sheet.
/// Also surfaces a primary CTA to proceed to the trip detail.
///
/// The invite code is generated on first mount via [GenerateInviteNotifier].
/// The screen handles loading, error, and data states.
class InviteScreen extends ConsumerWidget {
  const InviteScreen({super.key, required this.tripId});

  final String tripId;

  static const String _baseUrl = 'vamos.app/j';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripAsync = ref.watch(_tripProvider(tripId));
    final inviteAsync = ref.watch(generateInviteProvider(tripId));

    return Scaffold(
      // No back button — the create-trip form is consumed; popping back would
      // be confusing. The user proceeds via "Ir al viaje".
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Viaje creado'),
      ),
      body: SafeArea(
        child: tripAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => _ErrorState(
            message: 'No se pudo cargar el viaje.',
            onRetry: () => ref.invalidate(_tripProvider(tripId)),
          ),
          data: (trip) {
            if (trip == null) {
              return _ErrorState(
                message: 'El viaje no existe.',
                onRetry: () => ref.invalidate(_tripProvider(tripId)),
              );
            }
            return _Content(
              tripId: tripId,
              trip: trip,
              inviteAsync: inviteAsync,
              onRetryInvite: () =>
                  ref.read(generateInviteProvider(tripId).notifier).retry(),
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Main content — rendered once the trip is loaded
// ---------------------------------------------------------------------------

class _Content extends StatelessWidget {
  const _Content({
    required this.tripId,
    required this.trip,
    required this.inviteAsync,
    required this.onRetryInvite,
  });

  final String tripId;
  final Trip trip;
  final AsyncValue<String?> inviteAsync;
  final VoidCallback onRetryInvite;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: VamosSpacing.md,
        vertical: VamosSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Success icon ──────────────────────────────────────────────────
          const _SuccessIcon(),
          const SizedBox(height: VamosSpacing.lg),

          // ── Title (validated microcopy §5.2) ─────────────────────────────
          Text(
            'Tu viaje está listo',
            style: VamosTypography.displayMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: VamosSpacing.sm),

          // ── Trip summary ──────────────────────────────────────────────────
          Text(
            trip.name,
            style: VamosTypography.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: VamosSpacing.xs),
          Text(
            _formatDateRange(trip.startDate, trip.endDate),
            style: VamosTypography.monoMedium.copyWith(
              color: VamosColors.text3,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: VamosSpacing.xxl),

          // ── Divider + share section ───────────────────────────────────────
          const Divider(height: 1),
          const SizedBox(height: VamosSpacing.lg),

          Text(
            'Compartí este link con el grupo. Quien lo abra, entra.',
            style: VamosTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: VamosSpacing.md),

          // ── Invite link chip (loading / error / data) ─────────────────────
          inviteAsync.when(
            loading: () => const _LinkSkeleton(),
            error: (err, _) => _LinkError(onRetry: onRetryInvite),
            data: (code) {
              if (code == null) return _LinkError(onRetry: onRetryInvite);
              final link = '${InviteScreen._baseUrl}/$code';
              return _LinkChip(link: link, code: code);
            },
          ),

          const SizedBox(height: VamosSpacing.md),

          // ── WhatsApp button ───────────────────────────────────────────────
          inviteAsync.whenData((code) {
            if (code == null) return const SizedBox.shrink();
            return _WhatsAppButton(code: code);
          }).value ??
              const SizedBox.shrink(),

          const SizedBox(height: VamosSpacing.sm),

          // ── Native share button ───────────────────────────────────────────
          inviteAsync.whenData((code) {
            if (code == null) return const SizedBox.shrink();
            return _NativeShareButton(code: code);
          }).value ??
              const SizedBox.shrink(),

          const SizedBox(height: VamosSpacing.xxl),

          // ── Primary CTA ───────────────────────────────────────────────────
          FilledButton(
            onPressed: () => context.go('/trips/$tripId'),
            child: const Text('Ir al viaje'),
          ),

          const SizedBox(height: VamosSpacing.lg),
        ],
      ),
    );
  }

  String _formatDateRange(DateTime start, DateTime end) {
    final fmt = DateFormat('d MMM yyyy', 'es');
    return '${fmt.format(start)} – ${fmt.format(end)}';
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _SuccessIcon extends StatelessWidget {
  const _SuccessIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: VamosSpacing.xxxl,
      height: VamosSpacing.xxxl,
      decoration: const BoxDecoration(
        color: VamosColors.green,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.check,
        color: VamosColors.textOnDark,
        size: VamosSpacing.xl,
      ),
    );
  }
}

/// Displayed while the invite code is being generated in Firestore.
class _LinkSkeleton extends StatelessWidget {
  const _LinkSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VamosSpacing.md,
        vertical: VamosSpacing.md,
      ),
      decoration: BoxDecoration(
        color: VamosColors.surface2,
        borderRadius: VamosRadius.brLg,
        border: Border.all(color: VamosColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Generando link…',
              style: VamosTypography.monoMedium.copyWith(
                color: VamosColors.textMuted,
              ),
            ),
          ),
          const SizedBox(
            width: VamosSpacing.md,
            height: VamosSpacing.md,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      ),
    );
  }
}

/// Displayed when invite generation fails.
class _LinkError extends StatelessWidget {
  const _LinkError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(VamosSpacing.md),
      decoration: BoxDecoration(
        color: VamosColors.red.withValues(alpha: 0.08),
        borderRadius: VamosRadius.brLg,
        border: Border.all(color: VamosColors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: VamosColors.red, size: VamosSpacing.md),
          const SizedBox(width: VamosSpacing.sm),
          Expanded(
            child: Text(
              'No se pudo generar el link.',
              style: VamosTypography.bodyMedium.copyWith(color: VamosColors.red),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

/// The invite link chip with the copy button.
class _LinkChip extends StatelessWidget {
  const _LinkChip({required this.link, required this.code});

  final String link;
  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: VamosColors.surface,
        borderRadius: VamosRadius.brLg,
        border: Border.all(color: VamosColors.border),
      ),
      child: Row(
        children: [
          // Link text
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: VamosSpacing.md,
                vertical: VamosSpacing.md,
              ),
              child: Text(
                link,
                style: VamosTypography.monoMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          // Copy button
          IconButton(
            icon: const Icon(Icons.copy_outlined),
            tooltip: 'Copiar link',
            onPressed: () => _copyToClipboard(context, link),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copiado'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

/// WhatsApp share button — opens the wa.me share URL with the link pre-filled.
class _WhatsAppButton extends StatelessWidget {
  const _WhatsAppButton({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _shareWhatsApp(context, code),
      icon: const Icon(Icons.chat_outlined),
      label: const Text('Compartir por WhatsApp'),
    );
  }

  Future<void> _shareWhatsApp(BuildContext context, String code) async {
    final link = 'vamos.app/j/$code';
    final message = Uri.encodeComponent(
      'Sumate al viaje en Vamos: https://$link',
    );
    final uri = Uri.parse('https://wa.me/?text=$message');

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir WhatsApp.'),
          ),
        );
      }
    }
  }
}

/// Native share sheet button using share_plus.
class _NativeShareButton extends StatelessWidget {
  const _NativeShareButton({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _shareNative(code),
      icon: const Icon(Icons.ios_share_outlined),
      label: const Text('Compartir por otro lado'),
    );
  }

  Future<void> _shareNative(String code) async {
    final link = 'https://vamos.app/j/$code';
    await Share.share('Sumate al viaje en Vamos: $link');
  }
}

// ---------------------------------------------------------------------------
// Error state for the whole screen (trip not found / load error)
// ---------------------------------------------------------------------------

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(VamosSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message, style: VamosTypography.bodyLarge, textAlign: TextAlign.center),
          const SizedBox(height: VamosSpacing.md),
          FilledButton(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private trip stream provider (scoped to this file)
// ---------------------------------------------------------------------------

/// Watches a single trip document — scoped to [InviteScreen].
/// autoDispose + family so it is released when the screen pops.
final _tripProvider = StreamProvider.autoDispose
    .family<Trip?, String>((ref, tripId) {
  return ref.watch(tripRepositoryProvider).watchById(tripId);
});
