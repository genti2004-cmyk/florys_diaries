import 'package:florys_diaries/features/budget/domain/trip_budget_expense.dart';
import 'package:florys_diaries/features/checklist/domain/trip_checklist_item.dart';
import 'package:florys_diaries/features/participants/domain/trip_participant.dart';
import 'package:florys_diaries/features/planner/domain/trip_plan_item.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

class TripCloneOptions {
  const TripCloneOptions({
    this.includePlan = true,
    this.includeChecklist = true,
    this.includeBudget = true,
    this.includeParticipants = true,
  });

  final bool includePlan;
  final bool includeChecklist;
  final bool includeBudget;
  final bool includeParticipants;
}

class TripCloneService {
  const TripCloneService._();

  static Trip clone({
    required Trip source,
    required String newId,
    required String title,
    required DateTime startDate,
    TripCloneOptions options = const TripCloneOptions(),
  }) {
    final normalizedStart = _dateOnly(startDate);
    final sourceStart = _dateOnly(source.startDate);
    final shift = normalizedStart.difference(sourceStart);
    final newEnd = normalizedStart.add(
      Duration(days: source.durationDays - 1),
    );

    final participantIdMap = <String, String>{};
    final participants = options.includeParticipants
        ? source.participants.map((participant) {
            final newParticipant = TripParticipant(
              id: _newId(),
              name: participant.name,
            );
            participantIdMap[participant.id] = newParticipant.id;
            return newParticipant;
          }).toList(growable: false)
        : const <TripParticipant>[];

    final planItems = options.includePlan
        ? source.planItems.map((item) {
            return TripPlanItem(
              id: _newId(),
              title: item.title,
              date: item.dateOnly.add(shift),
              startMinutes: item.startMinutes,
              endMinutes: item.endMinutes,
              type: item.type,
              location: item.location,
              notes: item.notes,
              linkedDocumentId: null,
              reminderMinutesBefore: item.reminderMinutesBefore,
            );
          }).toList(growable: false)
        : const <TripPlanItem>[];

    final checklistItems = options.includeChecklist
        ? source.checklistItems.map((item) {
            return TripChecklistItem(
              id: _newId(),
              title: item.title,
              category: item.category,
              priority: item.priority,
              createdAt: DateTime.now(),
              notes: item.notes,
              dueDate: item.dueDate?.add(shift),
              sourceKey: item.sourceKey,
            );
          }).toList(growable: false)
        : const <TripChecklistItem>[];

    final expenses = options.includeBudget
        ? source.budgetExpenses
            .where((expense) => expense.status == TripExpenseStatus.planned)
            .map(
              (expense) => TripBudgetExpense(
                id: _newId(),
                title: expense.title,
                date: expense.dateOnly.add(shift),
                amountCents: expense.amountCents,
                category: expense.category,
                status: TripExpenseStatus.planned,
                notes: expense.notes,
                paidByParticipantId:
                    participantIdMap[expense.paidByParticipantId],
                participantIds: expense.participantIds
                    .map((id) => participantIdMap[id])
                    .whereType<String>()
                    .toList(growable: false),
              ),
            )
            .toList(growable: false)
        : const <TripBudgetExpense>[];

    return Trip(
      id: newId,
      title: title.trim().isEmpty ? '${source.title} – Kopie' : title.trim(),
      destination: source.destination,
      country: source.country,
      startDate: normalizedStart,
      endDate: newEnd,
      notes: source.notes,
      checklistItems: checklistItems,
      planItems: planItems,
      budgetAmountCents: options.includeBudget
          ? source.budgetAmountCents
          : 0,
      budgetCurrency: source.budgetCurrency,
      budgetExpenses: expenses,
      participants: participants,
    );
  }

  static String _newId() =>
      '${DateTime.now().microsecondsSinceEpoch}${_counter++}';

  static int _counter = 0;

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
