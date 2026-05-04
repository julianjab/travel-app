import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:vamos/core/theme/vamos_colors.dart';
import 'package:vamos/core/theme/vamos_spacing.dart';
import 'package:vamos/core/theme/vamos_typography.dart';
import 'package:vamos/data/models/itinerary_item.dart';
import 'package:vamos/data/models/trip.dart';
import 'package:vamos/features/itinerary/application/item_actions_notifier.dart';
import 'package:vamos/features/trips/application/my_trips_notifier.dart';

/// F2.3 — Item detail with voting (F2-04/F2-05), confirm (F2-06),
/// edit/delete (F2-07), and move-day (F2-08).
class ItemDetailScreen extends ConsumerWidget {
  const ItemDetailScreen({
    super.key,
    required this.tripId,
    required this.item,
    required this.trip,
  });

  final String tripId;
  final ItineraryItem item;
  final Trip trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(currentUserIdProvider);
    final isFacilitator = currentUserId == trip.facilitatorId;
    final isAuthor = currentUserId == item.authorId;
    final canEdit = isAuthor || isFacilitator;

    // Listen for errors on actions
    ref.listen<AsyncValue<void>>(itemActionsProvider, (prev, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al guardar. Intentá de nuevo.'),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: VamosColors.bg,
      appBar: AppBar(
        backgroundColor: VamosColors.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          item.title,
          style: VamosTypography.headlineMedium,
        ),
        actions: [
          if (canEdit)
            PopupMenuButton<_ItemAction>(
              icon: const Icon(Icons.more_horiz),
              onSelected: (action) =>
                  _handleMenuAction(context, ref, action, currentUserId),
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: _ItemAction.edit,
                  child: Text('Editar'),
                ),
                const PopupMenuItem(
                  value: _ItemAction.delete,
                  child: Text(
                    'Eliminar',
                    style: TextStyle(color: VamosColors.red),
                  ),
                ),
                const PopupMenuItem(
                  value: _ItemAction.moveDay,
                  child: Text('Mover de día'),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(VamosSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ----------------------------------------------------------------
            // Header section
            // ----------------------------------------------------------------
            _ItemHeader(item: item),
            const SizedBox(height: VamosSpacing.lg),
            const Divider(color: VamosColors.border),

            // ----------------------------------------------------------------
            // Voting section (F2-05)
            // ----------------------------------------------------------------
            const SizedBox(height: VamosSpacing.md),
            Text('Tu voto', style: VamosTypography.titleMedium),
            const SizedBox(height: VamosSpacing.md),
            _VoteButtons(
              tripId: tripId,
              item: item,
              currentUserId: currentUserId,
            ),
            const SizedBox(height: VamosSpacing.lg),
            const Divider(color: VamosColors.border),

            // ----------------------------------------------------------------
            // Voters section (F2-04)
            // ----------------------------------------------------------------
            const SizedBox(height: VamosSpacing.md),
            Text('Votos del grupo', style: VamosTypography.titleMedium),
            const SizedBox(height: VamosSpacing.sm),
            _VotersList(item: item, currentUserId: currentUserId),
            const SizedBox(height: VamosSpacing.lg),
            const Divider(color: VamosColors.border),

            // ----------------------------------------------------------------
            // Actions section (F2-06)
            // ----------------------------------------------------------------
            const SizedBox(height: VamosSpacing.md),
            _ActionButtons(
              tripId: tripId,
              item: item,
              trip: trip,
              isFacilitator: isFacilitator,
              canEdit: canEdit,
              currentUserId: currentUserId,
            ),
            const SizedBox(height: VamosSpacing.xl),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(
    BuildContext context,
    WidgetRef ref,
    _ItemAction action,
    String currentUserId,
  ) {
    switch (action) {
      case _ItemAction.edit:
        context.push(
          '/trips/$tripId/items/${item.id}/edit',
          extra: {'item': item, 'trip': trip},
        );
      case _ItemAction.delete:
        _showDeleteDialog(context, ref);
      case _ItemAction.moveDay:
        _showMoveDayDialog(context, ref);
    }
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: VamosRadius.brDialog),
        title: const Text('Eliminar item'),
        content: const Text(
          '¿Querés eliminar este item? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: VamosColors.red),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await ref.read(itemActionsProvider.notifier).delete(
                    tripId: tripId,
                    itemId: item.id,
                  );
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Sí, eliminar'),
          ),
        ],
      ),
    );
  }

  void _showMoveDayDialog(BuildContext context, WidgetRef ref) {
    // Build trip days list
    final days = <DateTime>[];
    var current = DateTime(
      trip.startDate.year,
      trip.startDate.month,
      trip.startDate.day,
    );
    final end = DateTime(
      trip.endDate.year,
      trip.endDate.month,
      trip.endDate.day,
    );
    while (!current.isAfter(end)) {
      days.add(current);
      current = current.add(const Duration(days: 1));
    }

    final dayFormat = DateFormat('EEE d MMM', 'es');
    final startDay = DateTime(
        trip.startDate.year, trip.startDate.month, trip.startDate.day);

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: VamosRadius.brDialog),
        title: const Text('Mover de día'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: days.length,
            itemBuilder: (_, index) {
              final day = days[index];
              final dayNumber = day.difference(startDay).inDays + 1;
              final isCurrentDay = day.year == item.day.year &&
                  day.month == item.day.month &&
                  day.day == item.day.day;
              return ListTile(
                title: Text(
                  'Día $dayNumber — ${dayFormat.format(day)}',
                  style: VamosTypography.bodyMedium.copyWith(
                    color: isCurrentDay
                        ? VamosColors.sol500
                        : VamosColors.text,
                  ),
                ),
                trailing: isCurrentDay
                    ? const Icon(Icons.check, color: VamosColors.sol500)
                    : null,
                onTap: () async {
                  Navigator.of(dialogContext).pop();
                  final updatedItem = item.copyWith(
                    day: day,
                    updatedAt: DateTime.now(),
                  );
                  await ref.read(itemActionsProvider.notifier).updateItem(
                        tripId: tripId,
                        item: updatedItem,
                      );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Menu actions enum
// ---------------------------------------------------------------------------

enum _ItemAction { edit, delete, moveDay }

// ---------------------------------------------------------------------------
// Header section
// ---------------------------------------------------------------------------

class _ItemHeader extends StatelessWidget {
  const _ItemHeader({required this.item});

  final ItineraryItem item;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE d MMM', 'es');
    final isConfirmed = item.status == 'confirmed';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status
        Row(
          children: [
            Text(
              isConfirmed ? '✓ Confirmado' : '💭 Propuesto',
              style: VamosTypography.overline.copyWith(
                color: isConfirmed ? VamosColors.green : VamosColors.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: VamosSpacing.sm),

        // Title
        Text(item.title, style: VamosTypography.displayMedium),
        const SizedBox(height: VamosSpacing.sm),

        // Date + time
        Text(
          [
            dateFormat.format(item.day),
            if (item.time != null) item.time!,
          ].join(' · '),
          style: VamosTypography.monoMedium.copyWith(
            color: VamosColors.text2,
          ),
        ),

        // Location
        if (item.location != null) ...[
          const SizedBox(height: VamosSpacing.xs),
          Text(
            item.location!,
            style: VamosTypography.bodyMedium,
          ),
        ],

        // Notes
        if (item.notes != null) ...[
          const SizedBox(height: VamosSpacing.sm),
          Text('Notas:', style: VamosTypography.caption),
          const SizedBox(height: VamosSpacing.xs),
          Text(item.notes!, style: VamosTypography.bodyMedium),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Vote buttons (F2-05)
// ---------------------------------------------------------------------------

class _VoteButtons extends ConsumerWidget {
  const _VoteButtons({
    required this.tripId,
    required this.item,
    required this.currentUserId,
  });

  final String tripId;
  final ItineraryItem item;
  final String currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myVote = item.votes[currentUserId];
    final actionsState = ref.watch(itemActionsProvider);
    final isLoading = actionsState.isLoading;

    Future<void> castVote(String vote) async {
      await ref.read(itemActionsProvider.notifier).castVote(
            tripId: tripId,
            itemId: item.id,
            userId: currentUserId,
            vote: vote,
          );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isLoading ? null : () => castVote('yes'),
            icon: Icon(
              Icons.thumb_up_outlined,
              color: myVote == 'yes' ? VamosColors.green : VamosColors.text3,
            ),
            label: Text(
              'Sí',
              style: VamosTypography.bodyMedium.copyWith(
                color: myVote == 'yes' ? VamosColors.green : VamosColors.text3,
                fontWeight:
                    myVote == 'yes' ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: myVote == 'yes'
                    ? VamosColors.green
                    : VamosColors.border,
              ),
              padding: const EdgeInsets.symmetric(vertical: VamosSpacing.sm),
              shape: const RoundedRectangleBorder(
                borderRadius: VamosRadius.brFull,
              ),
            ),
          ),
        ),
        const SizedBox(width: VamosSpacing.md),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isLoading ? null : () => castVote('no'),
            icon: Icon(
              Icons.thumb_down_outlined,
              color: myVote == 'no' ? VamosColors.red : VamosColors.text3,
            ),
            label: Text(
              'No',
              style: VamosTypography.bodyMedium.copyWith(
                color: myVote == 'no' ? VamosColors.red : VamosColors.text3,
                fontWeight:
                    myVote == 'no' ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color:
                    myVote == 'no' ? VamosColors.red : VamosColors.border,
              ),
              padding: const EdgeInsets.symmetric(vertical: VamosSpacing.sm),
              shape: const RoundedRectangleBorder(
                borderRadius: VamosRadius.brFull,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Voters list (F2-04)
// ---------------------------------------------------------------------------

class _VotersList extends StatelessWidget {
  const _VotersList({required this.item, required this.currentUserId});

  final ItineraryItem item;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    final yesVoters =
        item.votes.entries.where((e) => e.value == 'yes').toList();
    final noVoters =
        item.votes.entries.where((e) => e.value == 'no').toList();

    if (item.votes.isEmpty) {
      return Text(
        'Nadie votó todavía.',
        style: VamosTypography.bodyMedium.copyWith(color: VamosColors.text3),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (yesVoters.isNotEmpty) ...[
          Row(
            children: [
              const Icon(Icons.thumb_up_outlined,
                  size: 14, color: VamosColors.green),
              const SizedBox(width: VamosSpacing.xs),
              Text(
                'Sí (${yesVoters.length})',
                style: VamosTypography.caption.copyWith(
                  color: VamosColors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: VamosSpacing.xs),
          ...yesVoters.map(
            (e) => Padding(
              padding: const EdgeInsets.only(
                left: VamosSpacing.md,
                bottom: VamosSpacing.xs,
              ),
              child: Text(
                e.key == currentUserId ? 'Vos' : _shortenUserId(e.key),
                style: VamosTypography.bodyMedium,
              ),
            ),
          ),
          const SizedBox(height: VamosSpacing.sm),
        ],
        if (noVoters.isNotEmpty) ...[
          Row(
            children: [
              const Icon(Icons.thumb_down_outlined,
                  size: 14, color: VamosColors.red),
              const SizedBox(width: VamosSpacing.xs),
              Text(
                'No (${noVoters.length})',
                style: VamosTypography.caption.copyWith(
                  color: VamosColors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: VamosSpacing.xs),
          ...noVoters.map(
            (e) => Padding(
              padding: const EdgeInsets.only(
                left: VamosSpacing.md,
                bottom: VamosSpacing.xs,
              ),
              child: Text(
                e.key == currentUserId ? 'Vos' : _shortenUserId(e.key),
                style: VamosTypography.bodyMedium,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Returns a shortened user ID for display until member aliases are available.
  String _shortenUserId(String uid) {
    if (uid.length <= 8) return uid;
    return '${uid.substring(0, 4)}…${uid.substring(uid.length - 4)}';
  }
}

// ---------------------------------------------------------------------------
// Action buttons (F2-06 confirm, F2-07 edit/delete, F2-08 move-day)
// ---------------------------------------------------------------------------

class _ActionButtons extends ConsumerWidget {
  const _ActionButtons({
    required this.tripId,
    required this.item,
    required this.trip,
    required this.isFacilitator,
    required this.canEdit,
    required this.currentUserId,
  });

  final String tripId;
  final ItineraryItem item;
  final Trip trip;
  final bool isFacilitator;
  final bool canEdit;
  final String currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionsState = ref.watch(itemActionsProvider);
    final isLoading = actionsState.isLoading;
    final isConfirmed = item.status == 'confirmed';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Confirm / revert — only facilitator
        if (isFacilitator) ...[
          FilledButton(
            onPressed: isLoading
                ? null
                : () async {
                    final newStatus =
                        isConfirmed ? 'proposed' : 'confirmed';
                    final updated = item.copyWith(
                      status: newStatus,
                      updatedAt: DateTime.now(),
                    );
                    await ref.read(itemActionsProvider.notifier).updateItem(
                          tripId: tripId,
                          item: updated,
                        );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isConfirmed
                              ? 'Item vuelto a propuesto.'
                              : 'Item confirmado.'),
                        ),
                      );
                    }
                  },
            child: Text(isConfirmed
                ? '↩ Volver a propuesto'
                : '✓ Confirmar item'),
          ),
          const SizedBox(height: VamosSpacing.sm),
        ],
      ],
    );
  }
}
