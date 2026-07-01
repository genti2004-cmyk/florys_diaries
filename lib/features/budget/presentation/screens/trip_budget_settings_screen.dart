import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/core/widgets/unsaved_changes_guard.dart';
import 'package:florys_diaries/features/budget/domain/trip_budget_expense.dart';

class TripBudgetSettingsResult {
  const TripBudgetSettingsResult({
    required this.amountCents,
    required this.currency,
  });

  final int amountCents;
  final String currency;
}

class TripBudgetSettingsScreen extends StatefulWidget {
  const TripBudgetSettingsScreen({
    required this.amountCents,
    required this.currency,
    super.key,
  });

  final int amountCents;
  final String currency;

  @override
  State<TripBudgetSettingsScreen> createState() =>
      _TripBudgetSettingsScreenState();
}

class _TripBudgetSettingsScreenState
    extends State<TripBudgetSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late String _currency;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _currency = TripMoney.normalizeCurrency(widget.currency);
    _amountController = TextEditingController(
      text: widget.amountCents <= 0
          ? ''
          : (widget.amountCents / 100).toStringAsFixed(2).replaceAll('.', ','),
    );
    _amountController.addListener(_markChanged);
  }

  @override
  void dispose() {
    _amountController
      ..removeListener(_markChanged)
      ..dispose();
    super.dispose();
  }

  void _markChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final amount = TripMoney.parseToCents(_amountController.text)!;
    setState(() => _hasUnsavedChanges = false);
    Navigator.of(context).pop(
      TripBudgetSettingsResult(amountCents: amount, currency: _currency),
    );
  }

  @override
  Widget build(BuildContext context) {
    return UnsavedChangesGuard<TripBudgetSettingsResult>(
      hasUnsavedChanges: _hasUnsavedChanges,
      title: 'Budgetänderungen verwerfen?',
      message: 'Das Reisebudget wurde noch nicht gespeichert.',
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Reisebudget festlegen')),
        body: SafeArea(
          bottom: false,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                Container(
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
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Volle Kostenkontrolle',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Lege ein Gesamtbudget fest. Geplante und bezahlte Ausgaben werden gemeinsam berücksichtigt.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.84),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gesamtbudget',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Du kannst den Betrag später jederzeit anpassen.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          key: const ValueKey<String>('budget-settings-amount'),
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            labelText: 'Budgetbetrag',
                            hintText: 'z. B. 1500,00',
                            prefixIcon: Icon(Icons.payments_outlined),
                          ),
                          validator: (value) {
                            if (TripMoney.parseToCents(value ?? '') == null) {
                              return 'Bitte einen gültigen Betrag eingeben.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          key: const ValueKey<String>(
                            'budget-settings-currency',
                          ),
                          initialValue: _currency,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Währung',
                            prefixIcon: Icon(Icons.currency_exchange_rounded),
                          ),
                          items: TripMoney.supportedCurrencies
                              .map(
                                (currency) => DropdownMenuItem<String>(
                                  value: currency,
                                  child: Text(currency),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (value) {
                            if (value == null || value == _currency) {
                              return;
                            }
                            setState(() {
                              _currency = value;
                              _hasUnsavedChanges = true;
                            });
                          },
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
              key: const ValueKey<String>('budget-settings-save'),
              onPressed: _save,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Budget speichern'),
            ),
          ),
        ),
      ),
    );
  }
}
