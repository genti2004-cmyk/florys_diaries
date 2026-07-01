import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/features/report/data/travel_report_service.dart';
import 'package:florys_diaries/features/report/domain/travel_report_options.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

class TravelReportScreen extends StatefulWidget {
  const TravelReportScreen({
    required this.trip,
    this.service = const TravelReportService(),
    super.key,
  });

  final Trip trip;
  final TravelReportService service;

  @override
  State<TravelReportScreen> createState() => _TravelReportScreenState();
}

class _TravelReportScreenState extends State<TravelReportScreen> {
  TravelReportOptions _options = const TravelReportOptions();
  bool _isCreating = false;
  File? _lastFile;

  Future<File?> _create() async {
    if (_isCreating) {
      return null;
    }
    setState(() => _isCreating = true);
    try {
      final file = await widget.service.createPdf(
        widget.trip,
        options: _options,
      );
      if (!mounted) {
        return file;
      }
      setState(() => _lastFile = file);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reisebericht wurde erstellt.')),
      );
      return file;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Der Reisebericht konnte nicht erstellt werden.'),
          ),
        );
      }
      debugPrint('Reisebericht fehlgeschlagen: $error');
      return null;
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  Future<void> _open() async {
    final file = _lastFile ?? await _create();
    if (file == null) {
      return;
    }
    await OpenFilex.open(file.path);
  }

  Future<void> _share() async {
    final file = _lastFile ?? await _create();
    if (file == null || !mounted) {
      return;
    }
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'Reisebericht: ${widget.trip.title}',
        text: 'Reisebericht aus FlorysDiaries',
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  void _setOptions(TravelReportOptions value) {
    setState(() {
      _options = value;
      _lastFile = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Reisebericht & PDF')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.picture_as_pdf_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.trip.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.trip.destination}, ${widget.trip.country}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Erstelle ein offline verfügbares PDF. Originaldokumente werden aus Datenschutzgründen nicht automatisch eingebettet.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Umfang',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                _OptionSwitch(
                  title: 'Ausführliche Version',
                  subtitle: 'Notizen und Details vollständig übernehmen',
                  value: _options.detailed,
                  onChanged: (value) =>
                      _setOptions(_options.copyWith(detailed: value)),
                ),
                const Divider(height: 1),
                _OptionSwitch(
                  title: 'Tagesplan',
                  value: _options.includePlan,
                  onChanged: (value) =>
                      _setOptions(_options.copyWith(includePlan: value)),
                ),
                const Divider(height: 1),
                _OptionSwitch(
                  title: 'Budget und Ausgaben',
                  value: _options.includeBudget,
                  onChanged: (value) =>
                      _setOptions(_options.copyWith(includeBudget: value)),
                ),
                const Divider(height: 1),
                _OptionSwitch(
                  title: 'Checkliste',
                  value: _options.includeChecklist,
                  onChanged: (value) =>
                      _setOptions(_options.copyWith(includeChecklist: value)),
                ),
                const Divider(height: 1),
                _OptionSwitch(
                  title: 'Dokumentenliste',
                  subtitle: 'Nur Titel und Kategorien, keine Originaldateien',
                  value: _options.includeDocuments,
                  onChanged: (value) =>
                      _setOptions(_options.copyWith(includeDocuments: value)),
                ),
                const Divider(height: 1),
                _OptionSwitch(
                  title: 'Momente',
                  value: _options.includeMoments,
                  onChanged: (value) =>
                      _setOptions(_options.copyWith(includeMoments: value)),
                ),
                const Divider(height: 1),
                _OptionSwitch(
                  title: 'Reisefotos',
                  subtitle: 'Bis zu vier vorhandene JPG- oder PNG-Fotos',
                  value: _options.includePhotos,
                  onChanged: (value) =>
                      _setOptions(_options.copyWith(includePhotos: value)),
                ),
                const Divider(height: 1),
                _OptionSwitch(
                  title: 'Reiseteilnehmer',
                  value: _options.includeParticipants,
                  onChanged: (value) => _setOptions(
                    _options.copyWith(includeParticipants: value),
                  ),
                ),
              ],
            ),
          ),
          if (_lastFile != null) ...[
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                ),
                title: const Text('PDF ist bereit'),
                subtitle: Text(_lastFile!.path.split(Platform.pathSeparator).last),
                trailing: IconButton(
                  tooltip: 'PDF öffnen',
                  onPressed: _open,
                  icon: const Icon(Icons.open_in_new_rounded),
                ),
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isCreating ? null : _open,
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Erstellen & öffnen'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isCreating ? null : _share,
                  icon: _isCreating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.share_outlined),
                  label: const Text('Teilen'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionSwitch extends StatelessWidget {
  const _OptionSwitch({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      value: value,
      onChanged: onChanged,
    );
  }
}
