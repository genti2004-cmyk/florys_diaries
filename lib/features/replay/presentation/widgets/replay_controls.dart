import 'package:flutter/material.dart';

class ReplayControls extends StatelessWidget {
  const ReplayControls({
    required this.isPlaying,
    required this.canGoBack,
    required this.canGoForward,
    required this.canRestart,
    required this.onTogglePlay,
    required this.onPrevious,
    required this.onNext,
    required this.onRestart,
    super.key,
  });

  final bool isPlaying;
  final bool canGoBack;
  final bool canGoForward;
  final bool canRestart;
  final VoidCallback onTogglePlay;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: canGoBack ? onPrevious : null,
                icon: const Icon(Icons.skip_previous_rounded),
                label: const Text('Zurück'),
              ),
            ),
            const SizedBox(width: 10),
            FilledButton.icon(
              onPressed: onTogglePlay,
              icon: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              ),
              label: Text(isPlaying ? 'Pause' : 'Start'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: canGoForward ? onNext : null,
                icon: const Icon(Icons.skip_next_rounded),
                label: const Text('Weiter'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: canRestart ? onRestart : null,
            icon: const Icon(Icons.replay_rounded),
            label: const Text('Replay neu starten'),
          ),
        ),
      ],
    );
  }
}
