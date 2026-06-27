import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/features/checklist/domain/trip_checklist_item.dart';

class ChecklistItemEditorResult {
  const ChecklistItemEditorResult.save(this.item) : delete = false;
  const ChecklistItemEditorResult.delete(this.item) : delete = true;

  final TripChecklistItem item;
  final bool delete;
}

class ChecklistItemEditorScreen extends StatefulWidget {
  const ChecklistItemEditorScreen({
    required this.tripStartDate,
    this.item,
    super.key,
  });

  final DateTime tripStartDate;
  final TripChecklistItem? item;

  @override
  State<ChecklistItemEditorScreen> createState() =>
      _ChecklistItemEditorScreenState();
}

class _ChecklistItemEditorScreenState extends State<ChecklistItemEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  late TripChecklistCategory _category;
  late TripChecklistPriority _priority;
  DateTime? _dueDate;
  late bool _isCompleted;

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _titleController = TextEditingController(text: item?.title ?? '');
    _notesController = TextEditingController(text: item?.notes ?? '');
    _category = item?.category ?? TripChecklistCategory.other;
    _priority = item?.priority ?? TripChecklistPriority.medium;
    _dueDate =
        item?.dueDate ?? widget.tripStartDate.subtract(const Duration(days: 3));
    _isCompleted = item?.isCompleted ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final initialDate = _dueDate ?? widget.tripStartDate;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null || !mounted) {
      return;
    }
    setState(() => _dueDate = pickedDate);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final oldItem = widget.item;
    final item = TripChecklistItem(
      id: oldItem?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      category: _category,
      priority: _priority,
      createdAt: oldItem?.createdAt ?? DateTime.now(),
      notes: _notesController.text.trim(),
      dueDate: _dueDate,
      isCompleted: _isCompleted,
      sourceKey: oldItem?.sourceKey,
    );
    Navigator.of(context).pop(ChecklistItemEditorResult.save(item));
  }

  Future<void> _delete() async {
    final item = widget.item;
    if (item == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Aufgabe löschen?'),
          content: Text('${item.title} wird aus der Checkliste entfernt.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Löschen'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) {
      return;
    }
    Navigator.of(context).pop(ChecklistItemEditorResult.delete(item));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Aufgabe bearbeiten' : 'Neue Aufgabe'),
        actions: [
          if (_isEditing)
            IconButton(
              tooltip: 'Löschen',
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Aufgabe',
                  prefixIcon: Icon(Icons.checklist_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Bitte eine Aufgabe eingeben.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<TripChecklistCategory>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Kategorie',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: TripChecklistCategory.values
                    .map((category) {
                      return DropdownMenuItem<TripChecklistCategory>(
                        value: category,
                        child: Text(category.label),
                      );
                    })
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _category = value);
                  }
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<TripChecklistPriority>(
                initialValue: _priority,
                decoration: const InputDecoration(
                  labelText: 'Priorität',
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
                items: TripChecklistPriority.values
                    .map((priority) {
                      return DropdownMenuItem<TripChecklistPriority>(
                        value: priority,
                        child: Text(priority.label),
                      );
                    })
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _priority = value);
                  }
                },
              ),
              const SizedBox(height: 14),
              Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: const Icon(Icons.event_outlined),
                  title: const Text('Fälligkeitsdatum'),
                  subtitle: Text(
                    _dueDate == null ? 'Kein Datum' : _formatDate(_dueDate!),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_dueDate != null)
                        IconButton(
                          tooltip: 'Datum entfernen',
                          onPressed: () => setState(() => _dueDate = null),
                          icon: const Icon(Icons.clear_rounded),
                        ),
                      IconButton(
                        tooltip: 'Datum auswählen',
                        onPressed: _pickDueDate,
                        icon: const Icon(Icons.edit_calendar_outlined),
                      ),
                    ],
                  ),
                  onTap: _pickDueDate,
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _notesController,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  alignLabelWithHint: true,
                  labelText: 'Notiz optional',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                value: _isCompleted,
                onChanged: (value) => setState(() => _isCompleted = value),
                title: const Text('Als erledigt markieren'),
                secondary: Icon(
                  _isCompleted
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Speichern'),
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
