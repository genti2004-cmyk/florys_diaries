import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
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
  const DocumentEditorScreen({
    required this.tripId,
    this.document,
    super.key,
  });

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
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.any,
      withData: false,
    );

    final pickedFile = result?.files.single;
    final path = pickedFile?.path;
    if (path == null || path.trim().isEmpty) {
      return;
    }

    setState(() {
      _selectedFilePath = path;
      _selectedFileName = pickedFile?.name ?? _fileNameFromPath(path);
      if (_titleController.text.trim().isEmpty) {
        _titleController.text = _titleFromFileName(_selectedFileName);
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _isSaving) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final oldDocument = widget.document;
      final documentId = oldDocument?.id ?? _createId();
      var document = TravelDocument(
        id: documentId,
        title: _titleController.text.trim(),
        categoryId: _categoryId,
        createdAt: oldDocument?.createdAt ?? DateTime.now(),
        description: _descriptionController.text.trim(),
        fileName: oldDocument?.fileName ?? '',
        relativePath: oldDocument?.relativePath ?? '',
        fileSizeBytes: oldDocument?.fileSizeBytes ?? 0,
        fileExtension: oldDocument?.fileExtension ?? '',
      );

      if (_selectedFilePath.trim().isNotEmpty) {
        final copiedFile = await _fileService.copyFileToTrip(
          tripId: widget.tripId,
          sourcePath: _selectedFilePath,
          documentId: documentId,
        );

        if (oldDocument != null && oldDocument.relativePath.trim().isNotEmpty) {
          await _fileService.deleteDocumentFile(oldDocument);
        }

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
      Navigator.of(context).pop(DocumentEditorResult.save(document));
    } on FileSystemException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Die Datei konnte nicht gespeichert werden.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
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
    Navigator.of(context).pop(DocumentEditorResult.delete(document));
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedFileText = _selectedFileName.trim().isEmpty
        ? 'Noch keine Datei ausgewählt'
        : _selectedFileName;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Dokument bearbeiten' : 'Dokument anlegen'),
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
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<String>(
                initialValue: _categoryId,
                decoration: const InputDecoration(
                  labelText: 'Kategorie',
                  prefixIcon: Icon(Icons.folder_outlined),
                ),
                items: DocumentCategories.values.map((category) {
                  return DropdownMenuItem<String>(
                    value: category.id,
                    child: Row(
                      children: [
                        Icon(category.icon, size: 20, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Text(category.label),
                      ],
                    ),
                  );
                }).toList(growable: false),
                onChanged: _isSaving
                    ? null
                    : (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() => _categoryId = value);
                      },
              ),
              const SizedBox(height: 12),
              TextFormField(
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
              const SizedBox(height: 12),
              _FilePickerCard(
                fileName: selectedFileText,
                hasFile: _selectedFileName.trim().isNotEmpty,
                isBusy: _isSaving,
                onPickFile: _pickFile,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                enabled: !_isSaving,
                minLines: 4,
                maxLines: 7,
                decoration: const InputDecoration(
                  labelText: 'Beschreibung / Notiz',
                  hintText: 'Buchungsnummer, Strecke, Check-in, Details ...',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(
                  _isEditing ? 'Änderungen speichern' : 'Dokument speichern',
                ),
              ),
            ],
          ),
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
