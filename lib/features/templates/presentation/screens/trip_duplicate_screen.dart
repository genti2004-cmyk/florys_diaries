import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/core/widgets/premium_date_picker.dart';
import 'package:florys_diaries/features/templates/application/trip_clone_service.dart';
import 'package:florys_diaries/features/trips/application/trip_store_scope.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

class TripDuplicateScreen extends StatefulWidget {
  const TripDuplicateScreen({required this.sourceTrip, super.key});

  final Trip sourceTrip;

  @override
  State<TripDuplicateScreen> createState() => _TripDuplicateScreenState();
}

class _TripDuplicateScreenState extends State<TripDuplicateScreen> {
  late final TextEditingController _titleController;
  late DateTime _startDate;
  bool _includePlan = true;
  bool _includeChecklist = true;
  bool _includeBudget = true;
  bool _includeParticipants = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: '${widget.sourceTrip.title} – Kopie',
    );
    final today = DateTime.now();
    _startDate = DateTime(today.year, today.month, today.day);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final selected = await showPremiumDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
      title: 'Neuer Reisebeginn',
      subtitle: 'Alle übernommenen Termine werden relativ verschoben.',
    );
    if (!mounted || selected == null) {
      return;
    }
    setState(() => _startDate = selected);
  }

  Future<void> _save() async {
    if (_isSaving || _titleController.text.trim().isEmpty) {
      return;
    }
    setState(() => _isSaving = true);
    final store = TripStoreScope.of(context);
    final trip = TripCloneService.clone(
      source: widget.sourceTrip,
      newId: store.createId(),
      title: _titleController.text,
      startDate: _startDate,
      options: TripCloneOptions(
        includePlan: _includePlan,
        includeChecklist: _includeChecklist,
        includeBudget: _includeBudget,
        includeParticipants: _includeParticipants,
      ),
    );
    try {
      await store.addTrip(trip);
      if (mounted) {
        Navigator.of(context).pop(trip);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Die Reise konnte nicht dupliziert werden.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final endDate = _startDate.add(
      Duration(days: widget.sourceTrip.durationDays - 1),
    );
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Reise duplizieren')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Titel der neuen Reise',
                      prefixIcon: Icon(Icons.copy_all_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.calendar_month_outlined,
                      color: AppColors.primary,
                    ),
                    title: const Text('Neuer Zeitraum'),
                    subtitle: Text(
                      '${_formatDate(_startDate)} – ${_formatDate(endDate)}',
                    ),
                    trailing: const Icon(Icons.edit_calendar_outlined),
                    onTap: _pickStartDate,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Übernehmen',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Tagesplan'),
                  subtitle: Text('${widget.sourceTrip.planItemCount} Programmpunkte'),
                  value: _includePlan,
                  onChanged: (value) => setState(() => _includePlan = value),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Checkliste'),
                  subtitle: Text('${widget.sourceTrip.checklistItems.length} Aufgaben'),
                  value: _includeChecklist,
                  onChanged: (value) =>
                      setState(() => _includeChecklist = value),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Budgetstruktur'),
                  subtitle: const Text('Budget, Währung und geplante Ausgaben'),
                  value: _includeBudget,
                  onChanged: (value) => setState(() => _includeBudget = value),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Reiseteilnehmer'),
                  subtitle: Text('${widget.sourceTrip.participants.length} Personen'),
                  value: _includeParticipants,
                  onChanged: (value) =>
                      setState(() => _includeParticipants = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(15),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.privacy_tip_outlined, color: AppColors.primary),
                  SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      'Dokumente, Fotos, Momente und bereits bezahlte Ausgaben werden nicht kopiert.',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: FilledButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.copy_all_rounded),
            label: const Text('Neue Reise erstellen'),
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
