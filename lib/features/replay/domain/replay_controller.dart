import 'dart:async';

import 'package:flutter/foundation.dart';

import 'replay_event.dart';
import 'replay_speed.dart';
import 'replay_timeline.dart';

enum ReplayPlaybackStatus {
  empty,
  ready,
  playing,
  paused,
  completed,
}

class ReplayController extends ChangeNotifier {
  ReplayController({required this.timeline});

  final ReplayTimeline timeline;
  Timer? _timer;
  int _index = 0;
  bool _isPlaying = false;
  bool _hasStarted = false;
  ReplaySpeed _speed = ReplaySpeed.normal;

  int get index => _index;

  bool get isPlaying => _isPlaying;

  ReplaySpeed get speed => _speed;

  ReplayEvent? get currentEvent {
    if (timeline.isEmpty) {
      return null;
    }
    return timeline.eventAt(_index);
  }

  double get progress => timeline.progressFor(_index);

  bool get canGoBack => _index > 0;

  bool get canGoForward => timeline.isNotEmpty && _index < timeline.length - 1;

  bool get canRestart => timeline.isNotEmpty && (_index > 0 || _hasStarted);

  bool get isAtEnd => timeline.isNotEmpty && _index == timeline.length - 1;

  int get remainingSteps {
    if (timeline.isEmpty) {
      return 0;
    }
    return (timeline.length - 1 - _index).clamp(0, timeline.length - 1);
  }

  Duration get estimatedRemainingDuration {
    return Duration(
      milliseconds: _speed.stepDuration.inMilliseconds * remainingSteps,
    );
  }

  ReplayPlaybackStatus get status {
    if (timeline.isEmpty) {
      return ReplayPlaybackStatus.empty;
    }
    if (_isPlaying) {
      return ReplayPlaybackStatus.playing;
    }
    if (_hasStarted && isAtEnd) {
      return ReplayPlaybackStatus.completed;
    }
    if (_hasStarted) {
      return ReplayPlaybackStatus.paused;
    }
    return ReplayPlaybackStatus.ready;
  }

  String get statusLabel {
    switch (status) {
      case ReplayPlaybackStatus.empty:
        return 'Keine Ereignisse';
      case ReplayPlaybackStatus.ready:
        return 'Bereit';
      case ReplayPlaybackStatus.playing:
        return 'Wiedergabe läuft';
      case ReplayPlaybackStatus.paused:
        return 'Pausiert';
      case ReplayPlaybackStatus.completed:
        return 'Abgeschlossen';
    }
  }

  void play() {
    if (timeline.isEmpty || _isPlaying) {
      return;
    }

    if (isAtEnd && timeline.length > 1) {
      _index = 0;
    }

    _hasStarted = true;
    _isPlaying = canGoForward;
    notifyListeners();

    if (_isPlaying) {
      _scheduleNextTick();
    }
  }

  void pause() {
    _cancelTimer();
    if (!_isPlaying) {
      return;
    }
    _isPlaying = false;
    notifyListeners();
  }

  void togglePlay() {
    if (_isPlaying) {
      pause();
    } else {
      play();
    }
  }

  void previous() {
    if (!canGoBack) {
      return;
    }
    _hasStarted = true;
    _index -= 1;
    _refreshPlaybackTimer();
    notifyListeners();
  }

  void next() {
    if (!canGoForward) {
      _finishPlayback();
      return;
    }

    _hasStarted = true;
    _index += 1;

    if (isAtEnd) {
      _isPlaying = false;
      _cancelTimer();
    } else {
      _refreshPlaybackTimer();
    }
    notifyListeners();
  }

  void jumpTo(int index) {
    if (timeline.isEmpty) {
      return;
    }

    final nextIndex = index.clamp(0, timeline.length - 1);
    if (nextIndex == _index) {
      return;
    }

    _hasStarted = true;
    _index = nextIndex;

    if (isAtEnd) {
      _isPlaying = false;
      _cancelTimer();
    } else {
      _refreshPlaybackTimer();
    }
    notifyListeners();
  }

  void restart({bool autoplay = false}) {
    if (timeline.isEmpty) {
      return;
    }

    _cancelTimer();
    _index = 0;
    _hasStarted = autoplay;
    _isPlaying = autoplay && canGoForward;
    notifyListeners();

    if (_isPlaying) {
      _scheduleNextTick();
    }
  }

  void setSpeed(ReplaySpeed speed) {
    if (_speed == speed) {
      return;
    }

    _speed = speed;
    _refreshPlaybackTimer();
    notifyListeners();
  }

  void _scheduleNextTick() {
    _cancelTimer();
    if (!_isPlaying || !canGoForward) {
      return;
    }
    _timer = Timer(_speed.stepDuration, _handleTick);
  }

  void _handleTick() {
    _timer = null;
    if (!_isPlaying) {
      return;
    }

    if (!canGoForward) {
      _finishPlayback();
      return;
    }

    _index += 1;
    if (isAtEnd) {
      _isPlaying = false;
    } else {
      _scheduleNextTick();
    }
    notifyListeners();
  }

  void _refreshPlaybackTimer() {
    if (_isPlaying) {
      _scheduleNextTick();
    }
  }

  void _finishPlayback() {
    _cancelTimer();
    if (!_isPlaying) {
      return;
    }
    _isPlaying = false;
    notifyListeners();
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }
}
