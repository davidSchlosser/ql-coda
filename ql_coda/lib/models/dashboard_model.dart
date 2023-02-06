import 'dart:async';

import 'package:coda/models/player_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coda/logger.dart';
import 'package:logger/logger.dart';

import 'current_track_model.dart';

Logger _logger = getLogger('dashboard_model', Level.warning);

enum PlayerState {
  playing,
  paused,
  stopped,
  unresponsive, // Quodlibet or ql_coda_host is not running
}

@immutable
class Progress {
  Progress({required this.elapsedTrackTime, required this.trackLength, required this.playerState}) {
    _logger.d(
        'Progress constructor $playerState, elapsed: $elapsedTrackTime, remaining ${trackLength - elapsedTrackTime}');
  }

  final int elapsedTrackTime;
  final int trackLength;
  final PlayerState playerState;
}

final progressProvider = StateNotifierProvider<ProgressNotifier, Progress>((ref) {
  return ProgressNotifier();
});

class ProgressNotifier extends StateNotifier<Progress> {
  ProgressNotifier()
      : super(Progress(
            elapsedTrackTime: 0, //elapsed,
            trackLength: 0,
            playerState: PlayerState.unresponsive));

  final Ticker _ticker = Ticker();
  StreamSubscription<int>? _progressSubscription;
  StreamSubscription<PlayerStatus>? _playerStatusSubscription;
  StreamSubscription<CurrentTrackModel>? _currentTrackSubscription;

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

  // dashboard has to respond to player status events & track changes
  void monitorPlayerStatus() {
    _playerStatusSubscription?.cancel();
    _currentTrackSubscription?.cancel();

    _playerStatusSubscription = Player.playerStatusStreamController.stream.listen((PlayerStatus status) {
      _logger.w('_playerStatusSubscription: $status');
      //
      // status events can arrive from the Quodlibet player events, or from Quodlibet status requests. Former only tell us if player is playing, paused or stopped
      // latter provides more details
      //
      if (status.elapsedProportion == null) {
        if (!status.isPlaying!) {
          pause();
        } else {
          resetSubscription(
              ((status.elapsedProportion ?? 0) * state.trackLength).toInt(),
              state.trackLength,
              status.isPlaying != null
                  ? status.isPlaying!
                      ? PlayerState.playing
                      : PlayerState.paused
                  : PlayerState.paused);
        }
      }
    });

    _currentTrackSubscription =
        CurrentTrackStream.currentTrackStreamController.stream.listen((CurrentTrackModel currentTrack) {
      _logger.w('_currentTrackSubscription: $currentTrack');
      resetSubscription(0, currentTrack.length == '' ? 0 : double.parse(currentTrack.length).toInt());
    });
  }

  void resetSubscription(int elapsed, int length, [PlayerState playerState = PlayerState.playing]) {
    _progressSubscription?.cancel();

    // create a new ticker to countdown seconds remaining
    _progressSubscription = _ticker.tick(ticks: length - elapsed).listen((countdown) {
      _logger.d('_progressSubscription listener: $countdown');
      state = Progress(
          elapsedTrackTime: length - countdown, //elapsed,
          trackLength: length,
          playerState: playerState);
    });

    _progressSubscription?.onDone(() {
      state = Progress(elapsedTrackTime: 0, trackLength: 0, playerState: PlayerState.stopped);
    });

    state = Progress(elapsedTrackTime: elapsed, trackLength: length, playerState: PlayerState.playing);
  }

  void skipTo(int position) {
    _logger.d('skipTo $position');
    state = Progress(elapsedTrackTime: position, trackLength: state.trackLength, playerState: state.playerState);
  }

  void pause() {
    _progressSubscription?.pause();
    state = Progress(
        elapsedTrackTime: state.elapsedTrackTime, trackLength: state.trackLength, playerState: PlayerState.paused);
  }

  void resume() {
    resetSubscription(state.elapsedTrackTime, state.trackLength);
  }

  void stop() {
    _progressSubscription?.cancel();
    state = Progress(elapsedTrackTime: 0, trackLength: 0, playerState: PlayerState.stopped);
  }
}

class Ticker {
  Stream<int> tick({int? ticks}) {
    return Stream.periodic(
      const Duration(seconds: 1),
      (x) => ticks! - x - 1,
    ).take(ticks!);
  }
}
