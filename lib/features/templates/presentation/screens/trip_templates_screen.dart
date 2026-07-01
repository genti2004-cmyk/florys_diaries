import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/features/templates/data/trip_template_service.dart';
import 'package:florys_diaries/features/templates/domain/trip_template.dart';
import 'package:florys_diaries/features/templates/presentation/screens/trip_duplicate_screen.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

class TripTemplatesScreen extends StatefulWidget {
  const TripTemplatesScreen({
    this.service = const TripTemplateService(),
    super.key,
  });

  final TripTemplateService service;

  @override
  State<TripTemplatesScreen> createState() => _TripTemplatesScreenState();
}

class _TripTemplatesScreenState extends State<TripTemplatesScreen> {
  bool _isLoading = true;
  List<TripTemplate> _templates = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final templates = await widget.service.load();
      if (mounted) {
        setState(() {
          _templates = templates;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _templates = const [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createFromTemplate(TripTemplate template) async {
    await Navigator.of(context).push<Trip>(
      MaterialPageRoute<Trip>(
        builder: (_) => TripDuplicateScreen(sourceTrip: template.sourceTrip),
      ),
    );
  }

  Future<void> _delete(TripTemplate template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Vorlage löschen?'),
        content: Text('${template.name} wird dauerhaft entfernt.'),
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
      ),
    );
    if (!mounted || confirmed != true) {
      return;
    }
    await widget.service.delete(template.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Reisevorlagen')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _templates.isEmpty
          ? const _EmptyTemplates()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              itemCount: _templates.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final template = _templates[index];
                final trip = template.sourceTrip;
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.collections_bookmark_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    title: Text(
                      template.name,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: Text(
                      '${trip.destination}, ${trip.country} · ${trip.durationDays} Tage',
                    ),
                    onTap: () => _createFromTemplate(template),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'use') {
                          _createFromTemplate(template);
                        } else if (value == 'delete') {
                          _delete(template);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'use',
                          child: Text('Neue Reise erstellen'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Vorlage löschen'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _EmptyTemplates extends StatelessWidget {
  const _EmptyTemplates();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.collections_bookmark_outlined,
              size: 58,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 14),
            Text(
              'Noch keine Reisevorlagen',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 7),
            Text(
              'Öffne eine Reise und wähle im Menü „Als Vorlage speichern“.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
