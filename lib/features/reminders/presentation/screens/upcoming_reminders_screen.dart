import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/features/reminders/data/trip_reminder_notification_service.dart';
import 'package:florys_diaries/features/reminders/domain/trip_reminder_entry.dart';
import 'package:florys_diaries/features/trips/application/trip_store_scope.dart';

class UpcomingRemindersScreen extends StatefulWidget {
  const UpcomingRemindersScreen({super.key});

  @override
  State<UpcomingRemindersScreen> createState() =>
      _UpcomingRemindersScreenState();
}

class _UpcomingRemindersScreenState extends State<UpcomingRemindersScreen> {
  ReminderPermissionStatus? _permissionStatus;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _refreshPermission();
  }

  Future<void> _refreshPermission() async {
    final status = await TripReminderNotificationService.instance
        .permissionStatus();
    if (mounted) {
      setState(() => _permissionStatus = status);
    }
  }

  Future<void> _sendTestNotification() async {
    if (_isBusy) {
      return;
    }
    setState(() => _isBusy = true);
    final shown = await TripReminderNotificationService.instance
        .showTestNotification();
    if (!mounted) {
      return;
    }
    await _refreshPermission();
    if (!mounted) {
      return;
    }
    setState(() => _isBusy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          shown
              ? 'Testbenachrichtigung wurde gesendet.'
              : 'Benachrichtigungen sind auf diesem Gerät nicht erlaubt.',
        ),
      ),
    );
  }

  Future<void> _requestPermission() async {
    if (_isBusy) {
      return;
    }
    setState(() => _isBusy = true);
    final status = await TripReminderNotificationService.instance
        .requestPermissions();
    if (!mounted) {
      return;
    }
    final store = TripStoreScope.of(context);
    if (status.canNotify) {
      await TripReminderNotificationService.instance.syncAll(store.trips);
    }
    if (mounted) {
      setState(() {
        _permissionStatus = status;
        _isBusy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = TripStoreScope.of(context);
    final now = DateTime.now();
    final entries = TripReminderEntry.fromTrips(store.trips)
        .where((entry) => entry.isFuture(now))
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Kommende Erinnerungen')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            _PermissionCard(
              status: _permissionStatus,
              isBusy: _isBusy,
              onEnable: _requestPermission,
              onTest: _sendTestNotification,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Alle Reisen',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Text(
                  '${entries.length}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (entries.isEmpty)
              const _EmptyRemindersCard()
            else
              ...entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _GlobalReminderCard(entry: entry),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.status,
    required this.isBusy,
    required this.onEnable,
    required this.onTest,
  });

  final ReminderPermissionStatus? status;
  final bool isBusy;
  final VoidCallback onEnable;
  final VoidCallback onTest;

  @override
  Widget build(BuildContext context) {
    final allowed = status?.canNotify ?? true;
    final exact = status?.exactAlarmsAllowed ?? true;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (allowed ? AppColors.success : AppColors.warning)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(17),
              ),
              child: Icon(
                allowed
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_off_outlined,
                color: allowed ? AppColors.success : AppColors.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    allowed
                        ? 'Benachrichtigungen aktiv'
                        : 'Benachrichtigungen nicht erlaubt',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    allowed
                        ? exact
                              ? 'Erinnerungen können zur festgelegten Zeit erscheinen.'
                              : 'Erinnerungen sind aktiv, können aber leicht verzögert erscheinen.'
                        : 'Erlaube Benachrichtigungen, damit Reisehinweise angezeigt werden.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (!allowed || !exact)
                        FilledButton.icon(
                          onPressed: isBusy ? null : onEnable,
                          icon: isBusy
                              ? const SizedBox.square(
                                  dimension: 17,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.notifications_rounded),
                          label: Text(
                            allowed
                                ? 'Genaue Zeiten erlauben'
                                : 'Aktivieren',
                          ),
                        ),
                      if (allowed)
                        OutlinedButton.icon(
                          onPressed: isBusy ? null : onTest,
                          icon: const Icon(Icons.send_rounded),
                          label: const Text('Test senden'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlobalReminderCard extends StatelessWidget {
  const _GlobalReminderCard({required this.entry});

  final TripReminderEntry entry;

  @override
  Widget build(BuildContext context) {
    final isDocument =
        entry.sourceType == TripReminderSourceType.documentExpiry;
    final accent = isDocument ? AppColors.sand : AppColors.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(17),
              ),
              child: Icon(
                isDocument
                    ? Icons.badge_outlined
                    : Icons.event_available_rounded,
                color: accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.tripTitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      const Icon(
                        Icons.notifications_none_rounded,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _formatDateTime(entry.scheduledAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDateTime(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day.$month.${value.year} · $hour:$minute Uhr';
  }
}

class _EmptyRemindersCard extends StatelessWidget {
  const _EmptyRemindersCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(21),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: AppColors.primary,
                size: 29,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Noch keine kommenden Erinnerungen',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Aktiviere eine Erinnerung bei einem Programmpunkt oder hinterlege ein Ablaufdatum bei einem Dokument.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
