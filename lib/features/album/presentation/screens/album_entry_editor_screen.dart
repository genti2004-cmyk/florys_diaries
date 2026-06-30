import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/core/widgets/premium_date_picker.dart';
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
    final pickedDate = await showPremiumDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100, 12, 31),
      title: 'Datum des Moments',
      subtitle: 'Wann ist diese Erinnerung entstanden?',
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
          title: const Text('Moment löschen?'),
          content: Text('${entry.title} wird aus den Momenten dieser Reise entfernt.'),
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
      title: 'Momentänderungen verwerfen?',
      message: 'Die Änderungen an diesem Moment wurden noch nicht gespeichert.',
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Moment bearbeiten' : 'Moment hinzufügen'),
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
              key: const PageStorageKey<String>('moment-editor-form-v63'),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                _MomentEditorIntroCard(isEditing: _isEditing),
                const SizedBox(height: 16),
                _MomentEditorSection(
                  icon: Icons.auto_stories_outlined,
                  title: 'Moment',
                  subtitle: 'Wähle die Art des Eintrags und gib ihm einen kurzen Titel.',
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        key: const ValueKey<String>('album-editor-type'),
                        initialValue: _typeId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Art des Moments',
                          prefixIcon: Icon(Icons.category_outlined),
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
                      const SizedBox(height: 12),
                      TextFormField(
                        key: const ValueKey<String>('album-editor-title'),
                        controller: _titleController,
                        enabled: !_isSaving,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Titel',
                          hintText: 'z. B. Sonnenuntergang am Hafen',
                          prefixIcon: Icon(Icons.title_rounded),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Bitte Titel eingeben.';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _MomentEditorSection(
                  icon: Icons.place_outlined,
                  title: 'Ort und Datum',
                  subtitle: 'Ordne den Moment zeitlich und geografisch ein.',
                  child: Column(
                    children: [
                      TextFormField(
                        key: const ValueKey<String>('album-editor-location'),
                        controller: _locationController,
                        enabled: !_isSaving,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Ort',
                          hintText: 'Optional',
                          prefixIcon: Icon(Icons.place_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
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
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _MomentEditorSection(
                  icon: Icons.notes_outlined,
                  title: 'Geschichte',
                  subtitle: 'Optional: Was war besonders und woran möchtest du dich erinnern?',
                  optional: true,
                  child: TextFormField(
                    key: const ValueKey<String>('album-editor-description'),
                    controller: _descriptionController,
                    enabled: !_isSaving,
                    minLines: 4,
                    maxLines: 8,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      alignLabelWithHint: true,
                      hintText: 'Beschreibe diesen Moment ...',
                      prefixIcon: Icon(Icons.edit_note_rounded),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Card(
                  child: SwitchListTile.adaptive(
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
                    title: const Text('Lieblingsmoment'),
                    subtitle: const Text(
                      'Favoriten werden in der Momente-Ansicht hervorgehoben.',
                    ),
                    secondary: Icon(
                      _isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _MomentSaveBar(
          isEditing: _isEditing,
          isSaving: _isSaving,
          onSave: _save,
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

class _MomentEditorIntroCard extends StatelessWidget {
  const _MomentEditorIntroCard({required this.isEditing});

  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6A4068), Color(0xFFB36B8B)],
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
            child: const Icon(Icons.favorite_outline_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Moment aktualisieren' : 'Erinnerung festhalten',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  isEditing
                      ? 'Passe Titel, Ort, Datum oder Geschichte an.'
                      : 'Ein kurzer Titel genügt. Ort und Geschichte kannst du optional ergänzen.',
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

class _MomentEditorSection extends StatelessWidget {
  const _MomentEditorSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.optional = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final bool optional;

  @override
  Widget build(BuildContext context) {
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
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceSoft,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'Optional',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(color: AppColors.textMuted),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _MomentSaveBar extends StatelessWidget {
  const _MomentSaveBar({
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
      elevation: 10,
      shadowColor: const Color(0x220D1728),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: FilledButton.icon(
            key: const ValueKey<String>('album-editor-save'),
            onPressed: isSaving ? null : onSave,
            icon: isSaving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded),
            label: Text(isEditing ? 'Änderungen speichern' : 'Moment speichern'),
          ),
        ),
      ),
    );
  }
}
