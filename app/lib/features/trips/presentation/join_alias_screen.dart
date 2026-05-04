import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:vamos/core/theme/vamos_colors.dart';
import 'package:vamos/core/theme/vamos_spacing.dart';
import 'package:vamos/core/theme/vamos_typography.dart';
import 'package:vamos/data/models/trip.dart';
import 'package:vamos/data/repositories/firestore_trip_repository.dart';
import 'package:vamos/features/trips/application/join_trip_notifier.dart';

/// F1.4b — Alias selection screen (shown to ALL invitees).
///
/// Displays a trip preview card (name, dates, facilitator alias derived from
/// trip data) and lets the user choose their alias for this trip. The alias
/// defaults to the current user's display name from the notifier but is
/// editable.
///
/// Navigates to /join/:code/tags on "Siguiente".
class JoinAliasScreen extends ConsumerStatefulWidget {
  const JoinAliasScreen({
    super.key,
    required this.inviteCode,
    required this.tripId,
    required this.isNewUser,
    required this.defaultName,
  });

  final String inviteCode;
  final String tripId;

  /// Whether the user was routed through F1.4 (profile setup). Propagated to
  /// the tags screen so the notifier knows whether to call saveProfile.
  final bool isNewUser;

  /// Pre-filled alias — comes from Firebase Auth displayName or the name
  /// entered in F1.4. The field is editable so the user can pick a trip alias.
  final String defaultName;

  @override
  ConsumerState<JoinAliasScreen> createState() => _JoinAliasScreenState();
}

class _JoinAliasScreenState extends ConsumerState<JoinAliasScreen> {
  late final TextEditingController _aliasController;

  @override
  void initState() {
    super.initState();
    _aliasController = TextEditingController(text: widget.defaultName);
  }

  @override
  void dispose() {
    _aliasController.dispose();
    super.dispose();
  }

  void _onContinue() {
    final alias = _aliasController.text.trim();
    ref
        .read(joinTripProvider(widget.inviteCode).notifier)
        .setAlias(alias.isEmpty ? widget.defaultName : alias);

    context.push(
      '/join/${widget.inviteCode}/tags',
      extra: <String, dynamic>{
        'tripId': widget.tripId,
        'isNewUser': widget.isNewUser,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tripAsync = ref.watch(_tripWatchProvider(widget.tripId));

    return Scaffold(
      backgroundColor: VamosColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(VamosSpacing.lg),
          children: [
            const SizedBox(height: VamosSpacing.xxl),

            Text(
              'Te invitaron al viaje',
              style: VamosTypography.displayMedium,
            ),

            const SizedBox(height: VamosSpacing.lg),

            // Trip preview card
            tripAsync.when(
              loading: () => _TripCardSkeleton(),
              error: (e, _) => _TripCardError(),
              data: (trip) =>
                  trip == null ? _TripCardError() : _TripCard(trip: trip),
            ),

            const SizedBox(height: VamosSpacing.xl),
            const Divider(color: VamosColors.border),
            const SizedBox(height: VamosSpacing.xl),

            // Alias field
            Text(
              '¿Cómo te van a llamar en este viaje?',
              style: VamosTypography.titleMedium,
            ),
            const SizedBox(height: VamosSpacing.md),
            TextFormField(
              controller: _aliasController,
              onChanged: (_) => setState(() {}),
              textCapitalization: TextCapitalization.words,
              style: VamosTypography.bodyLarge,
              decoration: InputDecoration(
                hintText: widget.defaultName,
                hintStyle:
                    VamosTypography.bodyLarge.copyWith(color: VamosColors.textMuted),
                filled: true,
                fillColor: VamosColors.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: VamosSpacing.md,
                  vertical: VamosSpacing.md,
                ),
                border: OutlineInputBorder(
                  borderRadius: VamosRadius.brMd,
                  borderSide: const BorderSide(color: VamosColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: VamosRadius.brMd,
                  borderSide: const BorderSide(color: VamosColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: VamosRadius.brMd,
                  borderSide: const BorderSide(color: VamosColors.sol500, width: 2),
                ),
              ),
            ),
            const SizedBox(height: VamosSpacing.sm),
            Text(
              'Podés usar tu apodo, nickname o como te llame el grupo.',
              style: VamosTypography.bodyMedium,
            ),

            const SizedBox(height: VamosSpacing.xxxl),

            // CTA — always enabled (defaultName is the fallback if field is empty)
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _onContinue,
                style: FilledButton.styleFrom(
                  backgroundColor: VamosColors.sol500,
                  shape: RoundedRectangleBorder(
                    borderRadius: VamosRadius.brFull,
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: VamosSpacing.md,
                  ),
                ),
                child: Text(
                  'Siguiente',
                  style: VamosTypography.titleMedium.copyWith(
                    color: VamosColors.textOnDark,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Trip preview card
// ---------------------------------------------------------------------------

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM yyyy', 'es');
    final start = dateFormat.format(trip.startDate);
    final end = dateFormat.format(trip.endDate);

    return Card(
      elevation: 0,
      color: VamosColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: VamosRadius.brLg,
        side: const BorderSide(color: VamosColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(VamosSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(trip.name, style: VamosTypography.titleMedium),
            const SizedBox(height: VamosSpacing.xs),
            Text(
              '$start – $end',
              style: VamosTypography.monoMedium.copyWith(
                color: VamosColors.text3,
              ),
            ),
            const SizedBox(height: VamosSpacing.xs),
            Text(
              trip.destination,
              style: VamosTypography.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _TripCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: VamosColors.surface2,
      shape: RoundedRectangleBorder(
        borderRadius: VamosRadius.brLg,
        side: const BorderSide(color: VamosColors.border),
      ),
      child: const SizedBox(height: 88),
    );
  }
}

class _TripCardError extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: VamosColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: VamosRadius.brLg,
        side: const BorderSide(color: VamosColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(VamosSpacing.lg),
        child: Text(
          'No se pudo cargar el viaje.',
          style: VamosTypography.bodyMedium.copyWith(color: VamosColors.text3),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private provider — scoped to this file
// ---------------------------------------------------------------------------

/// Watches a single trip document. autoDispose + family so it is released
/// when the screen leaves the tree.
final _tripWatchProvider = StreamProvider.autoDispose
    .family<Trip?, String>((ref, tripId) {
  return ref.watch(tripRepositoryProvider).watchById(tripId);
});
