import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vamos/core/theme/vamos_colors.dart';
import 'package:vamos/core/theme/vamos_spacing.dart';
import 'package:vamos/core/theme/vamos_typography.dart';
import 'package:vamos/features/trips/application/join_trip_notifier.dart';

/// F1.4 — Profile setup screen (shown ONLY to new users).
///
/// Existing users skip this screen entirely — the router sends them directly
/// to [JoinAliasScreen]. New users set their global display name here. Profile
/// photo upload is deferred (Storage not in MVP); a disabled placeholder is
/// shown instead.
///
/// On "Siguiente" → navigates to /join/:code/alias passing [tripId].
class JoinProfileScreen extends ConsumerStatefulWidget {
  const JoinProfileScreen({
    super.key,
    required this.inviteCode,
    required this.tripId,
  });

  final String inviteCode;
  final String tripId;

  @override
  ConsumerState<JoinProfileScreen> createState() => _JoinProfileScreenState();
}

class _JoinProfileScreenState extends ConsumerState<JoinProfileScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onContinue() {
    if (_formKey.currentState?.validate() != true) return;

    ref
        .read(joinTripProvider(widget.inviteCode).notifier)
        .setDisplayName(_nameController.text.trim());

    context.push(
      '/join/${widget.inviteCode}/alias',
      extra: {'tripId': widget.tripId, 'isNewUser': true},
    );
  }

  @override
  Widget build(BuildContext context) {
    final nameText = _nameController.text.trim();
    final canContinue = nameText.isNotEmpty;

    return Scaffold(
      backgroundColor: VamosColors.bg,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(VamosSpacing.lg),
            children: [
              const SizedBox(height: VamosSpacing.xxl),

              // Header
              Text(
                'Antes de sumarte al viaje...',
                style: VamosTypography.displayMedium,
              ),
              const SizedBox(height: VamosSpacing.sm),
              Text(
                'Completá tu perfil una sola vez. Lo vas a usar en todos tus viajes.',
                style: VamosTypography.bodyMedium,
              ),

              const SizedBox(height: VamosSpacing.xl),
              const Divider(color: VamosColors.border),
              const SizedBox(height: VamosSpacing.xl),

              // Name field
              Text('Tu nombre', style: VamosTypography.caption),
              const SizedBox(height: VamosSpacing.sm),
              TextFormField(
                controller: _nameController,
                onChanged: (_) => setState(() {}),
                textCapitalization: TextCapitalization.words,
                style: VamosTypography.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Andrés Gómez',
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
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresá tu nombre para continuar';
                  }
                  return null;
                },
              ),

              const SizedBox(height: VamosSpacing.xl),

              // Photo placeholder (Storage deferred)
              Text('Foto de perfil (opcional)', style: VamosTypography.caption),
              const SizedBox(height: VamosSpacing.sm),
              _PhotoPlaceholder(),

              const SizedBox(height: VamosSpacing.sm),
              Text(
                'En tu perfil sos vos. Podés usar un apodo diferente en cada viaje en la pantalla siguiente.',
                style: VamosTypography.bodyMedium,
              ),

              const SizedBox(height: VamosSpacing.xxxl),

              // CTA
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: canContinue ? _onContinue : null,
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
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Photo placeholder widget
// ---------------------------------------------------------------------------

/// Disabled photo upload placeholder. Storage upload is deferred to v1.1+.
class _PhotoPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: VamosColors.surface2,
        borderRadius: VamosRadius.brMd,
        border: Border.all(color: VamosColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_a_photo_outlined,
            size: VamosSpacing.lg,
            color: VamosColors.textMuted,
          ),
          const SizedBox(width: VamosSpacing.sm),
          Text(
            'Foto · próximamente',
            style: VamosTypography.bodyMedium.copyWith(
              color: VamosColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
