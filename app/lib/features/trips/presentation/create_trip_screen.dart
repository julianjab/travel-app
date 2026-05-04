import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vamos/core/theme/vamos_colors.dart';
import 'package:vamos/core/utils/date_formatters.dart';
import 'package:vamos/core/theme/vamos_spacing.dart';
import 'package:vamos/core/theme/vamos_typography.dart';
import 'package:vamos/features/trips/application/create_trip_notifier.dart';
import 'package:vamos/features/trips/presentation/widgets/currency_picker_field.dart';

/// F1.2 — "Crear viaje" form screen.
///
/// Collects: trip name, destination (free text), start date, end date, and
/// main currency. Cover photo slot is UI-only in MVP — no actual upload.
/// The "Crear viaje" button is disabled until all four required fields are
/// filled (name, destination, both dates, currency).
///
/// On success the screen navigates to `/trips/{newId}` via [GoRouter].
class CreateTripScreen extends ConsumerStatefulWidget {
  const CreateTripScreen({super.key});

  @override
  ConsumerState<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends ConsumerState<CreateTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _destinationController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  String _currency = 'COP'; // LATAM-first default

  bool _hasNavigated = false;

  @override
  void dispose() {
    _nameController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  bool get _isFormComplete =>
      _nameController.text.trim().isNotEmpty &&
      _destinationController.text.trim().isNotEmpty &&
      _startDate != null &&
      _endDate != null &&
      _currency.isNotEmpty;

  String _formatDate(DateTime? date) {
    if (date == null) return 'Elegir fecha';
    return formatShortDate(date);
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      helpText: 'Fecha de inicio',
    );
    if (picked == null) return;
    setState(() {
      _startDate = picked;
      // Reset end date if it's before the new start
      if (_endDate != null && _endDate!.isBefore(picked)) {
        _endDate = null;
      }
    });
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? (_startDate ?? DateTime.now()),
      firstDate: _startDate ?? DateTime(2024),
      lastDate: DateTime(2030),
      helpText: 'Fecha de fin',
    );
    if (picked == null) return;
    setState(() => _endDate = picked);
  }

  Future<void> _submit() async {
    if (!_isFormComplete) return;

    await ref.read(createTripProvider.notifier).create(
          name: _nameController.text,
          destination: _destinationController.text,
          startDate: _startDate!,
          endDate: _endDate!,
          mainCurrency: _currency,
        );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final createAsync = ref.watch(createTripProvider);

    // Navigate once when a tripId is available — avoids duplicate navigation
    // if the widget rebuilds after the state change.
    ref.listen<AsyncValue<CreateTripResult>>(createTripProvider, (_, next) {
      if (_hasNavigated) return;
      next.whenData((result) {
        if (result.tripId != null) {
          _hasNavigated = true;
          // Navigate to F1.3 (invite screen) instead of the trip stub.
          context.go('/trips/${result.tripId}/invite');
        }
      });
    });

    final isLoading = createAsync.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo viaje'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(VamosSpacing.md),
        child: Form(
          key: _formKey,
          onChanged: () => setState(() {}), // re-evaluate _isFormComplete
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ----------------------------------------------------------------
              // Cover photo slot (UI only — no upload in MVP)
              // ----------------------------------------------------------------
              _CoverPhotoSlot(),
              const SizedBox(height: VamosSpacing.lg),

              // ----------------------------------------------------------------
              // Nombre del viaje
              // ----------------------------------------------------------------
              Text('Nombre del viaje', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: VamosSpacing.xs),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Brasil con los del barrio',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: VamosSpacing.lg),

              // ----------------------------------------------------------------
              // Destino
              // ----------------------------------------------------------------
              Text('Destino', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: VamosSpacing.xs),
              TextFormField(
                controller: _destinationController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'Río de Janeiro',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: VamosSpacing.lg),

              // ----------------------------------------------------------------
              // Fechas
              // ----------------------------------------------------------------
              Text('Fechas', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: VamosSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: _DateButton(
                      label: _formatDate(_startDate),
                      onTap: isLoading ? null : _pickStartDate,
                    ),
                  ),
                  const SizedBox(width: VamosSpacing.sm),
                  Expanded(
                    child: _DateButton(
                      label: _formatDate(_endDate),
                      onTap: isLoading ? null : _pickEndDate,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: VamosSpacing.lg),

              // ----------------------------------------------------------------
              // Moneda principal
              // ----------------------------------------------------------------
              CurrencyPickerField(
                value: _currency,
                onChanged: isLoading
                    ? null
                    : (v) => setState(() => _currency = v ?? _currency),
              ),
              const SizedBox(height: VamosSpacing.xxl),

              // ----------------------------------------------------------------
              // Error from notifier
              // ----------------------------------------------------------------
              if (createAsync.hasError) ...[
                _ErrorBanner(message: _errorMessage(createAsync.error)),
                const SizedBox(height: VamosSpacing.md),
              ],

              // ----------------------------------------------------------------
              // Submit button
              // ----------------------------------------------------------------
              FilledButton(
                onPressed: (_isFormComplete && !isLoading) ? _submit : null,
                child: isLoading
                    ? const SizedBox(
                        height: VamosSpacing.md,
                        width: VamosSpacing.md,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: VamosColors.textOnDark,
                        ),
                      )
                    : const Text('Crear viaje'),
              ),

              const SizedBox(height: VamosSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  String _errorMessage(Object? error) {
    if (error is ArgumentError) return error.message as String;
    return 'Hubo un problema al crear el viaje. Intentá de nuevo.';
  }
}

// ---------------------------------------------------------------------------
// Private sub-widgets
// ---------------------------------------------------------------------------

/// UI-only cover photo slot. No actual upload in MVP.
/// Matches the wireframe: a tappable area with a camera icon and label.
class _CoverPhotoSlot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Cover photo upload is out of MVP scope — slot is UI only.
      },
      child: Container(
        height: VamosSpacing.xxxl + VamosSpacing.xxl, // 112
        decoration: BoxDecoration(
          color: VamosColors.surface2,
          borderRadius: VamosRadius.brLg,
          border: Border.all(color: VamosColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_camera_outlined,
              size: VamosSpacing.xl,
              color: VamosColors.text3,
            ),
            const SizedBox(height: VamosSpacing.xs),
            Text(
              'Foto de portada (opcional)',
              style: VamosTypography.caption,
            ),
          ],
        ),
      ),
    );
  }
}

/// Tappable date-picker button styled as an outlined container.
class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEmpty = label == 'Elegir fecha';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: VamosSpacing.md,
          vertical: VamosSpacing.sm + VamosSpacing.xs, // 12
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: VamosRadius.brMd,
          border: Border.all(color: colorScheme.outline),
        ),
        child: Text(
          label,
          style: VamosTypography.monoMedium.copyWith(
            color: isEmpty
                ? colorScheme.onSurface.withValues(alpha: 0.38)
                : colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Inline error banner shown when the notifier emits an error.
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(VamosSpacing.md),
      decoration: BoxDecoration(
        color: VamosColors.red.withValues(alpha: 0.08),
        borderRadius: VamosRadius.brMd,
        border: Border.all(color: VamosColors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline,
            color: VamosColors.red,
            size: VamosSpacing.md,
          ),
          const SizedBox(width: VamosSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: VamosTypography.bodyMedium.copyWith(
                color: VamosColors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
