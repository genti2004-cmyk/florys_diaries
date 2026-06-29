import 'dart:io';

import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/core/widgets/unsaved_changes_guard.dart';
import 'package:florys_diaries/features/trips/application/trip_store_scope.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

class TripEditorScreen extends StatefulWidget {
  const TripEditorScreen({this.trip, super.key});

  final Trip? trip;

  @override
  State<TripEditorScreen> createState() => _TripEditorScreenState();
}

class _TripEditorScreenState extends State<TripEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _destinationController;
  late final TextEditingController _countryController;
  late final TextEditingController _notesController;
  late DateTime _startDate;
  late DateTime _endDate;

  bool _hasUnsavedChanges = false;
  bool _isSaving = false;

  bool get _isEditing => widget.trip != null;

  @override
  void initState() {
    super.initState();
    final trip = widget.trip;
    _titleController = TextEditingController(text: trip?.title ?? '');
    _destinationController = TextEditingController(
      text: trip?.destination ?? '',
    );
    _countryController = TextEditingController(text: trip?.country ?? '');
    _notesController = TextEditingController(text: trip?.notes ?? '');

    final now = DateTime.now();
    _startDate = trip?.startDate ?? DateTime(now.year, now.month, now.day);
    _endDate = trip?.endDate ?? _startDate.add(const Duration(days: 3));

    _titleController.addListener(_markTextChanged);
    _destinationController.addListener(_markTextChanged);
    _countryController.addListener(_markTextChanged);
    _notesController.addListener(_markTextChanged);
  }

  @override
  void dispose() {
    _titleController
      ..removeListener(_markTextChanged)
      ..dispose();
    _destinationController
      ..removeListener(_markTextChanged)
      ..dispose();
    _countryController
      ..removeListener(_markTextChanged)
      ..dispose();
    _notesController
      ..removeListener(_markTextChanged)
      ..dispose();
    super.dispose();
  }

  void _markTextChanged() {
    if (_hasUnsavedChanges || !mounted) {
      return;
    }
    setState(() => _hasUnsavedChanges = true);
  }

  Future<void> _pickStartDate() async {
    final picked = await _pickDate(_startDate);
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _startDate = picked;
      if (_endDate.isBefore(_startDate)) {
        _endDate = _startDate;
      }
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _pickEndDate() async {
    final picked = await _pickDate(_endDate);
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _endDate = picked.isBefore(_startDate) ? _startDate : picked;
      _hasUnsavedChanges = true;
    });
  }

  Future<DateTime?> _pickDate(DateTime initialDate) {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
  }

  Future<void> _saveTrip() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (_isSaving || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    final store = TripStoreScope.of(context);
    final oldTrip = widget.trip;
    final title = _titleController.text.trim();
    final destination = _destinationController.text.trim();
    final country = _countryController.text.trim();
    final notes = _notesController.text.trim();

    final trip = oldTrip == null
        ? Trip(
            id: store.createId(),
            title: title,
            destination: destination,
            country: country,
            startDate: _startDate,
            endDate: _endDate,
            notes: notes,
          )
        : oldTrip.copyWith(
            title: title,
            destination: destination,
            country: country,
            startDate: _startDate,
            endDate: _endDate,
            notes: notes,
          );

    try {
      if (_isEditing) {
        await store.updateTrip(trip);
      } else {
        await store.addTrip(trip);
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
        _hasUnsavedChanges = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    } on FileSystemException catch (error) {
      _showSaveError(
        error.message.trim().isEmpty
            ? 'Die Reise konnte nicht gespeichert werden.'
            : error.message,
      );
    } catch (error) {
      debugPrint('Reise konnte nicht gespeichert werden: $error');
      _showSaveError('Die Reise konnte nicht gespeichert werden.');
    }
  }

  void _showSaveError(String message) {
    if (!mounted) {
      return;
    }
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return UnsavedChangesGuard<void>(
      hasUnsavedChanges: _hasUnsavedChanges && !_isSaving,
      title: 'Reiseänderungen verwerfen?',
      message: 'Die Änderungen an dieser Reise wurden noch nicht gespeichert.',
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Reise bearbeiten' : 'Reise anlegen'),
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              key: const PageStorageKey<String>('trip-editor-form'),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                _EditorTextField(
                  fieldKey: const ValueKey<String>('trip-editor-title'),
                  controller: _titleController,
                  enabled: !_isSaving,
                  label: 'Reisetitel',
                  hint: 'z. B. Sommer in Paris',
                  icon: Icons.card_travel,
                ),
                const SizedBox(height: 12),
                _EditorTextField(
                  fieldKey: const ValueKey<String>('trip-editor-destination'),
                  controller: _destinationController,
                  enabled: !_isSaving,
                  label: 'Stadt / Reiseziel',
                  hint: 'z. B. Paris',
                  icon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 12),
                _EditorTextField(
                  fieldKey: const ValueKey<String>('trip-editor-country'),
                  controller: _countryController,
                  enabled: !_isSaving,
                  label: 'Land',
                  hint: 'z. B. Frankreich',
                  icon: Icons.public_outlined,
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final startButton = _DateButton(
                      label: 'Start',
                      value: _formatDate(_startDate),
                      enabled: !_isSaving,
                      onPressed: _pickStartDate,
                    );
                    final endButton = _DateButton(
                      label: 'Ende',
                      value: _formatDate(_endDate),
                      enabled: !_isSaving,
                      onPressed: _pickEndDate,
                    );

                    if (constraints.maxWidth < 330) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          startButton,
                          const SizedBox(height: 10),
                          endButton,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: startButton),
                        const SizedBox(width: 12),
                        Expanded(child: endButton),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey<String>('trip-editor-notes'),
                  controller: _notesController,
                  enabled: !_isSaving,
                  minLines: 4,
                  maxLines: 7,
                  decoration: const InputDecoration(
                    labelText: 'Notizen',
                    hintText: 'Hotel, Pläne, wichtige Hinweise ...',
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  key: const ValueKey<String>('trip-editor-save'),
                  onPressed: _isSaving ? null : _saveTrip,
                  icon: _isSaving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(
                    _isEditing ? 'Änderungen speichern' : 'Reise speichern',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }
}

class _EditorTextField extends StatelessWidget {
  const _EditorTextField({
    required this.fieldKey,
    required this.controller,
    required this.enabled,
    required this.label,
    required this.hint,
    required this.icon,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final bool enabled;
  final String label;
  final String hint;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: fieldKey,
      controller: controller,
      enabled: enabled,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Bitte ausfüllen';
        }
        return null;
      },
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final String value;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: enabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.all(14),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
