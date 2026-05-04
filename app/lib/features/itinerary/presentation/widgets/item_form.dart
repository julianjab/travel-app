import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vamos/core/theme/vamos_colors.dart';
import 'package:vamos/core/theme/vamos_spacing.dart';
import 'package:vamos/core/theme/vamos_typography.dart';
import 'package:vamos/data/models/trip.dart';

/// Form data produced by [ItemForm].
class ItemFormData {
  const ItemFormData({
    required this.title,
    required this.day,
    this.time,
    this.location,
    this.notes,
  });

  final String title;
  final DateTime day;
  final String? time;
  final String? location;
  final String? notes;
}

/// Shared form for creating and editing itinerary items (F2.2).
///
/// Used by [CreateItemScreen] and [EditItemScreen]. Renders fields for title,
/// day, time, location, and notes. Calls [onSubmit] with [ItemFormData] when
/// the form is valid and the user presses "Guardar".
class ItemForm extends StatefulWidget {
  const ItemForm({
    super.key,
    required this.trip,
    required this.onSubmit,
    required this.isLoading,
    this.initialTitle,
    this.initialDay,
    this.initialTime,
    this.initialLocation,
    this.initialNotes,
  });

  final Trip trip;
  final Future<void> Function(ItemFormData data) onSubmit;
  final bool isLoading;

  // Pre-fill values (for editing)
  final String? initialTitle;
  final DateTime? initialDay;
  final String? initialTime;
  final String? initialLocation;
  final String? initialNotes;

  @override
  State<ItemForm> createState() => _ItemFormState();
}

class _ItemFormState extends State<ItemForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _locationController;
  late final TextEditingController _notesController;

  late DateTime _selectedDay;
  String? _selectedTime; // null = "Sin hora"

  /// Generates trip days from startDate to endDate inclusive.
  List<DateTime> get _tripDays {
    final days = <DateTime>[];
    var current = DateTime(
      widget.trip.startDate.year,
      widget.trip.startDate.month,
      widget.trip.startDate.day,
    );
    final end = DateTime(
      widget.trip.endDate.year,
      widget.trip.endDate.month,
      widget.trip.endDate.day,
    );
    while (!current.isAfter(end)) {
      days.add(current);
      current = current.add(const Duration(days: 1));
    }
    return days;
  }

  /// Generates time options at 15-minute intervals from 00:00 to 23:45.
  List<String> get _timeOptions {
    final options = <String>[];
    for (var h = 0; h < 24; h++) {
      for (var m = 0; m < 60; m += 15) {
        final hStr = h.toString().padLeft(2, '0');
        final mStr = m.toString().padLeft(2, '0');
        options.add('$hStr:$mStr');
      }
    }
    return options;
  }

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.initialTitle ?? '');
    _locationController =
        TextEditingController(text: widget.initialLocation ?? '');
    _notesController =
        TextEditingController(text: widget.initialNotes ?? '');

    // Default day: initialDay or first trip day
    final tripDays = _tripDays;
    if (widget.initialDay != null) {
      final normalised = DateTime(
        widget.initialDay!.year,
        widget.initialDay!.month,
        widget.initialDay!.day,
      );
      _selectedDay = tripDays.contains(normalised)
          ? normalised
          : tripDays.first;
    } else {
      _selectedDay = tripDays.first;
    }

    _selectedTime = widget.initialTime;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final data = ItemFormData(
      title: _titleController.text.trim(),
      day: _selectedDay,
      time: _selectedTime,
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );
    await widget.onSubmit(data);
  }

  @override
  Widget build(BuildContext context) {
    final dayFormat = DateFormat('EEE d MMM', 'es');
    final tripDays = _tripDays;
    final timeOptions = _timeOptions;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(VamosSpacing.md),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---- Título ----
            Text('Título', style: VamosTypography.caption),
            const SizedBox(height: VamosSpacing.xs),
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Ej: Cena en Aprazível',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'El título es obligatorio' : null,
            ),
            const SizedBox(height: VamosSpacing.lg),

            // ---- Día ----
            Text('Día', style: VamosTypography.caption),
            const SizedBox(height: VamosSpacing.xs),
            DropdownButtonFormField<DateTime>(
              // ignore: deprecated_member_use
              value: _selectedDay,
              decoration: const InputDecoration(),
              items: tripDays.map((day) {
                return DropdownMenuItem(
                  value: day,
                  child: Text(
                    dayFormat.format(day),
                    style: VamosTypography.bodyMedium,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedDay = value);
              },
              validator: (_) => null,
            ),
            const SizedBox(height: VamosSpacing.lg),

            // ---- Hora (opcional) ----
            Text(
              'Hora (opcional)',
              style: VamosTypography.caption,
            ),
            const SizedBox(height: VamosSpacing.xs),
            DropdownButtonFormField<String?>(
              // ignore: deprecated_member_use
              value: _selectedTime,
              decoration: const InputDecoration(),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Sin hora'),
                ),
                ...timeOptions.map(
                  (t) => DropdownMenuItem<String?>(
                    value: t,
                    child: Text(
                      t,
                      style: VamosTypography.monoMedium,
                    ),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _selectedTime = value),
            ),
            const SizedBox(height: VamosSpacing.lg),

            // ---- Ubicación (opcional) ----
            Text(
              'Ubicación (opcional)',
              style: VamosTypography.caption,
            ),
            const SizedBox(height: VamosSpacing.xs),
            TextFormField(
              controller: _locationController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Ej: R. Aprazível 62, Santa Teresa',
              ),
            ),
            const SizedBox(height: VamosSpacing.lg),

            // ---- Notas (opcional) ----
            Text(
              'Notas (opcional)',
              style: VamosTypography.caption,
            ),
            const SizedBox(height: VamosSpacing.xs),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Reservar con anticipación, etc.',
              ),
            ),
            const SizedBox(height: VamosSpacing.xl),

            // ---- Submit ----
            FilledButton(
              onPressed: widget.isLoading ? null : _handleSubmit,
              child: widget.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: VamosColors.textOnDark,
                      ),
                    )
                  : const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
