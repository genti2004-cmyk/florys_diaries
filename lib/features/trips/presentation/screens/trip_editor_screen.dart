import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
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
  }

  @override
  void dispose() {
    _titleController.dispose();
    _destinationController.dispose();
    _countryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await _pickDate(_startDate);
    if (picked == null) {
      return;
    }
    setState(() {
      _startDate = picked;
      if (_endDate.isBefore(_startDate)) {
        _endDate = _startDate;
      }
    });
  }

  Future<void> _pickEndDate() async {
    final picked = await _pickDate(_endDate);
    if (picked == null) {
      return;
    }
    setState(() {
      _endDate = picked.isBefore(_startDate) ? _startDate : picked;
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final store = TripStoreScope.of(context);
    final oldTrip = widget.trip;
    final trip = Trip(
      id: oldTrip?.id ?? store.createId(),
      title: _titleController.text.trim(),
      destination: _destinationController.text.trim(),
      country: _countryController.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
      notes: _notesController.text.trim(),
      documents: oldTrip?.documents ?? const [],
      photoCount: oldTrip?.photoCount ?? 0,
    );

    if (_isEditing) {
      await store.updateTrip(trip);
    } else {
      await store.addTrip(trip);
    }

    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Reise bearbeiten' : 'Reise anlegen'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _EditorTextField(
                controller: _titleController,
                label: 'Reisetitel',
                hint: 'z. B. Sommer in Paris',
                icon: Icons.card_travel,
              ),
              const SizedBox(height: 12),
              _EditorTextField(
                controller: _destinationController,
                label: 'Stadt / Reiseziel',
                hint: 'z. B. Paris',
                icon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 12),
              _EditorTextField(
                controller: _countryController,
                label: 'Land',
                hint: 'z. B. Frankreich',
                icon: Icons.public_outlined,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _DateButton(
                      label: 'Start',
                      value: _formatDate(_startDate),
                      onPressed: _pickStartDate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DateButton(
                      label: 'Ende',
                      value: _formatDate(_endDate),
                      onPressed: _pickEndDate,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
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
                onPressed: _saveTrip,
                icon: const Icon(Icons.check),
                label: Text(
                  _isEditing ? 'Änderungen speichern' : 'Reise speichern',
                ),
              ),
            ],
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
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
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
    required this.onPressed,
  });

  final String label;
  final String value;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
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
