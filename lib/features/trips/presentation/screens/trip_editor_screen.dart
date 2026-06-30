import 'dart:io';

import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/core/widgets/premium_date_picker.dart';
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

  int get _durationDays {
    final days = _endDate.difference(_startDate).inDays + 1;
    return days < 1 ? 1 : days;
  }

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
    if (!mounted) {
      return;
    }
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  Future<void> _pickStartDate() async {
    final picked = await _pickDate(
      initialDate: _startDate,
      firstDate: DateTime(2000),
      title: 'Reisebeginn',
      subtitle: 'Wähle den ersten Tag deiner Reise.',
    );
    if (picked == null || !mounted) {
      return;
    }

    final previousDuration = _endDate.difference(_startDate);
    final latestAllowedDate = DateTime(2100, 12, 31);
    final proposedEndDate = picked.add(previousDuration);
    setState(() {
      _startDate = picked;
      _endDate = proposedEndDate.isAfter(latestAllowedDate)
          ? latestAllowedDate
          : proposedEndDate;
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _pickEndDate() async {
    final picked = await _pickDate(
      initialDate: _endDate,
      firstDate: _startDate,
      title: 'Reiseende',
      subtitle: 'Wähle den letzten Tag deiner Reise.',
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _endDate = picked;
      _hasUnsavedChanges = true;
    });
  }

  Future<DateTime?> _pickDate({
    required DateTime initialDate,
    required DateTime firstDate,
    required String title,
    required String subtitle,
  }) {
    final safeInitialDate = initialDate.isBefore(firstDate)
        ? firstDate
        : initialDate;
    return showPremiumDatePicker(
      context: context,
      initialDate: safeInitialDate,
      firstDate: firstDate,
      lastDate: DateTime(2100, 12, 31),
      title: title,
      subtitle: subtitle,
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
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(_isEditing ? 'Reise bearbeiten' : 'Neue Reise'),
        ),
        body: SafeArea(
          bottom: false,
          child: Form(
            key: _formKey,
            child: ListView(
              key: const PageStorageKey<String>('trip-editor-form'),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                _EditorIntroCard(isEditing: _isEditing),
                const SizedBox(height: 16),
                _EditorSection(
                  icon: Icons.location_on_outlined,
                  title: 'Reiseziel',
                  subtitle: 'Diese Angaben erscheinen später auf deinen Reisekarten.',
                  child: Column(
                    children: [
                      _EditorTextField(
                        fieldKey: const ValueKey<String>('trip-editor-title'),
                        controller: _titleController,
                        enabled: !_isSaving,
                        label: 'Reisetitel',
                        hint: 'z. B. Sommer in Paris',
                        icon: Icons.card_travel_rounded,
                        validationMessage: 'Bitte gib einen Reisetitel ein.',
                      ),
                      const SizedBox(height: 12),
                      _EditorTextField(
                        fieldKey: const ValueKey<String>(
                          'trip-editor-destination',
                        ),
                        controller: _destinationController,
                        enabled: !_isSaving,
                        label: 'Stadt oder Reiseziel',
                        hint: 'z. B. Paris',
                        icon: Icons.place_outlined,
                        validationMessage: 'Bitte gib ein Reiseziel ein.',
                      ),
                      const SizedBox(height: 12),
                      _EditorTextField(
                        fieldKey: const ValueKey<String>('trip-editor-country'),
                        controller: _countryController,
                        enabled: !_isSaving,
                        label: 'Land',
                        hint: 'z. B. Frankreich',
                        icon: Icons.public_outlined,
                        validationMessage: 'Bitte gib ein Land ein.',
                        textInputAction: TextInputAction.done,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _EditorSection(
                  icon: Icons.calendar_month_outlined,
                  title: 'Reisezeitraum',
                  subtitle: 'Tippe auf Start oder Ende, um das Datum zu ändern.',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$_durationDays ${_durationDays == 1 ? 'Tag' : 'Tage'}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final startButton = _DateButton(
                        label: 'Start',
                        value: _formatDate(_startDate),
                        icon: Icons.flight_takeoff_rounded,
                        enabled: !_isSaving,
                        onPressed: _pickStartDate,
                      );
                      final endButton = _DateButton(
                        label: 'Ende',
                        value: _formatDate(_endDate),
                        icon: Icons.flag_outlined,
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
                          const SizedBox(width: 10),
                          Expanded(child: endButton),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                _EditorSection(
                  icon: Icons.notes_outlined,
                  title: 'Notizen',
                  subtitle: 'Optional: Unterkunft, Treffpunkte oder wichtige Hinweise.',
                  optional: true,
                  child: TextFormField(
                    key: const ValueKey<String>('trip-editor-notes'),
                    controller: _notesController,
                    enabled: !_isSaving,
                    minLines: 3,
                    maxLines: 6,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Was möchtest du für diese Reise festhalten?',
                      prefixIcon: Icon(Icons.edit_note_rounded),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const _AfterSaveHint(),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _SaveBar(
          isEditing: _isEditing,
          isSaving: _isSaving,
          onSave: _saveTrip,
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

class _EditorIntroCard extends StatelessWidget {
  const _EditorIntroCard({required this.isEditing});

  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF173A70), Color(0xFF285FD5)],
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            ),
            child: const Icon(Icons.flight_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Reisedaten aktualisieren' : 'Reise in drei Schritten',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  isEditing
                      ? 'Ändere Ziel, Zeitraum oder Notizen. Planung und Dateien bleiben erhalten.'
                      : 'Ziel eintragen, Zeitraum wählen und speichern. Planung, Dokumente und Momente ergänzt du danach.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.84),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorSection extends StatelessWidget {
  const _EditorSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
    this.optional = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    final trailingWidget = trailing;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                          ),
                          if (optional) ...[
                            const SizedBox(width: 7),
                            Text(
                              'optional',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textMuted),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (trailingWidget != null) ...[
                  const SizedBox(width: 10),
                  trailingWidget,
                ],
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
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
    required this.validationMessage,
    this.textInputAction = TextInputAction.next,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final bool enabled;
  final String label;
  final String hint;
  final IconData icon;
  final String validationMessage;
  final TextInputAction textInputAction;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: fieldKey,
      controller: controller,
      enabled: enabled,
      textInputAction: textInputAction,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return validationMessage;
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
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceSoft,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AfterSaveHint extends StatelessWidget {
  const _AfterSaveHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            color: AppColors.primary,
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Nach dem Speichern kannst du Aufgaben, Dokumente und persönliche Momente direkt in der Reise ergänzen.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveBar extends StatelessWidget {
  const _SaveBar({
    required this.isEditing,
    required this.isSaving,
    required this.onSave,
  });

  final bool isEditing;
  final bool isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: FilledButton.icon(
            key: const ValueKey<String>('trip-editor-save'),
            onPressed: isSaving ? null : onSave,
            icon: isSaving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded),
            label: Text(isEditing ? 'Änderungen speichern' : 'Reise erstellen'),
          ),
        ),
      ),
    );
  }
}
