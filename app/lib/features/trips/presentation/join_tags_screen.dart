import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vamos/core/theme/vamos_colors.dart';
import 'package:vamos/core/theme/vamos_spacing.dart';
import 'package:vamos/core/theme/vamos_typography.dart';
import 'package:vamos/data/repositories/member_repository.dart';
import 'package:vamos/features/trips/application/join_trip_notifier.dart';

// ---------------------------------------------------------------------------
// Tag constants (source: docs/06-identidad-y-tono.md)
// ---------------------------------------------------------------------------

const _dietOptions = [
  'vegetariano',
  'vegano',
  'celíaco',
  'sin-lactosa',
  'sin-mariscos',
  'halal',
  'kosher',
];

const _paceOptions = [
  'camina mucho',
  'ritmo tranquilo',
  'nocturno',
  'madrugador',
];

const _budgetOptions = [
  'ajustado',
  'medio',
  'amplio',
];

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// F1.5 — Preference tags screen (shown to ALL invitees as the last step).
///
/// Multi-select for diet restrictions and pace tags; single-select for budget.
/// The "Entrar al viaje" button is always enabled — tags are optional (A3 scope
/// decision). On submit → calls [JoinTripNotifier.submitOnboarding], then
/// navigates to `/trips/:tripId` on success.
///
/// Exact header microcopy from `docs/06-identidad-y-tono.md` §5.3:
///   "Esto lo va a ver el grupo. Saltá lo que no aplique."
class JoinTagsScreen extends ConsumerStatefulWidget {
  const JoinTagsScreen({
    super.key,
    required this.inviteCode,
    required this.tripId,
    required this.isNewUser,
  });

  final String inviteCode;
  final String tripId;
  final bool isNewUser;

  @override
  ConsumerState<JoinTagsScreen> createState() => _JoinTagsScreenState();
}

class _JoinTagsScreenState extends ConsumerState<JoinTagsScreen> {
  final Set<String> _selectedDiet = {};
  final Set<String> _selectedPace = {};
  String _selectedBudget = '';

  void _toggleDiet(String tag) {
    setState(() {
      if (_selectedDiet.contains(tag)) {
        _selectedDiet.remove(tag);
      } else {
        _selectedDiet.add(tag);
      }
    });
  }

  void _togglePace(String tag) {
    setState(() {
      if (_selectedPace.contains(tag)) {
        _selectedPace.remove(tag);
      } else {
        _selectedPace.add(tag);
      }
    });
  }

  void _selectBudget(String option) {
    setState(() {
      _selectedBudget = _selectedBudget == option ? '' : option;
    });
  }

  Future<void> _onSubmit() async {
    final notifier = ref.read(joinTripProvider(widget.inviteCode).notifier);
    notifier.setDietTags(_selectedDiet.toList());
    notifier.setPaceTags(_selectedPace.toList());
    notifier.setBudget(_selectedBudget);

    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    await notifier.submitOnboarding(
      tripId: widget.tripId,
      userId: userId,
      isNewUser: widget.isNewUser,
    );

    if (!mounted) return;
    final joinState = ref.read(joinTripProvider(widget.inviteCode));
    joinState.when(
      data: (_) => context.go('/trips/${widget.tripId}'),
      error: (err, _) => _showError(err),
      loading: () {},
    );
  }

  void _showError(Object err) {
    final message = err is InviteLinkInactiveException
        ? 'Este link ya no está activo.'
        : 'No se pudo unir al viaje. Intentá de nuevo.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: VamosTypography.bodyMedium),
        backgroundColor: VamosColors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final joinAsync = ref.watch(joinTripProvider(widget.inviteCode));
    final isSubmitting = joinAsync.isLoading;

    // Listen for errors after build — surfaces async errors in a snackbar.
    ref.listen(joinTripProvider(widget.inviteCode), (_, next) {
      if (next.hasError) _showError(next.error!);
    });

    return Scaffold(
      backgroundColor: VamosColors.bg,
      appBar: AppBar(
        backgroundColor: VamosColors.bg,
        elevation: 0,
        title: Text(
          'Contanos un poco',
          style: VamosTypography.headlineMedium,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: VamosSpacing.lg,
                  vertical: VamosSpacing.md,
                ),
                children: [
                  // Header microcopy — exact string from §5.3
                  Text(
                    'Esto lo va a ver el grupo. Saltá lo que no aplique.',
                    style: VamosTypography.bodyMedium,
                  ),

                  const SizedBox(height: VamosSpacing.lg),
                  const Divider(color: VamosColors.border),
                  const SizedBox(height: VamosSpacing.lg),

                  // Diet section
                  _SectionHeader(label: '¿Comés de todo?'),
                  const SizedBox(height: VamosSpacing.sm),
                  _TagGroup(
                    options: _dietOptions,
                    selected: _selectedDiet,
                    onToggle: _toggleDiet,
                    multiSelect: true,
                  ),

                  const SizedBox(height: VamosSpacing.lg),
                  const Divider(color: VamosColors.border),
                  const SizedBox(height: VamosSpacing.lg),

                  // Pace section
                  _SectionHeader(label: 'Estilo de viaje'),
                  const SizedBox(height: VamosSpacing.sm),
                  _TagGroup(
                    options: _paceOptions,
                    selected: _selectedPace,
                    onToggle: _togglePace,
                    multiSelect: true,
                  ),

                  const SizedBox(height: VamosSpacing.lg),
                  const Divider(color: VamosColors.border),
                  const SizedBox(height: VamosSpacing.lg),

                  // Budget section (single-select)
                  _SectionHeader(label: 'Presupuesto cómodo'),
                  const SizedBox(height: VamosSpacing.sm),
                  _TagGroup(
                    options: _budgetOptions,
                    selected: _selectedBudget.isEmpty ? {} : {_selectedBudget},
                    onToggle: _selectBudget,
                    multiSelect: false,
                  ),

                  const SizedBox(height: VamosSpacing.xl),
                ],
              ),
            ),

            // Bottom CTA — always enabled
            Padding(
              padding: const EdgeInsets.fromLTRB(
                VamosSpacing.lg,
                VamosSpacing.sm,
                VamosSpacing.lg,
                VamosSpacing.lg,
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: isSubmitting ? null : _onSubmit,
                  style: FilledButton.styleFrom(
                    backgroundColor: VamosColors.sol500,
                    disabledBackgroundColor: VamosColors.sol500.withAlpha(120),
                    shape: RoundedRectangleBorder(
                      borderRadius: VamosRadius.brFull,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: VamosSpacing.md,
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          height: VamosSpacing.lg,
                          width: VamosSpacing.lg,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: VamosColors.textOnDark,
                          ),
                        )
                      : Text(
                          'Entrar al viaje',
                          style: VamosTypography.titleMedium.copyWith(
                            color: VamosColors.textOnDark,
                          ),
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
// Shared sub-widgets
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: VamosTypography.titleMedium);
  }
}

/// Renders a wrap of selectable filter chips.
class _TagGroup extends StatelessWidget {
  const _TagGroup({
    required this.options,
    required this.selected,
    required this.onToggle,
    required this.multiSelect,
  });

  final List<String> options;
  final Set<String> selected;
  final void Function(String) onToggle;

  /// When false, behaves like a single-select (radio group).
  final bool multiSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: VamosSpacing.sm,
      runSpacing: VamosSpacing.sm,
      children: options.map((option) {
        final isSelected = selected.contains(option);
        return FilterChip(
          label: Text(
            option,
            style: VamosTypography.bodyMedium.copyWith(
              color: isSelected ? VamosColors.textOnDark : VamosColors.text2,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          selected: isSelected,
          onSelected: (_) => onToggle(option),
          backgroundColor: VamosColors.surface,
          selectedColor: VamosColors.sol500,
          checkmarkColor: VamosColors.textOnDark,
          side: BorderSide(
            color: isSelected ? VamosColors.sol500 : VamosColors.border,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: VamosRadius.brFull,
          ),
          showCheckmark: false,
          padding: const EdgeInsets.symmetric(
            horizontal: VamosSpacing.sm,
            vertical: VamosSpacing.xs,
          ),
        );
      }).toList(),
    );
  }
}
