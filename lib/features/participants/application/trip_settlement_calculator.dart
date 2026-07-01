import 'package:florys_diaries/features/budget/domain/trip_budget_expense.dart';
import 'package:florys_diaries/features/participants/domain/trip_participant.dart';

class TripParticipantBalance {
  const TripParticipantBalance({
    required this.participant,
    required this.balanceCents,
  });

  final TripParticipant participant;
  final int balanceCents;
}

class TripSettlementTransfer {
  const TripSettlementTransfer({
    required this.fromParticipantId,
    required this.toParticipantId,
    required this.amountCents,
  });

  final String fromParticipantId;
  final String toParticipantId;
  final int amountCents;
}

class TripSettlementResult {
  const TripSettlementResult({
    required this.balances,
    required this.transfers,
  });

  final List<TripParticipantBalance> balances;
  final List<TripSettlementTransfer> transfers;
}

class TripSettlementCalculator {
  const TripSettlementCalculator._();

  static TripSettlementResult calculate({
    required List<TripParticipant> participants,
    required List<TripBudgetExpense> expenses,
  }) {
    final balanceById = <String, int>{
      for (final participant in participants) participant.id: 0,
    };

    for (final expense in expenses) {
      if (!expense.isPaid ||
          expense.paidByParticipantId == null ||
          expense.participantIds.isEmpty ||
          !balanceById.containsKey(expense.paidByParticipantId)) {
        continue;
      }

      final participantIds = expense.participantIds
          .where(balanceById.containsKey)
          .toList(growable: false);
      if (participantIds.isEmpty) {
        continue;
      }

      final baseShare = expense.amountCents ~/ participantIds.length;
      var remainder = expense.amountCents % participantIds.length;
      for (final participantId in participantIds) {
        final share = baseShare + (remainder > 0 ? 1 : 0);
        if (remainder > 0) {
          remainder--;
        }
        balanceById.update(participantId, (value) => value - share);
      }
      balanceById.update(
        expense.paidByParticipantId!,
        (value) => value + expense.amountCents,
      );
    }

    final creditors = balanceById.entries
        .where((entry) => entry.value > 0)
        .map((entry) => MapEntry(entry.key, entry.value))
        .toList(growable: true)
      ..sort((a, b) => b.value.compareTo(a.value));
    final debtors = balanceById.entries
        .where((entry) => entry.value < 0)
        .map((entry) => MapEntry(entry.key, -entry.value))
        .toList(growable: true)
      ..sort((a, b) => b.value.compareTo(a.value));

    final transfers = <TripSettlementTransfer>[];
    var creditorIndex = 0;
    var debtorIndex = 0;
    while (creditorIndex < creditors.length && debtorIndex < debtors.length) {
      final creditor = creditors[creditorIndex];
      final debtor = debtors[debtorIndex];
      final amount = creditor.value < debtor.value
          ? creditor.value
          : debtor.value;
      if (amount > 0) {
        transfers.add(
          TripSettlementTransfer(
            fromParticipantId: debtor.key,
            toParticipantId: creditor.key,
            amountCents: amount,
          ),
        );
      }
      creditors[creditorIndex] = MapEntry(
        creditor.key,
        creditor.value - amount,
      );
      debtors[debtorIndex] = MapEntry(debtor.key, debtor.value - amount);
      if (creditors[creditorIndex].value == 0) {
        creditorIndex++;
      }
      if (debtors[debtorIndex].value == 0) {
        debtorIndex++;
      }
    }

    final balances = participants
        .map(
          (participant) => TripParticipantBalance(
            participant: participant,
            balanceCents: balanceById[participant.id] ?? 0,
          ),
        )
        .toList(growable: false);

    return TripSettlementResult(
      balances: balances,
      transfers: List<TripSettlementTransfer>.unmodifiable(transfers),
    );
  }
}
