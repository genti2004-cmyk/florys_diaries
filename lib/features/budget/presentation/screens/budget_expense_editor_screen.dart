import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/core/widgets/premium_date_picker.dart';
import 'package:florys_diaries/core/widgets/unsaved_changes_guard.dart';
import 'package:florys_diaries/features/budget/domain/trip_budget_expense.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

class BudgetExpenseEditorResult {
  const BudgetExpenseEditorResult._({
    required this.expense,
    required this.delete,
  });

  const BudgetExpenseEditorResult.save(TripBudgetExpense expense)
    : this._(expense: expense, delete: false);

  const BudgetExpenseEditorResult.delete(TripBudgetExpense expense)
    : this._(expense: expense, delete: true);

  final TripBudgetExpense expense;
  final bool delete;
}

class BudgetExpenseEditorScreen extends StatefulWidget {
  const BudgetExpenseEditorScreen({
    required this.trip,
    this.expense,
    this.initialDate,
    super.key,
  });

  final Trip trip;
  final TripBudgetExpense? expense;
  final DateTime? initialDate;

  @override
  State<BudgetExpenseEditorScreen> createState() =>
      _BudgetExpenseEditorScreenState();
}

class _BudgetExpenseEditorScreenState
    extends State<BudgetExpenseEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;
  late DateTime _date;
  late TripExpenseCategory _category;
  late TripExpenseStatus _status;
  bool _hasUnsavedChanges = false;
  bool _isSaving = false;

  bool get _isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    _titleController = TextEditingController(text: expense?.title ?? '');
    _amountController = TextEditingController(
      text: expense == null
          ? ''
          : (expense.amountCents / 100)
                .toStringAsFixed(2)
                .replaceAll('.', ','),
    );
    _notesController = TextEditingController(text: expense?.notes ?? '');
    _date = _clampDate(
      expense?.date ?? widget.initialDate ?? widget.trip.startDate,
    );
    _category = expense?.category ?? TripExpenseCategory.other;
    _status = expense?.status ?? TripExpenseStatus.planned;

    _titleController.addListener(_markChanged);
    _amountController.addListener(_markChanged);
    _notesController.addListener(_markChanged);
  }

  @override
  void dispose() {
    _titleController
      ..removeListener(_markChanged)
      ..dispose();
    _amountController
      ..removeListener(_markChanged)
      ..dispose();
    _notesController
      ..removeListener(_markChanged)
      ..dispose();
    super.dispose();
  }

  void _markChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  Future<void> _pickDate() async {
    final selected = await showPremiumDatePicker(
      context: context,
      initialDate: _date,
      firstDate: _dateOnly(widget.trip.startDate),
      lastDate: _dateOnly(widget.trip.endDate),
      title: 'Reisetag',
      subtitle: 'Ordne die Ausgabe einem Tag dieser Reise zu.',
    );
    if (!mounted || selected == null || _sameDate(selected, _date)) {
      return;
    }
    setState(() {
      _date = selected;
      _hasUnsavedChanges = true;
    });
  }

  void _save() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_isSaving || !_formKey.currentState!.validate()) {
      return;
    }

    final amount = TripMoney.parseToCents(_amountController.text)!;
    setState(() => _isSaving = true);
    final oldExpense = widget.expense;
    final expense = oldExpense == null
        ? TripBudgetExpense(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            title: _titleController.text.trim(),
            date: _date,
            amountCents: amount,
            category: _category,
            status: _status,
            notes: _notesController.text.trim(),
          )
        : oldExpense.copyWith(
            title: _titleController.text.trim(),
            date: _date,
            amountCents: amount,
            category: _category,
            status: _status,
            notes: _notesController.text.trim(),
          );

    setState(() {
      _isSaving = false;
      _hasUnsavedChanges = false;
    });
    Navigator.of(context).pop(BudgetExpenseEditorResult.save(expense));
  }

  Future<void> _delete() async {
    final expense = widget.expense;
    if (expense == null || _isSaving) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Ausgabe löschen?'),
          content: Text('${expense.title} wird aus dem Reisebudget entfernt.'),
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
    setState(() => _hasUnsavedChanges = false);
    Navigator.of(context).pop(BudgetExpenseEditorResult.delete(expense));
  }

  @override
  Widget build(BuildContext context) {
    return UnsavedChangesGuard<BudgetExpenseEditorResult>(
      hasUnsavedChanges: _hasUnsavedChanges && !_isSaving,
      title: 'Ausgabenänderungen verwerfen?',
      message: 'Diese Ausgabe wurde noch nicht gespeichert.',
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(_isEditing ? 'Ausgabe bearbeiten' : 'Neue Ausgabe'),
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
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextFormField(
                          key: const ValueKey<String>('expense-editor-title'),
                          controller: _titleController,
                          enabled: !_isSaving,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Bezeichnung',
                            hintText: 'z. B. Hotel, Zugticket oder Abendessen',
                            prefixIcon: Icon(Icons.receipt_long_rounded),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Bitte eine Bezeichnung eingeben.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          key: const ValueKey<String>('expense-editor-amount'),
                          controller: _amountController,
                          enabled: !_isSaving,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            labelText: 'Betrag in ${widget.trip.budgetCurrency}',
                            hintText: 'z. B. 89,90',
                            prefixIcon: const Icon(Icons.payments_outlined),
                          ),
                          validator: (value) {
                            if (TripMoney.parseToCents(value ?? '') == null) {
                              return 'Bitte einen gültigen Betrag eingeben.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<TripExpenseCategory>(
                          key: const ValueKey<String>(
                            'expense-editor-category',
                          ),
                          initialValue: _category,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Kategorie',
                            prefixIcon: Icon(Icons.category_outlined),
                          ),
                          items: TripExpenseCategory.values
                              .map(
                                (category) =>
                                    DropdownMenuItem<TripExpenseCategory>(
                                      value: category,
                                      child: Row(
                                        children: [
                                          Icon(category.icon, size: 19),
                                          const SizedBox(width: 10),
                                          Text(category.label),
                                        ],
                                      ),
                                    ),
                              )
                              .toList(growable: false),
                          onChanged: _isSaving
                              ? null
                              : (value) {
                                  if (value == null || value == _category) {
                                    return;
                                  }
                                  setState(() {
                                    _category = value;
                                    _hasUnsavedChanges = true;
                                  });
                                },
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<TripExpenseStatus>(
                          key: const ValueKey<String>('expense-editor-status'),
                          initialValue: _status,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                            prefixIcon: Icon(Icons.fact_check_outlined),
                          ),
                          items: TripExpenseStatus.values
                              .map(
                                (status) =>
                                    DropdownMenuItem<TripExpenseStatus>(
                                      value: status,
                                      child: Row(
                                        children: [
                                          Icon(status.icon, size: 19),
                                          const SizedBox(width: 10),
                                          Text(status.label),
                                        ],
                                      ),
                                    ),
                              )
                              .toList(growable: false),
                          onChanged: _isSaving
                              ? null
                              : (value) {
                                  if (value == null || value == _status) {
                                    return;
                                  }
                                  setState(() {
                                    _status = value;
                                    _hasUnsavedChanges = true;
                                  });
                                },
                        ),
                        const SizedBox(height: 14),
                        _DateButton(
                          date: _date,
                          enabled: !_isSaving,
                          onPressed: _pickDate,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          key: const ValueKey<String>('expense-editor-notes'),
                          controller: _notesController,
                          enabled: !_isSaving,
                          minLines: 3,
                          maxLines: 5,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            labelText: 'Notiz optional',
                            prefixIcon: Icon(Icons.notes_rounded),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: FilledButton.icon(
              key: const ValueKey<String>('expense-editor-save'),
              onPressed: _isSaving ? null : _save,
              icon: const Icon(Icons.check_rounded),
              label: Text(_isEditing ? 'Änderungen speichern' : 'Ausgabe speichern'),
            ),
          ),
        ),
      ),
    );
  }

  DateTime _clampDate(DateTime date) {
    final value = _dateOnly(date);
    final start = _dateOnly(widget.trip.startDate);
    final end = _dateOnly(widget.trip.endDate);
    if (value.isBefore(start)) {
      return start;
    }
    if (value.isAfter(end)) {
      return end;
    }
    return value;
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static bool _sameDate(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.date,
    required this.enabled,
    required this.onPressed,
  });

  final DateTime date;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return Material(
      color: AppColors.surfaceSoft,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        key: const ValueKey<String>('expense-editor-date'),
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reisetag',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$day.$month.${date.year}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
