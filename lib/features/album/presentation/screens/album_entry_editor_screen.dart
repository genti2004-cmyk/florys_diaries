import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/core/widgets/unsaved_changes_guard.dart';
import 'package:florys_diaries/features/album/domain/trip_album_entry.dart';

class AlbumEntryEditorResult {
  const AlbumEntryEditorResult.save(this.entry) : delete = false;
  const AlbumEntryEditorResult.delete(this.entry) : delete = true;

  final TripAlbumEntry entry;
  final bool delete;
}

class AlbumEntryEditorScreen extends StatefulWidget {
  const AlbumEntryEditorScreen({
    required this.tripStartDate,
    this.entry,
    super.key,
  });

  final DateTime tripStartDate;
  final TripAlbumEntry? entry;

  @override
  State<AlbumEntryEditorScreen> createState() => _AlbumEntryEditorScreenState();
}

class _AlbumEntryEditorScreenState extends State<AlbumEntryEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _locationController;
  late final TextEditingController _descriptionController;
  late DateTime _date;
  late String _typeId;
  late bool _isFavorite;

  bool _hasUnsavedChanges = false;
  bool _isSaving = false;

  bool get _isEditing => widget.entry != null;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _titleController = TextEditingController(text: entry?.title ?? '');
    _locationController = TextEditingController(text: entry?.location ?? '');
    _descriptionController = TextEditingController(
      text: entry?.description ?? '',
    );
    _date = entry?.date ?? widget.tripStartDate;
    _typeId = entry?.typeId ?? TripAlbumEntryTypes.note.id;
    _isFavorite = entry?.isFavorite ?? false;

    _titleController.addListener(_markTextChanged);
    _locationController.addListener(_markTextChanged);
    _descriptionController.addListener(_markTextChanged);
  }

  @override
  void dispose() {
    _titleController
      ..removeListener(_markTextChanged)
      ..dispose();
    _locationController
      ..removeListener(_markTextChanged)
      ..dispose();
    _descriptionController
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

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null || !mounted || pickedDate == _date) {
      return;
    }
    setState(() {
      _date = pickedDate;
      _hasUnsavedChanges = true;
    });
  }

  void _save() {
    FocusManager.instance.primaryFocus?.unfocus();

    if (_isSaving || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    final oldEntry = widget.entry;
    final entry = oldEntry == null
        ? TripAlbumEntry(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            typeId: _typeId,
            date: _date,
            title: _titleController.text.trim(),
            location: _locationController.text.trim(),
            description: _descriptionController.text.trim(),
            isFavorite: _isFavorite,
          )
        : oldEntry.copyWith(
            typeId: _typeId,
            date: _date,
            title: _titleController.text.trim(),
            location: _locationController.text.trim(),
            description: _descriptionController.text.trim(),
            isFavorite: _isFavorite,
          );

    final result = AlbumEntryEditorResult.save(entry);
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
    final entry = widget.entry;
    if (entry == null || _isSaving) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Album-Eintrag löschen?'),
          content: Text('${entry.title} wird aus dem Reisealbum entfernt.'),
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

    final result = AlbumEntryEditorResult.delete(entry);
    setState(() => _hasUnsavedChanges = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pop(result);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return UnsavedChangesGuard<AlbumEntryEditorResult>(
      hasUnsavedChanges: _hasUnsavedChanges && !_isSaving,
      title: 'Album-Änderungen verwerfen?',
      message:
          'Die Änderungen an diesem Album-Eintrag wurden noch nicht gespeichert.',
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _isEditing ? 'Album-Eintrag bearbeiten' : 'Album-Eintrag',
          ),
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
              key: const PageStorageKey<String>('album-entry-editor-form'),
              padding: const EdgeInsets.all(16),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                DropdownButtonFormField<String>(
                  key: const ValueKey<String>('album-editor-type'),
                  initialValue: _typeId,
                  decoration: const InputDecoration(
                    labelText: 'Art des Eintrags',
                    prefixIcon: Icon(Icons.auto_stories_outlined),
                  ),
                  items: TripAlbumEntryTypes.values
                      .map((type) {
                        return DropdownMenuItem<String>(
                          value: type.id,
                          child: Text(type.label),
                        );
                      })
                      .toList(growable: false),
                  onChanged: _isSaving
                      ? null
                      : (value) {
                          if (value == null || value == _typeId) {
                            return;
                          }
                          setState(() {
                            _typeId = value;
                            _hasUnsavedChanges = true;
                          });
                        },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  key: const ValueKey<String>('album-editor-title'),
                  controller: _titleController,
                  enabled: !_isSaving,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Titel',
                    prefixIcon: Icon(Icons.title_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Bitte Titel eingeben.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  key: const ValueKey<String>('album-editor-location'),
                  controller: _locationController,
                  enabled: !_isSaving,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Ort optional',
                    prefixIcon: Icon(Icons.place_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    key: const ValueKey<String>('album-editor-date'),
                    enabled: !_isSaving,
                    leading: const Icon(Icons.calendar_today_outlined),
                    title: const Text('Datum'),
                    subtitle: Text(_formatDate(_date)),
                    trailing: const Icon(Icons.edit_calendar_outlined),
                    onTap: _isSaving ? null : _pickDate,
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  key: const ValueKey<String>('album-editor-description'),
                  controller: _descriptionController,
                  enabled: !_isSaving,
                  minLines: 4,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    alignLabelWithHint: true,
                    labelText: 'Beschreibung / Erinnerung',
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile.adaptive(
                  key: const ValueKey<String>('album-editor-favorite'),
                  value: _isFavorite,
                  onChanged: _isSaving
                      ? null
                      : (value) {
                          if (value == _isFavorite) {
                            return;
                          }
                          setState(() {
                            _isFavorite = value;
                            _hasUnsavedChanges = true;
                          });
                        },
                  title: const Text('Als Lieblingsmoment markieren'),
                  subtitle: const Text(
                    'Wird im Reisealbum besonders hervorgehoben.',
                  ),
                  secondary: Icon(
                    _isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  key: const ValueKey<String>('album-editor-save'),
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
