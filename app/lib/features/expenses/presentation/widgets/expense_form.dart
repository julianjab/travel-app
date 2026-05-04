import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:vamos/core/theme/vamos_colors.dart';
import 'package:vamos/core/theme/vamos_spacing.dart';
import 'package:vamos/core/theme/vamos_typography.dart';
import 'package:vamos/data/models/expense.dart';
import 'package:vamos/data/models/trip.dart';

/// The split mode available in the expense form.
enum _SplitMode { equal, percentage, amount }

/// Reusable expense form used by both [CreateExpenseScreen] and
/// [EditExpenseScreen].
///
/// All UI state is owned here. When the user taps "Guardar" the [onSubmit]
/// callback receives a fully built [Expense] (with a generated id and
/// placeholder createdAt/createdBy — the caller fills those).
class ExpenseForm extends StatefulWidget {
  const ExpenseForm({
    super.key,
    required this.trip,
    required this.onSubmit,
    required this.isLoading,
    this.initial,
  });

  final Trip trip;
  final ValueChanged<Expense> onSubmit;
  final bool isLoading;

  /// Pre-filled expense for edit mode. null when creating.
  final Expense? initial;

  @override
  State<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<ExpenseForm> {
  final _formKey = GlobalKey<FormState>();

  // --- Controllers ---
  late final TextEditingController _descCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _rateCtrl;

  // --- Values ---
  late String _currency;
  late String _paidBy;
  late DateTime _date;
  late _SplitMode _splitMode;

  /// Which members are included in the split (for all modes).
  late Map<String, bool> _included;

  /// Controllers for per-member percentage / amount inputs.
  late Map<String, TextEditingController> _memberCtrl;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _descCtrl = TextEditingController(text: initial?.description ?? '');
    _amountCtrl = TextEditingController(
      text: initial != null ? initial.amount.toString() : '',
    );
    _rateCtrl = TextEditingController(
      text: initial != null ? initial.exchangeRate.toString() : '1',
    );
    _currency = initial?.currency ?? widget.trip.mainCurrency;
    _paidBy = initial?.paidBy ??
        (widget.trip.memberIds.isNotEmpty ? widget.trip.memberIds.first : '');
    _date = initial?.date ?? DateTime.now();
    _splitMode = _parseSplitMode(initial?.splitType ?? 'equal');

    // Initialize inclusion: default all members included.
    final includedSet = initial?.splitBetween.toSet() ?? widget.trip.memberIds.toSet();
    _included = {
      for (final uid in widget.trip.memberIds) uid: includedSet.contains(uid),
    };

    // Initialize per-member controllers.
    final details = initial?.splitDetails ?? {};
    _memberCtrl = {
      for (final uid in widget.trip.memberIds)
        uid: TextEditingController(
          text: details.containsKey(uid) ? details[uid].toString() : '',
        ),
    };
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    _rateCtrl.dispose();
    for (final ctrl in _memberCtrl.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  _SplitMode _parseSplitMode(String raw) {
    switch (raw) {
      case 'percentage':
        return _SplitMode.percentage;
      case 'amount':
        return _SplitMode.amount;
      default:
        return _SplitMode.equal;
    }
  }

  String _splitModeKey(_SplitMode mode) {
    switch (mode) {
      case _SplitMode.percentage:
        return 'percentage';
      case _SplitMode.amount:
        return 'amount';
      case _SplitMode.equal:
        return 'equal';
    }
  }

  List<String> get _selectedMembers =>
      widget.trip.memberIds.where((uid) => _included[uid] == true).toList();

  bool get _showExchangeRate => _currency != widget.trip.mainCurrency;

  double get _parsedAmount =>
      double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ?? 0;

  double get _parsedRate =>
      double.tryParse(_rateCtrl.text.replaceAll(',', '.')) ?? 1;

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  String? _validateAmount(String? v) {
    if (v == null || v.isEmpty) return 'Ingresá el monto';
    final n = double.tryParse(v.replaceAll(',', '.'));
    if (n == null || n <= 0) return 'Ingresá un monto válido';
    return null;
  }

  String? _validateRate(String? v) {
    if (v == null || v.isEmpty) return 'Ingresá la tasa';
    final n = double.tryParse(v.replaceAll(',', '.'));
    if (n == null || n <= 0) return 'Tasa inválida';
    return null;
  }

  /// Returns an error string if the split details are inconsistent, or null.
  String? _validateSplitDetails() {
    final selected = _selectedMembers;
    if (selected.isEmpty) return 'Seleccioná al menos un integrante';

    if (_splitMode == _SplitMode.percentage) {
      double total = 0;
      for (final uid in selected) {
        final v = double.tryParse(_memberCtrl[uid]!.text.replaceAll(',', '.'));
        if (v == null || v < 0) return 'Ingresá un porcentaje válido para cada integrante';
        total += v;
      }
      if ((total - 100).abs() > 0.5) {
        return 'Los porcentajes deben sumar 100%. Ahora suman ${total.toStringAsFixed(1)}%.';
      }
    } else if (_splitMode == _SplitMode.amount) {
      final totalExpense = _parsedAmount;
      double splitTotal = 0;
      for (final uid in selected) {
        final v = double.tryParse(_memberCtrl[uid]!.text.replaceAll(',', '.'));
        if (v == null || v < 0) return 'Ingresá un monto válido para cada integrante';
        splitTotal += v;
      }
      if ((splitTotal - totalExpense).abs() > 0.01) {
        return 'Los montos deben sumar ${totalExpense.toStringAsFixed(2)}. Ahora suman ${splitTotal.toStringAsFixed(2)}.';
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Submit
  // ---------------------------------------------------------------------------

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final splitError = _validateSplitDetails();
    if (splitError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(splitError)),
      );
      return;
    }

    final selected = _selectedMembers;
    final amount = _parsedAmount;
    final rate = _showExchangeRate ? _parsedRate : 1.0;

    Map<String, dynamic>? splitDetails;
    if (_splitMode != _SplitMode.equal) {
      splitDetails = {
        for (final uid in selected)
          uid: double.tryParse(
                _memberCtrl[uid]!.text.replaceAll(',', '.'),
              ) ??
              0.0,
      };
    }

    final expense = Expense(
      // Generate a unique ID. The repo will use this as the document key.
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount,
      currency: _currency,
      exchangeRate: rate,
      amountInMainCurrency: amount * rate,
      description: _descCtrl.text.trim().isNotEmpty ? _descCtrl.text.trim() : null,
      paidBy: _paidBy,
      splitBetween: selected,
      splitType: _splitModeKey(_splitMode),
      splitDetails: splitDetails,
      date: _date,
      createdAt: DateTime.now(),
      createdBy: '', // filled by caller
      hasSettlements: false,
      editHistory: const [],
    );

    widget.onSubmit(expense);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(VamosSpacing.md),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Descripción ---
            _SectionLabel(text: 'Descripción'),
            const SizedBox(height: VamosSpacing.xs),
            TextFormField(
              controller: _descCtrl,
              decoration: _inputDecoration('Ej: Almuerzo en el centro'),
              style: VamosTypography.bodyLarge,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: VamosSpacing.md),

            // --- Monto + Moneda ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel(text: 'Monto'),
                      const SizedBox(height: VamosSpacing.xs),
                      TextFormField(
                        controller: _amountCtrl,
                        decoration: _inputDecoration('0.00'),
                        style: VamosTypography.monoMedium,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                        ],
                        validator: _validateAmount,
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: VamosSpacing.sm),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel(text: 'Moneda'),
                      const SizedBox(height: VamosSpacing.xs),
                      _CurrencyDropdown(
                        value: _currency,
                        onChanged: (v) {
                          if (v != null) setState(() => _currency = v);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: VamosSpacing.md),

            // --- Tasa de cambio (only when currency differs) ---
            if (_showExchangeRate) ...[
              _SectionLabel(text: 'Tasa de cambio'),
              const SizedBox(height: VamosSpacing.xs),
              TextFormField(
                controller: _rateCtrl,
                decoration: _inputDecoration(
                  '1.0',
                  helper:
                      '1 ${_currency} = ? ${widget.trip.mainCurrency}',
                ),
                style: VamosTypography.monoMedium,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                validator: _validateRate,
              ),
              const SizedBox(height: VamosSpacing.md),
            ],

            // --- ¿Quién pagó? ---
            _SectionLabel(text: '¿Quién pagó?'),
            const SizedBox(height: VamosSpacing.xs),
            _MemberDropdown(
              memberIds: widget.trip.memberIds,
              value: _paidBy,
              onChanged: (v) {
                if (v != null) setState(() => _paidBy = v);
              },
            ),
            const SizedBox(height: VamosSpacing.md),

            // --- Fecha ---
            _SectionLabel(text: 'Fecha'),
            const SizedBox(height: VamosSpacing.xs),
            _DatePickerField(
              value: _date,
              onChanged: (d) => setState(() => _date = d),
            ),
            const SizedBox(height: VamosSpacing.md),

            // --- División ---
            _SectionLabel(text: 'División'),
            const SizedBox(height: VamosSpacing.sm),
            _SplitModeSelector(
              value: _splitMode,
              onChanged: (m) => setState(() => _splitMode = m),
            ),
            const SizedBox(height: VamosSpacing.sm),

            // Split detail inputs
            _SplitDetail(
              mode: _splitMode,
              memberIds: widget.trip.memberIds,
              included: _included,
              memberCtrl: _memberCtrl,
              onIncludedChanged: (uid, v) =>
                  setState(() => _included[uid] = v),
            ),
            const SizedBox(height: VamosSpacing.xl),

            // --- CTA ---
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: widget.isLoading ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: VamosColors.sol500,
                  foregroundColor: VamosColors.textOnDark,
                  disabledBackgroundColor: VamosColors.border,
                  shape: const RoundedRectangleBorder(
                    borderRadius: VamosRadius.brFull,
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: VamosSpacing.md,
                  ),
                ),
                child: widget.isLoading
                    ? const SizedBox(
                        height: VamosSpacing.md,
                        width: VamosSpacing.md,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: VamosColors.textOnDark,
                        ),
                      )
                    : const Text('Guardar'),
              ),
            ),
            const SizedBox(height: VamosSpacing.lg),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section label
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: VamosTypography.caption.copyWith(
        color: VamosColors.text3,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Input decoration helper
// ---------------------------------------------------------------------------

InputDecoration _inputDecoration(String hint, {String? helper}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: VamosTypography.bodyMedium.copyWith(color: VamosColors.textMuted),
    helperText: helper,
    helperStyle: VamosTypography.caption,
    filled: true,
    fillColor: VamosColors.surface,
    border: const OutlineInputBorder(
      borderRadius: VamosRadius.brMd,
      borderSide: BorderSide(color: VamosColors.border),
    ),
    enabledBorder: const OutlineInputBorder(
      borderRadius: VamosRadius.brMd,
      borderSide: BorderSide(color: VamosColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: VamosRadius.brMd,
      borderSide: const BorderSide(color: VamosColors.sol500, width: 2),
    ),
    errorBorder: const OutlineInputBorder(
      borderRadius: VamosRadius.brMd,
      borderSide: BorderSide(color: VamosColors.red),
    ),
    focusedErrorBorder: const OutlineInputBorder(
      borderRadius: VamosRadius.brMd,
      borderSide: BorderSide(color: VamosColors.red, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: VamosSpacing.md,
      vertical: VamosSpacing.sm,
    ),
  );
}

// ---------------------------------------------------------------------------
// Currency dropdown (inline in form)
// ---------------------------------------------------------------------------

class _CurrencyDropdown extends StatelessWidget {
  const _CurrencyDropdown({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String?> onChanged;

  static const _currencies = [
    'COP', 'ARS', 'MXN', 'BRL', 'CLP', 'PEN', 'UYU', 'USD', 'EUR',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
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
        value: _currencies.contains(value) ? value : _currencies.first,
        onChanged: onChanged,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        style: VamosTypography.monoMedium,
        items: _currencies
            .map(
              (c) => DropdownMenuItem(
                value: c,
                child: Text(c, style: VamosTypography.monoMedium),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Member dropdown (who paid)
// ---------------------------------------------------------------------------

class _MemberDropdown extends StatelessWidget {
  const _MemberDropdown({
    required this.memberIds,
    required this.value,
    required this.onChanged,
  });

  final List<String> memberIds;
  final String value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final safeValue = memberIds.contains(value) ? value : (memberIds.isNotEmpty ? memberIds.first : null);
    return Container(
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
        value: safeValue,
        onChanged: onChanged,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        style: VamosTypography.bodyLarge,
        hint: Text('Seleccioná', style: VamosTypography.bodyMedium),
        items: memberIds
            .map(
              (uid) => DropdownMenuItem(
                value: uid,
                child: Text(
                  _shortenId(uid),
                  style: VamosTypography.bodyLarge,
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  String _shortenId(String uid) =>
      uid.length > 12 ? uid.substring(0, 12) : uid;
}

// ---------------------------------------------------------------------------
// Date picker field
// ---------------------------------------------------------------------------

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({required this.value, required this.onChanged});

  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final formatted = DateFormat('dd/MM/yyyy', 'es').format(value);
    return InkWell(
      borderRadius: VamosRadius.brMd,
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          locale: const Locale('es'),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: VamosSpacing.md,
          vertical: VamosSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: VamosColors.surface,
          borderRadius: VamosRadius.brMd,
          border: Border.all(color: VamosColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(formatted, style: VamosTypography.monoMedium),
            ),
            const Icon(
              Icons.calendar_today_outlined,
              size: VamosSpacing.md,
              color: VamosColors.text3,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Split mode selector (segmented button)
// ---------------------------------------------------------------------------

class _SplitModeSelector extends StatelessWidget {
  const _SplitModeSelector({required this.value, required this.onChanged});

  final _SplitMode value;
  final ValueChanged<_SplitMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<_SplitMode>(
      style: SegmentedButton.styleFrom(
        backgroundColor: VamosColors.bg,
        selectedBackgroundColor: VamosColors.sol500,
        selectedForegroundColor: VamosColors.textOnDark,
        foregroundColor: VamosColors.text3,
        side: const BorderSide(color: VamosColors.border),
        shape: const RoundedRectangleBorder(
          borderRadius: VamosRadius.brMd,
        ),
        textStyle: VamosTypography.caption,
      ),
      segments: const [
        ButtonSegment(
          value: _SplitMode.equal,
          label: Text('Partes iguales'),
        ),
        ButtonSegment(
          value: _SplitMode.percentage,
          label: Text('Porcentajes'),
        ),
        ButtonSegment(
          value: _SplitMode.amount,
          label: Text('Montos'),
        ),
      ],
      selected: {value},
      onSelectionChanged: (set) {
        if (set.isNotEmpty) onChanged(set.first);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Split detail panel — shows per-mode inputs
// ---------------------------------------------------------------------------

class _SplitDetail extends StatelessWidget {
  const _SplitDetail({
    required this.mode,
    required this.memberIds,
    required this.included,
    required this.memberCtrl,
    required this.onIncludedChanged,
  });

  final _SplitMode mode;
  final List<String> memberIds;
  final Map<String, bool> included;
  final Map<String, TextEditingController> memberCtrl;
  final void Function(String uid, bool value) onIncludedChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: memberIds.map((uid) {
        final isIncluded = included[uid] ?? true;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: VamosSpacing.xs),
          child: Row(
            children: [
              // Checkbox for inclusion
              SizedBox(
                width: VamosSpacing.xl,
                child: Checkbox(
                  value: isIncluded,
                  activeColor: VamosColors.sol500,
                  onChanged: (v) => onIncludedChanged(uid, v ?? false),
                ),
              ),
              // Member label
              Expanded(
                child: Text(
                  _shortenId(uid),
                  style: VamosTypography.bodyMedium,
                ),
              ),
              // Per-member amount/percentage input (only shown when included)
              if (mode != _SplitMode.equal && isIncluded)
                SizedBox(
                  width: VamosSpacing.xxxl + VamosSpacing.lg,
                  child: TextFormField(
                    controller: memberCtrl[uid],
                    decoration: _inputDecoration(
                      mode == _SplitMode.percentage ? '%' : '0.00',
                    ),
                    style: VamosTypography.monoMedium,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    textAlign: TextAlign.right,
                  ),
                )
              else if (mode != _SplitMode.equal && !isIncluded)
                // Placeholder to keep row height consistent.
                const SizedBox(
                  width: VamosSpacing.xxxl + VamosSpacing.lg,
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _shortenId(String uid) =>
      uid.length > 16 ? uid.substring(0, 16) : uid;
}
