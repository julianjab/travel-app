import 'package:flutter/material.dart';
import 'package:vamos/core/theme/vamos_colors.dart';
import 'package:vamos/core/theme/vamos_spacing.dart';
import 'package:vamos/core/theme/vamos_typography.dart';

/// A labeled dropdown that lets the user pick the trip's main currency.
///
/// Shows the LATAM-focused currency list. Includes a helper text reminding
/// the user that the currency cannot be changed after the trip is created.
///
/// Default currency is COP (Colombian Peso) per LATAM-first product principle
/// (see docs/02-prd-inicial.md §3). The parent form overrides this default
/// and listens for changes via [onChanged].
///
/// Uses [DropdownButton] (not DropdownButtonFormField) because the parent
/// [CreateTripScreen] owns the selected value in its own state — this is a
/// fully controlled widget.
class CurrencyPickerField extends StatelessWidget {
  const CurrencyPickerField({
    super.key,
    required this.value,
    this.onChanged,
  });

  /// Currently selected ISO 4217 currency code (e.g. "COP").
  final String value;

  /// Called with the newly selected currency code when the user picks one.
  /// When null, the dropdown is effectively disabled.
  final ValueChanged<String?>? onChanged;

  /// LATAM-focused currency list. Ordered by estimated user frequency.
  static const List<({String code, String label})> _currencies = [
    (code: 'COP', label: 'COP — Peso colombiano'),
    (code: 'ARS', label: 'ARS — Peso argentino'),
    (code: 'MXN', label: 'MXN — Peso mexicano'),
    (code: 'BRL', label: 'BRL — Real brasileño'),
    (code: 'CLP', label: 'CLP — Peso chileno'),
    (code: 'PEN', label: 'PEN — Sol peruano'),
    (code: 'UYU', label: 'UYU — Peso uruguayo'),
    (code: 'USD', label: 'USD — Dólar estadounidense'),
    (code: 'EUR', label: 'EUR — Euro'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Moneda principal', style: VamosTypography.bodyMedium),
        const SizedBox(height: VamosSpacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: VamosSpacing.md,
            vertical: VamosSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: VamosColors.surface,
            borderRadius: VamosRadius.brMd,
            border: Border.all(color: VamosColors.border),
          ),
          child: DropdownButton<String>(
            value: value,
            onChanged: onChanged,
            isExpanded: true,
            underline: const SizedBox.shrink(), // hide the default underline
            style: VamosTypography.bodyLarge.copyWith(color: VamosColors.text),
            dropdownColor: VamosColors.surface,
            borderRadius: VamosRadius.brMd,
            items: _currencies
                .map(
                  (c) => DropdownMenuItem(
                    value: c.code,
                    child: Text(c.label, style: VamosTypography.bodyLarge),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: VamosSpacing.xs),
        Text(
          'La moneda no se puede cambiar después de crear el viaje.',
          style: VamosTypography.caption,
        ),
      ],
    );
  }
}
