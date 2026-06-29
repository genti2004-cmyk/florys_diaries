import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/core/widgets/unsaved_changes_guard.dart';
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

  bool _hasUnsavedChanges = false;
  bool _isSaving = false;

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

    _titleController.addListener(_markTextChanged);
    _notesController.addListener(_markTextChanged);
  }

  @override
  void dispose() {
    _titleController
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

  Future<void> _pickDueDate() async {
    final initialDate = _dueDate ?? widget.tripStartDate;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null || !mounted || pickedDate == _dueDate) {
      return;
    }
    setState(() {
      _dueDate = pickedDate;
      _hasUnsavedChanges = true;
    });
  }

  void _clearDueDate() {
    if (_isSaving || _dueDate == null) {
      return;
    }
    setState(() {
      _dueDate = null;
      _hasUnsavedChanges = true;
    });
  }

  void _save() {
    FocusManager.instance.primaryFocus?.unfocus();

    if (_isSaving || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    final oldItem = widget.item;
    final item = oldItem == null
        ? TripChecklistItem(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            title: _titleController.text.trim(),
            category: _category,
            priority: _priority,
            createdAt: DateTime.now(),
            notes: _notesController.text.trim(),
            dueDate: _dueDate,
            isCompleted: _isCompleted,
          )
        : oldItem.copyWith(
            title: _titleController.text.trim(),
            category: _category,
            priority: _priority,
            notes: _notesController.text.trim(),
            dueDate: _dueDate,
            clearDueDate: _dueDate == null,
            isCompleted: _isCompleted,
          );

    final result = ChecklistItemEditorResult.save(item);
    setState(() {
      _isSaving = false;
      _hasUnsavedChanges = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pop(result);
      }
    });
  }

  Future<void> _delete() async {
    final item = widget.item;
    if (item == null || _isSaving) {
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

    final result = ChecklistItemEditorResult.delete(item);
    setState(() => _hasUnsavedChanges = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pop(result);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return UnsavedChangesGuard<ChecklistItemEditorResult>(
      hasUnsavedChanges: _hasUnsavedChanges && !_isSaving,
      title: 'Checklisten-Änderungen verwerfen?',
      message:
          'Die Änderungen an dieser Aufgabe wurden noch nicht gespeichert.',
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Aufgabe bearbeiten' : 'Neue Aufgabe'),
          actions: [
            if (_isEditing)
              IconButton(
                tooltip: 'Löschen',
                onPressed: _isSaving ? null : _delete,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
          ],
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              key: const PageStorageKey<String>('checklist-item-editor-form'),
              padding: const EdgeInsets.all(16),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                TextFormField(
                  key: const ValueKey<String>('checklist-editor-title'),
                  controller: _titleController,
                  enabled: !_isSaving,
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
                  key: const ValueKey<String>('checklist-editor-category'),
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
                  onChanged: _isSaving
                      ? null
                      : (value) {
                          if (value == null || value == _category) {
                            return;
                          }
                          setState(() {
                            _category = value;
                            _hasUnsavedChanges = true;
                          });
                        },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<TripChecklistPriority>(
                  key: const ValueKey<String>('checklist-editor-priority'),
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
                  onChanged: _isSaving
                      ? null
                      : (value) {
                          if (value == null || value == _priority) {
                            return;
                          }
                          setState(() {
                            _priority = value;
                            _hasUnsavedChanges = true;
                          });
                        },
                ),
                const SizedBox(height: 14),
                Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    key: const ValueKey<String>('checklist-editor-due-date'),
                    enabled: !_isSaving,
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
                            onPressed: _isSaving ? null : _clearDueDate,
                            icon: const Icon(Icons.clear_rounded),
                          ),
                        IconButton(
                          tooltip: 'Datum auswählen',
                          onPressed: _isSaving ? null : _pickDueDate,
                          icon: const Icon(Icons.edit_calendar_outlined),
                        ),
                      ],
                    ),
                    onTap: _isSaving ? null : _pickDueDate,
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  key: const ValueKey<String>('checklist-editor-notes'),
                  controller: _notesController,
                  enabled: !_isSaving,
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
                  key: const ValueKey<String>('checklist-editor-completed'),
                  value: _isCompleted,
                  onChanged: _isSaving
                      ? null
                      : (value) {
                          if (value == _isCompleted) {
                            return;
                          }
                          setState(() {
                            _isCompleted = value;
                            _hasUnsavedChanges = true;
                          });
                        },
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
                  key: const ValueKey<String>('checklist-editor-save'),
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded),
                  label: const Text('Speichern'),
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
