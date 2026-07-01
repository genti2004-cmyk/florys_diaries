import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/core/widgets/unsaved_changes_guard.dart';
import 'package:florys_diaries/features/documents/domain/travel_document.dart';
import 'package:florys_diaries/features/planner/domain/trip_plan_item.dart';
import 'package:florys_diaries/features/reminders/data/trip_reminder_notification_service.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

class PlanItemEditorResult {
  const PlanItemEditorResult._({required this.item, required this.delete});

  const PlanItemEditorResult.save(TripPlanItem item)
    : this._(item: item, delete: false);

  const PlanItemEditorResult.delete(TripPlanItem item)
    : this._(item: item, delete: true);

  final TripPlanItem item;
  final bool delete;
}

class PlanItemEditorScreen extends StatefulWidget {
  const PlanItemEditorScreen({
    required this.trip,
    this.item,
    this.initialDate,
    super.key,
  });

  final Trip trip;
  final TripPlanItem? item;
  final DateTime? initialDate;

  @override
  State<PlanItemEditorScreen> createState() => _PlanItemEditorScreenState();
}

class _PlanItemEditorScreenState extends State<PlanItemEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _locationController;
  late final TextEditingController _notesController;

  late DateTime _date;
  late TimeOfDay _startTime;
  TimeOfDay? _endTime;
  late TripPlanItemType _type;
  late bool _isCompleted;
  String _linkedDocumentId = '';
  int? _reminderMinutesBefore;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _titleController = TextEditingController(text: item?.title ?? '');
    _locationController = TextEditingController(text: item?.location ?? '');
    _notesController = TextEditingController(text: item?.notes ?? '');
    _date = _clampDate(item?.date ?? widget.initialDate ?? widget.trip.startDate);
    _startTime = _timeFromMinutes(item?.startMinutes ?? 9 * 60);
    _endTime = item?.endMinutes == null
        ? null
        : _timeFromMinutes(item!.endMinutes!);
    _type = item?.type ?? TripPlanItemType.activity;
    _isCompleted = item?.isCompleted ?? false;
    _linkedDocumentId = item?.linkedDocumentId ?? '';
    _reminderMinutesBefore = item?.reminderMinutesBefore;

    _titleController.addListener(_markChanged);
    _locationController.addListener(_markChanged);
    _notesController.addListener(_markChanged);
  }

  @override
  void dispose() {
    _titleController
      ..removeListener(_markChanged)
      ..dispose();
    _locationController
      ..removeListener(_markChanged)
      ..dispose();
    _notesController
      ..removeListener(_markChanged)
      ..dispose();
    super.dispose();
  }

  void _markChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: _dateOnly(widget.trip.startDate),
      lastDate: _dateOnly(widget.trip.endDate),
      helpText: 'Reisetag auswählen',
      cancelText: 'Abbrechen',
      confirmText: 'Übernehmen',
    );
    if (!mounted || selected == null || _sameDate(selected, _date)) {
      return;
    }
    setState(() {
      _date = selected;
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _pickStartTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _startTime,
      helpText: 'Startzeit auswählen',
      cancelText: 'Abbrechen',
      confirmText: 'Übernehmen',
    );
    if (!mounted || selected == null || selected == _startTime) {
      return;
    }
    setState(() {
      _startTime = selected;
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _pickEndTime() async {
    final initial = _endTime ??
        TimeOfDay(
          hour: (_startTime.hour + 1) % 24,
          minute: _startTime.minute,
        );
    final selected = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: 'Endzeit auswählen',
      cancelText: 'Abbrechen',
      confirmText: 'Übernehmen',
    );
    if (!mounted || selected == null || selected == _endTime) {
      return;
    }
    setState(() {
      _endTime = selected;
      _hasUnsavedChanges = true;
    });
  }

  void _clearEndTime() {
    if (_endTime == null) {
      return;
    }
    setState(() {
      _endTime = null;
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _save() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_isSaving || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    if (_reminderMinutesBefore != null) {
      final permission = await TripReminderNotificationService.instance
          .requestPermissions();
      if (!mounted) {
        return;
      }
      if (!permission.canNotify) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Bitte Benachrichtigungen erlauben, damit die Erinnerung funktioniert.',
            ),
          ),
        );
        return;
      }
    }
    final oldItem = widget.item;
    final item = oldItem == null
        ? TripPlanItem(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            title: _titleController.text.trim(),
            date: _date,
            startMinutes: _minutesFromTime(_startTime),
            endMinutes: _endTime == null ? null : _minutesFromTime(_endTime!),
            type: _type,
            location: _locationController.text.trim(),
            notes: _notesController.text.trim(),
            isCompleted: _isCompleted,
            linkedDocumentId: _linkedDocumentId.isEmpty
                ? null
                : _linkedDocumentId,
            reminderMinutesBefore: _reminderMinutesBefore,
          )
        : oldItem.copyWith(
            title: _titleController.text.trim(),
            date: _date,
            startMinutes: _minutesFromTime(_startTime),
            endMinutes: _endTime == null ? null : _minutesFromTime(_endTime!),
            clearEndMinutes: _endTime == null,
            type: _type,
            location: _locationController.text.trim(),
            notes: _notesController.text.trim(),
            isCompleted: _isCompleted,
            linkedDocumentId: _linkedDocumentId.isEmpty
                ? null
                : _linkedDocumentId,
            clearLinkedDocument: _linkedDocumentId.isEmpty,
            reminderMinutesBefore: _reminderMinutesBefore,
            clearReminder: _reminderMinutesBefore == null,
          );

    setState(() {
      _isSaving = false;
      _hasUnsavedChanges = false;
    });
    Navigator.of(context).pop(PlanItemEditorResult.save(item));
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
          title: const Text('Programmpunkt löschen?'),
          content: Text('${item.title} wird aus dem Tagesplan entfernt.'),
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
    setState(() => _hasUnsavedChanges = false);
    Navigator.of(context).pop(PlanItemEditorResult.delete(item));
  }

  @override
  Widget build(BuildContext context) {
    final documents = List<TravelDocument>.from(widget.trip.documents)
      ..sort((left, right) => left.title.compareTo(right.title));

    return UnsavedChangesGuard<PlanItemEditorResult>(
      hasUnsavedChanges: _hasUnsavedChanges && !_isSaving,
      title: 'Änderungen am Tagesplan verwerfen?',
      message: 'Dieser Programmpunkt wurde noch nicht gespeichert.',
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Programmpunkt bearbeiten' : 'Neuer Programmpunkt'),
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
          bottom: false,
          child: Form(
            key: _formKey,
            child: ListView(
              key: const PageStorageKey<String>('plan-item-editor-form'),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                TextFormField(
                  key: const ValueKey<String>('plan-editor-title'),
                  controller: _titleController,
                  enabled: !_isSaving,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Titel',
                    prefixIcon: Icon(Icons.edit_calendar_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Bitte einen Titel eingeben.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<TripPlanItemType>(
                  key: const ValueKey<String>('plan-editor-type'),
                  initialValue: _type,
                  decoration: const InputDecoration(
                    labelText: 'Art',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: TripPlanItemType.values
                      .map(
                        (type) => DropdownMenuItem<TripPlanItemType>(
                          value: type,
                          child: Row(
                            children: [
                              Icon(type.icon, size: 19),
                              const SizedBox(width: 10),
                              Text(type.label),
                            ],
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: _isSaving
                      ? null
                      : (value) {
                          if (value == null || value == _type) {
                            return;
                          }
                          setState(() {
                            _type = value;
                            _hasUnsavedChanges = true;
                          });
                        },
                ),
                const SizedBox(height: 14),
                _EditorTile(
                  key: const ValueKey<String>('plan-editor-date'),
                  icon: Icons.calendar_today_outlined,
                  title: 'Reisetag',
                  value: _formatDate(_date),
                  onTap: _isSaving ? null : _pickDate,
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final narrow = constraints.maxWidth < 360;
                    final start = _EditorTile(
                      key: const ValueKey<String>('plan-editor-start-time'),
                      icon: Icons.schedule_rounded,
                      title: 'Start',
                      value: _formatTime(_startTime),
                      onTap: _isSaving ? null : _pickStartTime,
                    );
                    final end = _EditorTile(
                      key: const ValueKey<String>('plan-editor-end-time'),
                      icon: Icons.more_time_rounded,
                      title: 'Ende optional',
                      value: _endTime == null ? 'Keine Endzeit' : _formatTime(_endTime!),
                      onTap: _isSaving ? null : _pickEndTime,
                      trailing: _endTime == null
                          ? null
                          : IconButton(
                              tooltip: 'Endzeit entfernen',
                              onPressed: _isSaving ? null : _clearEndTime,
                              icon: const Icon(Icons.clear_rounded),
                            ),
                    );
                    if (narrow) {
                      return Column(
                        children: [start, const SizedBox(height: 14), end],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: start),
                        const SizedBox(width: 12),
                        Expanded(child: end),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  key: const ValueKey<String>('plan-editor-location'),
                  controller: _locationController,
                  enabled: !_isSaving,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Ort optional',
                    prefixIcon: Icon(Icons.place_outlined),
                  ),
                ),
                if (documents.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    key: const ValueKey<String>('plan-editor-document'),
                    initialValue: documents.any((item) => item.id == _linkedDocumentId)
                        ? _linkedDocumentId
                        : '',
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Dokument verknüpfen optional',
                      prefixIcon: Icon(Icons.attach_file_rounded),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: '',
                        child: Text('Kein Dokument'),
                      ),
                      ...documents.map(
                        (document) => DropdownMenuItem<String>(
                          value: document.id,
                          child: Text(
                            document.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: _isSaving
                        ? null
                        : (value) {
                            final next = value ?? '';
                            if (next == _linkedDocumentId) {
                              return;
                            }
                            setState(() {
                              _linkedDocumentId = next;
                              _hasUnsavedChanges = true;
                            });
                          },
                  ),
                ],
                const SizedBox(height: 14),
                TextFormField(
                  key: const ValueKey<String>('plan-editor-notes'),
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
                const SizedBox(height: 14),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(6, 4, 6, 12),
                    child: Column(
                      children: [
                        SwitchListTile.adaptive(
                          key: const ValueKey<String>('plan-editor-reminder'),
                          value: _reminderMinutesBefore != null,
                          onChanged: _isSaving
                              ? null
                              : (value) {
                                  setState(() {
                                    _reminderMinutesBefore = value ? 60 : null;
                                    _hasUnsavedChanges = true;
                                  });
                                },
                          title: const Text('Erinnerung aktivieren'),
                          subtitle: const Text(
                            'Benachrichtigung vor diesem Programmpunkt.',
                          ),
                          secondary: Icon(
                            _reminderMinutesBefore == null
                                ? Icons.notifications_none_rounded
                                : Icons.notifications_active_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                        if (_reminderMinutesBefore != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: DropdownButtonFormField<int>(
                              key: const ValueKey<String>(
                                'plan-editor-reminder-lead',
                              ),
                              initialValue: _reminderMinutesBefore,
                              decoration: const InputDecoration(
                                labelText: 'Vorwarnzeit',
                                prefixIcon: Icon(Icons.schedule_rounded),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 15,
                                  child: Text('15 Minuten vorher'),
                                ),
                                DropdownMenuItem(
                                  value: 30,
                                  child: Text('30 Minuten vorher'),
                                ),
                                DropdownMenuItem(
                                  value: 60,
                                  child: Text('1 Stunde vorher'),
                                ),
                                DropdownMenuItem(
                                  value: 1440,
                                  child: Text('1 Tag vorher'),
                                ),
                              ],
                              onChanged: _isSaving
                                  ? null
                                  : (value) {
                                      if (value == null ||
                                          value == _reminderMinutesBefore) {
                                        return;
                                      }
                                      setState(() {
                                        _reminderMinutesBefore = value;
                                        _hasUnsavedChanges = true;
                                      });
                                    },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile.adaptive(
                  key: const ValueKey<String>('plan-editor-completed'),
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
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _PlanItemSaveBar(
          isSaving: _isSaving,
          isEditing: _isEditing,
          onSave: _save,
        ),
      ),
    );
  }

  DateTime _clampDate(DateTime date) {
    final normalized = _dateOnly(date);
    final first = _dateOnly(widget.trip.startDate);
    final last = _dateOnly(widget.trip.endDate);
    if (normalized.isBefore(first)) {
      return first;
    }
    if (normalized.isAfter(last)) {
      return last;
    }
    return normalized;
  }

  static TimeOfDay _timeFromMinutes(int minutes) {
    final safe = minutes.clamp(0, 1439).toInt();
    return TimeOfDay(hour: safe ~/ 60, minute: safe % 60);
  }

  static int _minutesFromTime(TimeOfDay time) => time.hour * 60 + time.minute;

  static DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  static bool _sameDate(DateTime left, DateTime right) {
    return left.year == right.year && left.month == right.month && left.day == right.day;
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }

  static String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _PlanItemSaveBar extends StatelessWidget {
  const _PlanItemSaveBar({
    required this.isSaving,
    required this.isEditing,
    required this.onSave,
  });

  final bool isSaving;
  final bool isEditing;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shadowColor: AppColors.shadow,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: FilledButton.icon(
          key: const ValueKey<String>('plan-editor-save'),
          onPressed: isSaving ? null : onSave,
          icon: isSaving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check_rounded),
          label: Text(
            isEditing ? 'Änderungen speichern' : 'Programmpunkt speichern',
          ),
        ),
      ),
    );
  }
}

class _EditorTile extends StatelessWidget {
  const _EditorTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
    this.trailing,
    super.key,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        enabled: onTap != null,
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        subtitle: Text(value),
        trailing: trailing ?? const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
