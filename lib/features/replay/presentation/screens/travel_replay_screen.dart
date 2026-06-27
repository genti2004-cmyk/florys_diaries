import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/features/replay/data/replay_builder.dart';
import 'package:florys_diaries/features/replay/domain/replay_controller.dart';
import 'package:florys_diaries/features/replay/domain/replay_event.dart';
import 'package:florys_diaries/features/replay/presentation/widgets/replay_completion_summary.dart';
import 'package:florys_diaries/features/replay/presentation/widgets/replay_controls.dart';
import 'package:florys_diaries/features/replay/presentation/widgets/replay_event_memory.dart';
import 'package:florys_diaries/features/replay/presentation/widgets/replay_map_view.dart';
import 'package:florys_diaries/features/replay/presentation/widgets/replay_progress.dart';
import 'package:florys_diaries/features/replay/presentation/widgets/replay_speed_selector.dart';
import 'package:florys_diaries/features/replay/presentation/widgets/replay_timeline_view.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

class TravelReplayScreen extends StatefulWidget {
  const TravelReplayScreen({required this.trip, super.key});

  final Trip trip;

  @override
  State<TravelReplayScreen> createState() => _TravelReplayScreenState();
}

class _TravelReplayScreenState extends State<TravelReplayScreen> {
  late final ReplayController _controller;

  @override
  void initState() {
    super.initState();
    final timeline = const ReplayBuilder().buildForTrip(widget.trip);
    _controller = ReplayController(timeline: timeline);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Travel Replay')),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final event = _controller.currentEvent;
            final isCompleted =
                _controller.status == ReplayPlaybackStatus.completed;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _ReplayHeader(trip: widget.trip),
                const SizedBox(height: 16),
                ReplayMapView(
                  events: _controller.timeline.events,
                  currentIndex: _controller.index,
                  isPlaying: _controller.isPlaying,
                ),
                const SizedBox(height: 16),
                if (event == null)
                  const _EmptyReplayCard()
                else ...[
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 420),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: isCompleted
                        ? ReplayCompletionSummary(
                            key: const ValueKey('replay_completed'),
                            trip: widget.trip,
                            eventCount: _controller.timeline.length,
                            onReplayAgain: () =>
                                _controller.restart(autoplay: true),
                            onClose: () => Navigator.of(context).maybePop(),
                          )
                        : Column(
                            key: ValueKey(event.id),
                            children: [
                              _CurrentEventCard(event: event),
                              ReplayEventMemory(
                                trip: widget.trip,
                                event: event,
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 16),
                  ReplayProgress(
                    progress: _controller.progress,
                    currentIndex: _controller.index,
                    totalCount: _controller.timeline.length,
                    remainingDuration: _controller.estimatedRemainingDuration,
                    statusLabel: _controller.statusLabel,
                    speedLabel: _controller.speed.label,
                    onIndexChanged: _controller.jumpTo,
                  ),
                  const SizedBox(height: 14),
                  ReplaySpeedSelector(
                    selectedSpeed: _controller.speed,
                    enabled: _controller.timeline.length > 1,
                    onChanged: _controller.setSpeed,
                  ),
                  const SizedBox(height: 16),
                  ReplayControls(
                    isPlaying: _controller.isPlaying,
                    canGoBack: _controller.canGoBack,
                    canGoForward: _controller.canGoForward,
                    canRestart: _controller.canRestart,
                    onTogglePlay: _controller.togglePlay,
                    onPrevious: _controller.previous,
                    onNext: _controller.next,
                    onRestart: () => _controller.restart(),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Reise-Timeline',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.text,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ReplayTimelineView(
                    events: _controller.timeline.events,
                    currentIndex: _controller.index,
                    onEventTap: _controller.jumpTo,
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ReplayHeader extends StatelessWidget {
  const _ReplayHeader({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.play_circle_outline_rounded,
                    color: AppColors.primary,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.text,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${trip.destination}, ${trip.country}',
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ReplayChip(label: '${trip.durationDays} Tage'),
                _ReplayChip(label: '${trip.documentCount} Dokumente'),
                _ReplayChip(label: '${trip.albumEntryCount} Album-Einträge'),
                _ReplayChip(label: '${trip.highlightCount} Highlights'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentEventCard extends StatelessWidget {
  const _CurrentEventCard({required this.event});

  final ReplayEvent event;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primarySoft, AppColors.surface],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    event.typeLabel,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (event.badge.trim().isNotEmpty)
                  _ReplayChip(label: event.badge),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              event.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.text,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (event.subtitle.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                event.subtitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if (event.location.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.place_outlined,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.location,
                      style: const TextStyle(color: AppColors.text),
                    ),
                  ),
                ],
              ),
            ],
            if (event.description.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                event.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.text,
                  height: 1.35,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReplayChip extends StatelessWidget {
  const _ReplayChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppColors.text,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyReplayCard extends StatelessWidget {
  const _EmptyReplayCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Text('Für diese Reise gibt es noch keine Replay-Ereignisse.'),
      ),
    );
  }
}
