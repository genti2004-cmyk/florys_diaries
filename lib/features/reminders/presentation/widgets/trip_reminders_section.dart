import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/features/reminders/data/trip_reminder_notification_service.dart';
import 'package:florys_diaries/features/reminders/domain/trip_reminder_entry.dart';
import 'package:florys_diaries/features/trips/application/trip_store_scope.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

class TripRemindersSection extends StatefulWidget {
  const TripRemindersSection({required this.trip, super.key});

  final Trip trip;

  @override
  State<TripRemindersSection> createState() => _TripRemindersSectionState();
}

class _TripRemindersSectionState extends State<TripRemindersSection> {
  ReminderPermissionStatus? _permissionStatus;
  bool _isCheckingPermission = false;

  @override
  void initState() {
    super.initState();
    _loadPermissionStatus();
  }

  Future<void> _loadPermissionStatus() async {
    final status = await TripReminderNotificationService.instance
        .permissionStatus();
    if (mounted) {
      setState(() => _permissionStatus = status);
    }
  }

  Future<void> _enableNotifications() async {
    if (_isCheckingPermission) {
      return;
    }
    setState(() => _isCheckingPermission = true);
    final status = await TripReminderNotificationService.instance
        .requestPermissions();
    if (!mounted) {
      return;
    }
    setState(() {
      _permissionStatus = status;
      _isCheckingPermission = false;
    });

    if (status.canNotify) {
      final store = TripStoreScope.of(context);
      await TripReminderNotificationService.instance.syncAll(store.trips);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status.exactAlarmsAllowed
                  ? 'Reiseerinnerungen sind aktiviert.'
                  : 'Reiseerinnerungen sind aktiviert und können leicht verzögert erscheinen.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final allEntries = TripReminderEntry.fromTrip(widget.trip);
    final upcoming = allEntries
        .where((entry) => entry.isFuture(now))
        .toList(growable: false);
    final notificationsDenied =
        _permissionStatus?.isAvailable == true &&
        _permissionStatus?.notificationsAllowed == false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF182B4E), Color(0xFF536FC4)],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x24536FC4),
                blurRadius: 24,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Erinnerungen',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            upcoming.isEmpty
                                ? 'Noch keine kommende Erinnerung'
                                : '${upcoming.length} kommende ${upcoming.length == 1 ? 'Erinnerung' : 'Erinnerungen'}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.78),
                                ),
                          ),
                        ],
                      ),
                    ),
                    _CountBadge(count: upcoming.length),
                  ],
                ),
                if (notificationsDenied) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isCheckingPermission
                          ? null
                          : _enableNotifications,
                      icon: _isCheckingPermission
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.notifications_rounded),
                      label: const Text('Benachrichtigungen erlauben'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF253F77),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (upcoming.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...upcoming.take(4).map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: _ReminderPreview(entry: entry),
            ),
          ),
          if (upcoming.length > 4)
            Text(
              '+ ${upcoming.length - 4} weitere Erinnerungen',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ],
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 42, minHeight: 42),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Text(
        '$count',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ReminderPreview extends StatelessWidget {
  const _ReminderPreview({required this.entry});

  final TripReminderEntry entry;

  @override
  Widget build(BuildContext context) {
    final isDocument =
        entry.sourceType == TripReminderSourceType.documentExpiry;
    final accent = isDocument ? AppColors.sand : AppColors.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(15),
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDateTime(entry.scheduledAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
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
