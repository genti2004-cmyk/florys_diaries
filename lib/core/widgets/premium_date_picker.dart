import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';

Future<DateTime?> showPremiumDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  DateTime? lastDate,
  String title = 'Datum auswählen',
  String subtitle = 'Wähle das passende Datum im Kalender.',
}) {
  final safeFirstDate = DateUtils.dateOnly(firstDate);
  final safeLastDate = DateUtils.dateOnly(
    lastDate ?? DateTime(2100, 12, 31),
  );
  final safeInitialDate = _clampDate(
    DateUtils.dateOnly(initialDate),
    safeFirstDate,
    safeLastDate,
  );

  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.46),
    builder: (sheetContext) {
      return _PremiumDatePickerSheet(
        initialDate: safeInitialDate,
        firstDate: safeFirstDate,
        lastDate: safeLastDate,
        title: title,
        subtitle: subtitle,
      );
    },
  );
}

DateTime _clampDate(DateTime value, DateTime firstDate, DateTime lastDate) {
  if (value.isBefore(firstDate)) {
    return firstDate;
  }
  if (value.isAfter(lastDate)) {
    return lastDate;
  }
  return value;
}

class _PremiumDatePickerSheet extends StatefulWidget {
  const _PremiumDatePickerSheet({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.title,
    required this.subtitle,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final String title;
  final String subtitle;

  @override
  State<_PremiumDatePickerSheet> createState() =>
      _PremiumDatePickerSheetState();
}

class _PremiumDatePickerSheetState extends State<_PremiumDatePickerSheet> {
  late DateTime _selectedDate;
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _visibleMonth = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: FractionallySizedBox(
            heightFactor: 0.92,
            child: Material(
              color: AppColors.background,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: Alignment.center,
                            child: Container(
                              width: 42,
                              height: 5,
                              margin: const EdgeInsets.only(bottom: 14),
                              decoration: BoxDecoration(
                                color: AppColors.border,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                          _SelectedDateHero(
                            title: widget.title,
                            subtitle: widget.subtitle,
                            selectedDate: _selectedDate,
                          ),
                          const SizedBox(height: 14),
                          _QuickDateRow(
                            firstDate: widget.firstDate,
                            lastDate: widget.lastDate,
                            selectedDate: _selectedDate,
                            onSelected: _selectDate,
                          ),
                          const SizedBox(height: 14),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                              child: Column(
                                children: [
                                  _MonthHeader(
                                    visibleMonth: _visibleMonth,
                                    canGoPrevious: _canGoPrevious,
                                    canGoNext: _canGoNext,
                                    onPrevious: _showPreviousMonth,
                                    onNext: _showNextMonth,
                                  ),
                                  const SizedBox(height: 12),
                                  const _WeekdayHeader(),
                                  const SizedBox(height: 6),
                                  _MonthGrid(
                                    visibleMonth: _visibleMonth,
                                    selectedDate: _selectedDate,
                                    firstDate: widget.firstDate,
                                    lastDate: widget.lastDate,
                                    onSelected: _selectDate,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _BottomActions(
                    selectedDate: _selectedDate,
                    onCancel: () => Navigator.of(context).pop(),
                    onConfirm: () => Navigator.of(context).pop(_selectedDate),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool get _canGoPrevious {
    final previous = DateTime(_visibleMonth.year, _visibleMonth.month - 1);
    final firstMonth = DateTime(widget.firstDate.year, widget.firstDate.month);
    return !previous.isBefore(firstMonth);
  }

  bool get _canGoNext {
    final next = DateTime(_visibleMonth.year, _visibleMonth.month + 1);
    final lastMonth = DateTime(widget.lastDate.year, widget.lastDate.month);
    return !next.isAfter(lastMonth);
  }

  void _showPreviousMonth() {
    if (!_canGoPrevious) {
      return;
    }
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1);
    });
  }

  void _showNextMonth() {
    if (!_canGoNext) {
      return;
    }
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1);
    });
  }

  void _selectDate(DateTime date) {
    final safeDate = _clampDate(date, widget.firstDate, widget.lastDate);
    setState(() {
      _selectedDate = safeDate;
      _visibleMonth = DateTime(safeDate.year, safeDate.month);
    });
  }
}

class _SelectedDateHero extends StatelessWidget {
  const _SelectedDateHero({
    required this.title,
    required this.subtitle,
    required this.selectedDate,
  });

  final String title;
  final String subtitle;
  final DateTime selectedDate;

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
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F173A70),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 62,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.17),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${selectedDate.day}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  _shortMonthName(selectedDate.month),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${_weekdayName(selectedDate.weekday)}, '
                  '${selectedDate.day}. ${_monthName(selectedDate.month)} '
                  '${selectedDate.year}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
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

class _QuickDateRow extends StatelessWidget {
  const _QuickDateRow({
    required this.firstDate,
    required this.lastDate,
    required this.selectedDate,
    required this.onSelected,
  });

  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    final options = <_QuickDateOption>[
      _QuickDateOption(label: 'Heute', date: today),
      _QuickDateOption(label: 'Morgen', date: today.add(const Duration(days: 1))),
      _QuickDateOption(
        label: '+1 Woche',
        date: today.add(const Duration(days: 7)),
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < options.length; index++) ...[
            if (index > 0) const SizedBox(width: 8),
            _QuickDateChip(
              option: options[index],
              enabled: !_isOutsideRange(options[index].date),
              selected: DateUtils.isSameDay(
                selectedDate,
                options[index].date,
              ),
              onSelected: onSelected,
            ),
          ],
        ],
      ),
    );
  }

  bool _isOutsideRange(DateTime date) {
    return date.isBefore(firstDate) || date.isAfter(lastDate);
  }
}

class _QuickDateChip extends StatelessWidget {
  const _QuickDateChip({
    required this.option,
    required this.enabled,
    required this.selected,
    required this.onSelected,
  });

  final _QuickDateOption option;
  final bool enabled;
  final bool selected;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(option.label),
      selected: selected,
      onSelected: enabled ? (_) => onSelected(option.date) : null,
      avatar: Icon(
        option.label == 'Heute'
            ? Icons.today_rounded
            : option.label == 'Morgen'
            ? Icons.wb_sunny_outlined
            : Icons.fast_forward_rounded,
        size: 17,
      ),
      showCheckmark: false,
      selectedColor: AppColors.primarySoft,
      disabledColor: AppColors.surfaceSoft,
      side: BorderSide(
        color: selected ? AppColors.primary : AppColors.border,
      ),
      labelStyle: TextStyle(
        color: enabled
            ? selected
                  ? AppColors.primary
                  : AppColors.text
            : AppColors.textMuted.withValues(alpha: 0.55),
        fontWeight: FontWeight.w800,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.visibleMonth,
    required this.canGoPrevious,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime visibleMonth;
  final bool canGoPrevious;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MonthNavigationButton(
          tooltip: 'Vorheriger Monat',
          icon: Icons.chevron_left_rounded,
          enabled: canGoPrevious,
          onPressed: onPrevious,
        ),
        Expanded(
          child: Text(
            '${_monthName(visibleMonth.month)} ${visibleMonth.year}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        _MonthNavigationButton(
          tooltip: 'Nächster Monat',
          icon: Icons.chevron_right_rounded,
          enabled: canGoNext,
          onPressed: onNext,
        ),
      ],
    );
  }
}

class _MonthNavigationButton extends StatelessWidget {
  const _MonthNavigationButton({
    required this.tooltip,
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      tooltip: tooltip,
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader();

  @override
  Widget build(BuildContext context) {
    const labels = <String>['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

    return Row(
      children: [
        for (var index = 0; index < labels.length; index++)
          Expanded(
            child: Text(
              labels[index],
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: index >= 5 ? AppColors.sand : AppColors.textMuted,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.visibleMonth,
    required this.selectedDate,
    required this.firstDate,
    required this.lastDate,
    required this.onSelected,
  });

  final DateTime visibleMonth;
  final DateTime selectedDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(visibleMonth.year, visibleMonth.month);
    final leadingEmptyCells = firstOfMonth.weekday - DateTime.monday;
    final daysInMonth = DateUtils.getDaysInMonth(
      visibleMonth.year,
      visibleMonth.month,
    );
    final today = DateUtils.dateOnly(DateTime.now());

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 42,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 5,
        crossAxisSpacing: 5,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        final day = index - leadingEmptyCells + 1;
        if (day < 1 || day > daysInMonth) {
          return const SizedBox.shrink();
        }

        final date = DateTime(visibleMonth.year, visibleMonth.month, day);
        final enabled = !date.isBefore(firstDate) && !date.isAfter(lastDate);
        final selected = DateUtils.isSameDay(date, selectedDate);
        final isToday = DateUtils.isSameDay(date, today);
        final isWeekend = date.weekday >= DateTime.saturday;

        return _CalendarDayButton(
          date: date,
          enabled: enabled,
          selected: selected,
          isToday: isToday,
          isWeekend: isWeekend,
          onTap: () => onSelected(date),
        );
      },
    );
  }
}

class _CalendarDayButton extends StatelessWidget {
  const _CalendarDayButton({
    required this.date,
    required this.enabled,
    required this.selected,
    required this.isToday,
    required this.isWeekend,
    required this.onTap,
  });

  final DateTime date;
  final bool enabled;
  final bool selected;
  final bool isToday;
  final bool isWeekend;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = !enabled
        ? AppColors.textMuted.withValues(alpha: 0.34)
        : selected
        ? Colors.white
        : isWeekend
        ? const Color(0xFFB7793F)
        : AppColors.text;

    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label:
          '${date.day}. ${_monthName(date.month)} ${date.year}',
      child: Material(
        color: selected ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: isToday && !selected
                  ? Border.all(color: AppColors.primary, width: 1.5)
                  : null,
            ),
            child: Text(
              '${date.day}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: textColor,
                fontWeight: selected || isToday
                    ? FontWeight.w900
                    : FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.selectedDate,
    required this.onCancel,
    required this.onConfirm,
  });

  final DateTime selectedDate;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  child: const Text('Abbrechen'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: onConfirm,
                  icon: const Icon(Icons.check_rounded),
                  label: Text(
                    '${selectedDate.day.toString().padLeft(2, '0')}.'
                    '${selectedDate.month.toString().padLeft(2, '0')}.'
                    '${selectedDate.year} übernehmen',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickDateOption {
  const _QuickDateOption({required this.label, required this.date});

  final String label;
  final DateTime date;
}

String _monthName(int month) {
  const months = <String>[
    'Januar',
    'Februar',
    'März',
    'April',
    'Mai',
    'Juni',
    'Juli',
    'August',
    'September',
    'Oktober',
    'November',
    'Dezember',
  ];
  return months[month - 1];
}

String _shortMonthName(int month) {
  const months = <String>[
    'JAN',
    'FEB',
    'MÄR',
    'APR',
    'MAI',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OKT',
    'NOV',
    'DEZ',
  ];
  return months[month - 1];
}

String _weekdayName(int weekday) {
  const weekdays = <String>[
    'Montag',
    'Dienstag',
    'Mittwoch',
    'Donnerstag',
    'Freitag',
    'Samstag',
    'Sonntag',
  ];
  return weekdays[weekday - 1];
}
