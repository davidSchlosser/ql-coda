import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coda/logger.dart';
import 'package:logger/logger.dart';

Logger _logger = getLogger('dashboard_model', Level.warning);

enum PlayerState {
  playing,
  paused,
  stopped,
  unresponsive, // Quodlibet or ql_coda_host is not running
}

@immutable
class Progress {
  Progress(
      {required this.elapsedTrackTime,
      required this.trackLength,
        required this.playerState}){
    _logger.d('Progress constructor $playerState, elapsed: $elapsedTrackTime, remaining ${trackLength - elapsedTrackTime}');
  }

  final int elapsedTrackTime;
  final int trackLength;
  final PlayerState playerState;
}

final progressProvider =
    StateNotifierProvider<ProgressNotifier, Progress>((ref) {
  return ProgressNotifier();
});

class ProgressNotifier extends StateNotifier<Progress> {
  ProgressNotifier() : super(Progress(
      elapsedTrackTime: 0, //elapsed,
      trackLength: 0,
      playerState: PlayerState.unresponsive));

  final Ticker _ticker = Ticker();
  StreamSubscription<int>? _progressSubscription;

  @override
  void dispose() {
    _progressSubscription?.cancel();
    super.dispose();
  }

  void start(int length) {
    if (state.playerState == PlayerState.paused) {
      resume();
    } else {
      resetSubscription(0, length);
    }
  }

  void resetSubscription(int elapsed, int length){
    _progressSubscription?.cancel();

    // create a new ticker to countdown seconds remaining
    _progressSubscription = _ticker.tick(ticks: length - elapsed).listen((countdown) {
      _logger.d('_progressSubscription listener: $countdown');
      state = Progress(
          elapsedTrackTime: length - countdown, //elapsed,
          trackLength: length,
          playerState: PlayerState.playing);
    });

    _progressSubscription?.onDone(() {
      state = Progress(
          elapsedTrackTime: 0,
          trackLength: 0,
          playerState: PlayerState.stopped);
    });

    state = Progress(
        elapsedTrackTime: elapsed,
        trackLength: length,
        playerState: PlayerState.playing);

  }

  void skipTo(int position) {
    _logger.d('skipTo $position');
    state = Progress(
        elapsedTrackTime: position,
        trackLength: state.trackLength,
        playerState: state.playerState);
  }

  void pause() {
    _progressSubscription?.pause();
    state = Progress(
        elapsedTrackTime: state.elapsedTrackTime,
        trackLength: state.trackLength,
        playerState: PlayerState.paused);
  }

  void resume() {
    resetSubscription(state.elapsedTrackTime, state.trackLength);
  }

  void stop() {
    _progressSubscription?.cancel();
    state = Progress(
        elapsedTrackTime: 0,
        trackLength: 0,
        playerState: PlayerState.stopped);
  }
}

class Ticker {
  Stream<int> tick({int? ticks}) {
    return Stream.periodic(
      Duration(seconds: 1),
      (x) => ticks! - x - 1,
    ).take(ticks!);
  }
}
