import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/core/widgets/unsaved_changes_guard.dart';
import 'package:florys_diaries/features/documents/data/travel_file_service.dart';
import 'package:florys_diaries/features/documents/domain/document_category.dart';
import 'package:florys_diaries/features/documents/domain/travel_document.dart';

class DocumentEditorResult {
  const DocumentEditorResult.save(this.document) : delete = false;
  const DocumentEditorResult.delete(this.document) : delete = true;

  final TravelDocument document;
  final bool delete;
}

class DocumentEditorScreen extends StatefulWidget {
  const DocumentEditorScreen({required this.tripId, this.document, super.key});

  final String tripId;
  final TravelDocument? document;

  @override
  State<DocumentEditorScreen> createState() => _DocumentEditorScreenState();
}

class _DocumentEditorScreenState extends State<DocumentEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fileService = const TravelFileService();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late String _categoryId;

  String _selectedFilePath = '';
  String _selectedFileName = '';
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;

  bool get _isEditing => widget.document != null;

  @override
  void initState() {
    super.initState();
    final document = widget.document;
    _titleController = TextEditingController(text: document?.title ?? '');
    _descriptionController = TextEditingController(
      text: document?.description ?? '',
    );
    _selectedFileName = document?.fileName ?? '';
    _categoryId = document?.categoryId ?? DocumentCategories.flight.id;

    _titleController.addListener(_markTextChanged);
    _descriptionController.addListener(_markTextChanged);
  }

  @override
  void dispose() {
    _titleController
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

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.any,
      withData: false,
    );

    final pickedFile = result?.files.single;
    final path = pickedFile?.path;
    if (path == null || path.trim().isEmpty || !mounted) {
      return;
    }

    setState(() {
      _selectedFilePath = path;
      _selectedFileName = pickedFile?.name ?? _fileNameFromPath(path);
      _hasUnsavedChanges = true;
      if (_titleController.text.trim().isEmpty) {
        _titleController.text = _titleFromFileName(_selectedFileName);
      }
    });
  }

  Future<void> _save() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (_isSaving || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final oldDocument = widget.document;
      final documentId = oldDocument?.id ?? _createId();
      var document = oldDocument == null
          ? TravelDocument(
              id: documentId,
              title: _titleController.text.trim(),
              categoryId: _categoryId,
              createdAt: DateTime.now(),
              description: _descriptionController.text.trim(),
            )
          : oldDocument.copyWith(
              title: _titleController.text.trim(),
              categoryId: _categoryId,
              description: _descriptionController.text.trim(),
            );

      if (_selectedFilePath.trim().isNotEmpty) {
        final copiedFile = await _fileService.copyFileToTrip(
          tripId: widget.tripId,
          sourcePath: _selectedFilePath,
          documentId: documentId,
        );

        document = document.copyWith(
          fileName: copiedFile.fileName,
          relativePath: copiedFile.relativePath,
          fileSizeBytes: copiedFile.fileSizeBytes,
          fileExtension: copiedFile.fileExtension,
        );
      }

      if (!mounted) {
        return;
      }

      final result = DocumentEditorResult.save(document);
      setState(() {
        _isSaving = false;
        _hasUnsavedChanges = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pop(result);
        }
      });
    } on FileSystemException catch (error) {
      _handleSaveError(
        error.message.trim().isEmpty
            ? 'Die Datei konnte nicht gespeichert werden.'
            : error.message,
      );
    } catch (error) {
      debugPrint('Dokument konnte nicht gespeichert werden: $error');
      _handleSaveError('Die Datei konnte nicht gespeichert werden.');
    }
  }

  Future<void> _delete() async {
    final document = widget.document;
    if (document == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Dokument löschen?'),
          content: Text('${document.title} wird aus dieser Reise entfernt.'),
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

    final result = DocumentEditorResult.delete(document);
    setState(() => _hasUnsavedChanges = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pop(result);
      }
    });
  }

  void _handleSaveError(String message) {
    if (!mounted) {
      return;
    }
    setState(() => _isSaving = false);
    _showError(message);
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final selectedFileText = _selectedFileName.trim().isEmpty
        ? 'Noch keine Datei ausgewählt'
        : _selectedFileName;

    return UnsavedChangesGuard<DocumentEditorResult>(
      hasUnsavedChanges: _hasUnsavedChanges && !_isSaving,
      title: 'Dokumentänderungen verwerfen?',
      message:
          'Die Änderungen an diesem Dokument wurden noch nicht gespeichert.',
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Dokument bearbeiten' : 'Dokument hinzufügen'),
          actions: [
            if (_isEditing)
              IconButton(
                tooltip: 'Löschen',
                onPressed: _isSaving ? null : _delete,
                icon: const Icon(Icons.delete_outline),
              ),
          ],
        ),
        body: SafeArea(
          bottom: false,
          child: Form(
            key: _formKey,
            child: ListView(
              key: const PageStorageKey<String>('document-editor-form-v63'),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                _DocumentEditorIntroCard(isEditing: _isEditing),
                const SizedBox(height: 16),
                _DocumentEditorSection(
                  icon: Icons.description_outlined,
                  title: 'Dokumentdetails',
                  subtitle: 'Kategorie und Titel helfen dir beim schnellen Wiederfinden.',
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        key: const ValueKey<String>('document-editor-category'),
                        initialValue: _categoryId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Kategorie',
                          prefixIcon: Icon(Icons.folder_outlined),
                        ),
                        items: DocumentCategories.values
                            .map((category) {
                              return DropdownMenuItem<String>(
                                value: category.id,
                                child: Row(
                                  children: [
                                    Icon(
                                      category.icon,
                                      size: 20,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(category.label),
                                  ],
                                ),
                              );
                            })
                            .toList(growable: false),
                        onChanged: _isSaving
                            ? null
                            : (value) {
                                if (value == null || value == _categoryId) {
                                  return;
                                }
                                setState(() {
                                  _categoryId = value;
                                  _hasUnsavedChanges = true;
                                });
                              },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: const ValueKey<String>('document-editor-title'),
                        controller: _titleController,
                        enabled: !_isSaving,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Titel',
                          hintText: 'z. B. Flugticket Lufthansa',
                          prefixIcon: Icon(Icons.title_rounded),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Bitte Titel eintragen';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _DocumentEditorSection(
                  icon: Icons.attach_file_rounded,
                  title: 'Datei',
                  subtitle: 'Wähle ein Ticket, PDF, Bild oder eine andere Reisedatei.',
                  child: _FilePickerCard(
                    fileName: selectedFileText,
                    hasFile: _selectedFileName.trim().isNotEmpty,
                    isBusy: _isSaving,
                    onPickFile: _pickFile,
                  ),
                ),
                const SizedBox(height: 14),
                _DocumentEditorSection(
                  icon: Icons.notes_outlined,
                  title: 'Notiz',
                  subtitle: 'Optional: Buchungsnummer, Strecke oder wichtige Hinweise.',
                  optional: true,
                  child: TextFormField(
                    key: const ValueKey<String>('document-editor-description'),
                    controller: _descriptionController,
                    enabled: !_isSaving,
                    minLines: 3,
                    maxLines: 6,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Was möchtest du zu dieser Datei festhalten?',
                      prefixIcon: Icon(Icons.edit_note_rounded),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _DocumentSaveBar(
          isEditing: _isEditing,
          isSaving: _isSaving,
          onSave: _save,
        ),
      ),
    );
  }

  static String _createId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }

  static String _fileNameFromPath(String path) {
    final parts = path.split(RegExp(r'[\\/]+'));
    return parts.isEmpty ? 'Datei' : parts.last;
  }

  static String _titleFromFileName(String fileName) {
    final withoutExtension = fileName.replaceFirst(RegExp(r'\.[^.]+$'), '');
    final title = withoutExtension.replaceAll(RegExp(r'[_-]+'), ' ').trim();
    return title.isEmpty ? fileName : title;
  }
}

class _DocumentEditorIntroCard extends StatelessWidget {
  const _DocumentEditorIntroCard({required this.isEditing});

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
            child: const Icon(Icons.folder_copy_outlined, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Datei aktualisieren' : 'Datei sicher ablegen',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  isEditing
                      ? 'Passe Kategorie, Titel, Datei oder Notiz an.'
                      : 'Gib der Datei einen klaren Titel und ordne sie einer Kategorie zu.',
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

class _DocumentEditorSection extends StatelessWidget {
  const _DocumentEditorSection({
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

class _DocumentSaveBar extends StatelessWidget {
  const _DocumentSaveBar({
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
            key: const ValueKey<String>('document-editor-save'),
            onPressed: isSaving ? null : onSave,
            icon: isSaving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded),
            label: Text(
              isEditing ? 'Änderungen speichern' : 'Dokument speichern',
            ),
          ),
        ),
      ),
    );
  }
}

class _FilePickerCard extends StatelessWidget {
  const _FilePickerCard({
    required this.fileName,
    required this.hasFile,
    required this.isBusy,
    required this.onPickFile,
  });

  final String fileName;
  final bool hasFile;
  final bool isBusy;
  final VoidCallback onPickFile;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                hasFile ? Icons.attach_file_rounded : Icons.upload_file_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasFile ? 'Ausgewählte Datei' : 'Datei anhängen',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.text,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton(
              onPressed: isBusy ? null : onPickFile,
              child: Text(hasFile ? 'Ändern' : 'Wählen'),
            ),
          ],
        ),
      ),
    );
  }
}
