import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
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
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null || !mounted) {
      return;
    }
    setState(() => _date = pickedDate);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final oldEntry = widget.entry;
    final entry = TripAlbumEntry(
      id: oldEntry?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      typeId: _typeId,
      date: _date,
      title: _titleController.text.trim(),
      location: _locationController.text.trim(),
      description: _descriptionController.text.trim(),
      isFavorite: _isFavorite,
    );
    Navigator.of(context).pop(AlbumEntryEditorResult.save(entry));
  }

  Future<void> _delete() async {
    final entry = widget.entry;
    if (entry == null) {
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
    Navigator.of(context).pop(AlbumEntryEditorResult.delete(entry));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Album-Eintrag bearbeiten' : 'Album-Eintrag'),
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
              DropdownButtonFormField<String>(
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
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() => _typeId = value);
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _titleController,
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
                controller: _locationController,
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
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: const Text('Datum'),
                  subtitle: Text(_formatDate(_date)),
                  trailing: const Icon(Icons.edit_calendar_outlined),
                  onTap: _pickDate,
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descriptionController,
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
                value: _isFavorite,
                onChanged: (value) => setState(() => _isFavorite = value),
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
