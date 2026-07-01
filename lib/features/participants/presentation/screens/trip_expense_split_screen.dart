import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/features/budget/domain/trip_budget_expense.dart';
import 'package:florys_diaries/features/participants/application/trip_settlement_calculator.dart';
import 'package:florys_diaries/features/participants/domain/trip_participant.dart';
import 'package:florys_diaries/features/trips/application/trip_store_scope.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

class TripExpenseSplitScreen extends StatefulWidget {
  const TripExpenseSplitScreen({required this.trip, super.key});

  final Trip trip;

  @override
  State<TripExpenseSplitScreen> createState() =>
      _TripExpenseSplitScreenState();
}

class _TripExpenseSplitScreenState extends State<TripExpenseSplitScreen> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addParticipant(Trip currentTrip) async {
    _nameController.clear();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reiseteilnehmer hinzufügen'),
          content: TextField(
            controller: _nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Name',
              prefixIcon: Icon(Icons.person_add_alt_1_rounded),
            ),
            onSubmitted: (value) =>
                Navigator.of(dialogContext).pop(value.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(
                dialogContext,
              ).pop(_nameController.text.trim()),
              child: const Text('Hinzufügen'),
            ),
          ],
        );
      },
    );
    if (!mounted || name == null || name.trim().isEmpty) {
      return;
    }

    final participant = TripParticipant(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim(),
    );
    final updated = currentTrip.copyWith(
      participants: [...currentTrip.participants, participant],
    );
    await TripStoreScope.of(context).updateTrip(updated);
  }

  Future<void> _renameParticipant(
    Trip currentTrip,
    TripParticipant participant,
  ) async {
    _nameController.text = participant.name;
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Name bearbeiten'),
          content: TextField(
            controller: _nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Name'),
            onSubmitted: (value) =>
                Navigator.of(dialogContext).pop(value.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(
                dialogContext,
              ).pop(_nameController.text.trim()),
              child: const Text('Speichern'),
            ),
          ],
        );
      },
    );
    if (!mounted || name == null || name.trim().isEmpty) {
      return;
    }

    final participants = currentTrip.participants
        .map(
          (item) => item.id == participant.id
              ? item.copyWith(name: name.trim())
              : item,
        )
        .toList(growable: false);
    await TripStoreScope.of(
      context,
    ).updateTrip(currentTrip.copyWith(participants: participants));
  }

  Future<void> _removeParticipant(
    Trip currentTrip,
    TripParticipant participant,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Teilnehmer entfernen?'),
        content: Text(
          '${participant.name} wird aus allen Kostenaufteilungen dieser Reise entfernt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Entfernen'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) {
      return;
    }

    final participants = currentTrip.participants
        .where((item) => item.id != participant.id)
        .toList(growable: false);
    final expenses = currentTrip.budgetExpenses
        .map(
          (expense) => expense.copyWith(
            paidByParticipantId:
                expense.paidByParticipantId == participant.id
                ? null
                : expense.paidByParticipantId,
            participantIds: expense.participantIds
                .where((id) => id != participant.id)
                .toList(growable: false),
          ),
        )
        .toList(growable: false);
    await TripStoreScope.of(context).updateTrip(
      currentTrip.copyWith(
        participants: participants,
        budgetExpenses: expenses,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = TripStoreScope.of(context);
    final trip = store.trips.firstWhere(
      (item) => item.id == widget.trip.id,
      orElse: () => widget.trip,
    );
    final result = TripSettlementCalculator.calculate(
      participants: trip.participants,
      expenses: trip.budgetExpenses,
    );
    final names = {
      for (final participant in trip.participants)
        participant.id: participant.name,
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Reisekasse aufteilen')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.groups_rounded,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Reiseteilnehmer',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Teilnehmer hinzufügen',
                        onPressed: () => _addParticipant(trip),
                        icon: const Icon(Icons.person_add_alt_1_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Lege fest, wer bezahlt hat und für wen eine Ausgabe gilt. FlorysDiaries berechnet den einfachsten Ausgleich.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 14),
                  if (trip.participants.isEmpty)
                    const _EmptyParticipants()
                  else
                    ...trip.participants.map(
                      (participant) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primarySoft,
                          foregroundColor: AppColors.primary,
                          child: Text(
                            participant.name.trim().isEmpty
                                ? '?'
                                : participant.name.trim()[0].toUpperCase(),
                          ),
                        ),
                        title: Text(participant.name),
                        trailing: PopupMenuButton<String>(
                          onSelected: (action) {
                            if (action == 'rename') {
                              _renameParticipant(trip, participant);
                            } else if (action == 'remove') {
                              _removeParticipant(trip, participant);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'rename',
                              child: Text('Umbenennen'),
                            ),
                            PopupMenuItem(
                              value: 'remove',
                              child: Text('Entfernen'),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Zwischenstand',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          if (trip.participants.isEmpty)
            const _InfoCard(
              icon: Icons.info_outline_rounded,
              text: 'Füge zuerst mindestens zwei Teilnehmer hinzu.',
            )
          else
            Card(
              child: Column(
                children: result.balances.map((balance) {
                  final cents = balance.balanceCents;
                  final label = cents > 0
                      ? 'bekommt zurück'
                      : cents < 0
                      ? 'muss zahlen'
                      : 'ausgeglichen';
                  return ListTile(
                    leading: Icon(
                      cents > 0
                          ? Icons.south_west_rounded
                          : cents < 0
                          ? Icons.north_east_rounded
                          : Icons.check_circle_outline_rounded,
                      color: cents > 0
                          ? AppColors.success
                          : cents < 0
                          ? AppColors.warning
                          : AppColors.textMuted,
                    ),
                    title: Text(balance.participant.name),
                    subtitle: Text(label),
                    trailing: Text(
                      TripMoney.format(cents.abs(), trip.budgetCurrency),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  );
                }).toList(growable: false),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            'Empfohlener Ausgleich',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          if (result.transfers.isEmpty)
            const _InfoCard(
              icon: Icons.check_circle_outline_rounded,
              text: 'Aktuell ist kein Ausgleich erforderlich.',
            )
          else
            Card(
              child: Column(
                children: result.transfers.map((transfer) {
                  return ListTile(
                    leading: const Icon(
                      Icons.payments_outlined,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      '${names[transfer.fromParticipantId] ?? 'Teilnehmer'} → ${names[transfer.toParticipantId] ?? 'Teilnehmer'}',
                    ),
                    trailing: Text(
                      TripMoney.format(
                        transfer.amountCents,
                        trip.budgetCurrency,
                      ),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  );
                }).toList(growable: false),
              ),
            ),
          const SizedBox(height: 12),
          const _InfoCard(
            icon: Icons.lock_outline_rounded,
            text: 'Nur bezahlte Ausgaben mit Zahler und ausgewählten Teilnehmern werden in den Ausgleich einbezogen.',
          ),
        ],
      ),
    );
  }
}

class _EmptyParticipants extends StatelessWidget {
  const _EmptyParticipants();

  @override
  Widget build(BuildContext context) {
    return const _InfoCard(
      icon: Icons.person_add_alt_1_rounded,
      text: 'Noch keine Reiseteilnehmer angelegt.',
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 11),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }
}
