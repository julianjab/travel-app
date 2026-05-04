import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vamos/core/theme/vamos_colors.dart';
import 'package:vamos/core/theme/vamos_spacing.dart';
import 'package:vamos/core/theme/vamos_typography.dart';
import 'package:vamos/data/models/member.dart';
import 'package:vamos/data/repositories/firestore_trip_repository.dart';
import 'package:vamos/features/members/application/members_notifier.dart';
import 'package:vamos/features/trips/application/my_trips_notifier.dart';
import 'package:vamos/shared/widgets/loading_indicator.dart';

// ---------------------------------------------------------------------------
// Avatar color palette — deterministic from alias initial
// ---------------------------------------------------------------------------

const List<Color> _avatarColors = [
  VamosColors.sol500,
  VamosColors.green,
  VamosColors.warning,
  VamosColors.red,
];

Color _avatarColorFor(String alias) {
  if (alias.isEmpty) return VamosColors.sol500;
  return _avatarColors[alias.codeUnitAt(0) % _avatarColors.length];
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// F4.1 — Members list (Gente tab inside the trip shell).
///
/// Shows live member list with alias, initial-letter avatar, and preference
/// tags. The facilitator sees an "Invitar más" button that navigates to the
/// invite screen (/trips/:id/invite).
class MembersScreen extends ConsumerWidget {
  const MembersScreen({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(membersProvider(tripId));
    final tripAsync = ref.watch(
      // watchById returns Stream<Trip?> — wrap in StreamProvider per-tripId
      _tripStreamProvider(tripId),
    );
    final currentUserId = ref.watch(currentUserIdProvider);

    return membersAsync.when(
      loading: () => const VamosLoadingIndicator(),
      error: (error, _) => _ErrorState(error: error.toString()),
      data: (members) {
        // Determine if the current user is the facilitator. We need the trip
        // doc for the facilitatorId — fall back to false while loading.
        final facilitatorId =
            tripAsync.valueOrNull?.facilitatorId ?? '';
        final isFacilitator =
            currentUserId.isNotEmpty && currentUserId == facilitatorId;

        if (members.isEmpty) {
          return _EmptyState(
            isFacilitator: isFacilitator,
            tripId: tripId,
          );
        }

        return _MembersList(
          members: members,
          facilitatorId: facilitatorId,
          isFacilitator: isFacilitator,
          tripId: tripId,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Trip stream provider (family) — local to this file
// ---------------------------------------------------------------------------

// We need the trip doc to read facilitatorId. Scoped to this file because
// TripShellScreen already reads the trip for the AppBar — no duplication
// across features; this is within one screen family.
final _tripStreamProvider =
    StreamProvider.autoDispose.family((ref, String tripId) {
  return ref.watch(tripRepositoryProvider).watchById(tripId);
});

// ---------------------------------------------------------------------------
// Members list
// ---------------------------------------------------------------------------

class _MembersList extends StatelessWidget {
  const _MembersList({
    required this.members,
    required this.facilitatorId,
    required this.isFacilitator,
    required this.tripId,
  });

  final List<Member> members;
  final String facilitatorId;
  final bool isFacilitator;
  final String tripId;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            VamosSpacing.md,
            VamosSpacing.md,
            VamosSpacing.md,
            VamosSpacing.sm,
          ),
          sliver: SliverToBoxAdapter(
            child: Text(
              '${members.length} ${members.length == 1 ? 'persona' : 'personas'}',
              style: VamosTypography.titleMedium,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: VamosSpacing.md),
          sliver: SliverList.separated(
            itemCount: members.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: VamosSpacing.sm),
            itemBuilder: (context, index) {
              final member = members[index];
              return _MemberCard(
                member: member,
                isFacilitator: member.userId == facilitatorId,
              );
            },
          ),
        ),
        // Bottom padding + facilitator CTA
        SliverPadding(
          padding: const EdgeInsets.all(VamosSpacing.md),
          sliver: SliverToBoxAdapter(
            child: isFacilitator
                ? FilledButton.icon(
                    onPressed: () =>
                        context.push('/trips/$tripId/invite'),
                    icon: const Icon(Icons.person_add_outlined),
                    label: const Text('Invitar más'),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Member card
// ---------------------------------------------------------------------------

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.isFacilitator,
  });

  final Member member;
  final bool isFacilitator;

  @override
  Widget build(BuildContext context) {
    final tags = _buildTagLabels(member.tags);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(14)), // VamosRadius.lg
        side: BorderSide(color: VamosColors.border),
      ),
      color: VamosColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(VamosSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AvatarInitial(alias: member.alias),
            const SizedBox(width: VamosSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          member.alias,
                          style: VamosTypography.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isFacilitator) ...[
                        const SizedBox(width: VamosSpacing.xs),
                        _FacilitatorChip(),
                      ],
                    ],
                  ),
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: VamosSpacing.xs),
                    Wrap(
                      spacing: VamosSpacing.xs,
                      runSpacing: VamosSpacing.xs,
                      children: tags
                          .map((label) => _TagChip(label: label))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Flattens the [tags] map into display strings.
  ///
  /// Keys used in the data model: "diet", "pace", "budget".
  /// Each key holds a List of Strings (diet, pace) or a String (budget).
  static List<String> _buildTagLabels(Map<String, dynamic> tags) {
    final labels = <String>[];

    // diet — List<String>
    final diet = tags['diet'];
    if (diet is List) {
      for (final item in diet) {
        if (item is String && item.isNotEmpty) labels.add(item);
      }
    } else if (diet is String && diet.isNotEmpty) {
      labels.add(diet);
    }

    // pace — List<String>
    final pace = tags['pace'];
    if (pace is List) {
      for (final item in pace) {
        if (item is String && item.isNotEmpty) labels.add(item);
      }
    } else if (pace is String && pace.isNotEmpty) {
      labels.add(pace);
    }

    // budget — String
    final budget = tags['budget'];
    if (budget is String && budget.isNotEmpty) labels.add(budget);

    return labels;
  }
}

// ---------------------------------------------------------------------------
// Avatar
// ---------------------------------------------------------------------------

class _AvatarInitial extends StatelessWidget {
  const _AvatarInitial({required this.alias});

  final String alias;

  @override
  Widget build(BuildContext context) {
    final initial =
        alias.isNotEmpty ? alias[0].toUpperCase() : '?';
    final bgColor = _avatarColorFor(alias);

    return CircleAvatar(
      radius: VamosSpacing.lg, // 24 logical pixels
      backgroundColor: bgColor,
      child: Text(
        initial,
        style: VamosTypography.titleMedium.copyWith(
          color: VamosColors.textOnDark,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Facilitator chip
// ---------------------------------------------------------------------------

class _FacilitatorChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VamosSpacing.sm,
        vertical: VamosSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: VamosColors.sol50,
        borderRadius: const BorderRadius.all(Radius.circular(9999)), // brFull
        border: Border.all(color: VamosColors.sol300),
      ),
      child: Text(
        'facilitador',
        style: VamosTypography.overline.copyWith(
          color: VamosColors.sol600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tag chip
// ---------------------------------------------------------------------------

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VamosSpacing.sm,
        vertical: VamosSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: VamosColors.surface2,
        borderRadius: const BorderRadius.all(Radius.circular(9999)), // brFull
        border: Border.all(color: VamosColors.border),
      ),
      child: Text(
        label,
        style: VamosTypography.caption,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.isFacilitator,
    required this.tripId,
  });

  final bool isFacilitator;
  final String tripId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(VamosSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Acá no hay nada todavía.',
            style: VamosTypography.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: VamosSpacing.sm),
          Text(
            'Compartí el link de invitación con el grupo para que se sumen.',
            style: VamosTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (isFacilitator) ...[
            const SizedBox(height: VamosSpacing.lg),
            FilledButton.icon(
              onPressed: () => context.push('/trips/$tripId/invite'),
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Compartir invitación'),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error state
// ---------------------------------------------------------------------------

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(VamosSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: VamosColors.red,
            size: VamosSpacing.xxxl,
          ),
          const SizedBox(height: VamosSpacing.md),
          Text(
            'No se pudo cargar la lista.',
            style: VamosTypography.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: VamosSpacing.sm),
          Text(
            'Revisá tu conexión e intentá de nuevo.',
            style: VamosTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
