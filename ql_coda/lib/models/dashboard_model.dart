import 'dart:async';

import 'package:coda/models/player_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coda/logger.dart';
import 'package:logger/logger.dart';

import 'current_track_model.dart';

Logger _logger = getLogger('dashboard_model', Level.warning);


@immutable
class Progress {
  Progress({required this.elapsedTrackTime, required this.trackLength, required this.playerState}) {
    // _logger.d( 'Progress constructor $playerState, elapsed: $elapsedTrackTime, remaining ${trackLength - elapsedTrackTime}');
  }

  final int elapsedTrackTime;
  final int trackLength;
  final PlayerState playerState;

  @override
  String toString() {
    return 'elapsed $elapsedTrackTime, length $trackLength, $playerState';
  }
}

class Dashboard {
  static Ticker _ticker = Ticker();
  static StreamSubscription<int>? _progressSubscription;
  static StreamSubscription<PlayerState>? _playerStateSubscription;
  static StreamSubscription<CurrentTrackModel>? _currentTrackSubscription;
  static StreamSubscription<double>? _elapsedProportionSubscription;
  static int elapsed = 0;

  @override
  void dispose() {
    _progressSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _currentTrackSubscription?.cancel();
    _elapsedProportionSubscription?.cancel();
    // super.dispose();
  }

  // dashboard has to respond to player status events & track changes
  static void monitorPlayerStatus(int trackLength) {
    _currentTrackSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _elapsedProportionSubscription?.cancel();
    //int elapsed = 0;
    PlayerState playerState;

    _elapsedProportionSubscription = Player.elapsedProportionStreamController.stream.listen((double elapsedProportion) {
      elapsed = (trackLength * elapsedProportion).toInt();
    });

    _playerStateSubscription = Player.playerStateController.stream.listen((PlayerState playerState) {
      _logger.d('_playerStateSubscription: $playerState');

      if (playerState == PlayerState.playing) {
        // resume
        _logger.d('_playerStateSubscription: resume at $elapsed of $trackLength');
        resetProgress(elapsed, trackLength);

      }
      else {
        // pause - ignore the ticker
        _progressSubscription?.pause();
      }
    });

  }

  static resetProgress(int resetElapsed, int length) {
    _progressSubscription?.cancel();
    _logger.d('resetProgress $resetElapsed, $length');
    elapsed = resetElapsed;

    // create a new ticker to countdown seconds remaining
    _progressSubscription = _ticker.tick(ticks: length - elapsed).listen((countdown) {
      _logger.d('countdown $countdown');
      elapsed = length - countdown;
      Player.elapsedProportionStreamController.add((elapsed / length).toDouble());
    });
  }

  static void forceProgress(int elapsed, int length) {
    _logger.d('forceProgress $elapsed of $length');
    Player.elapsedProportionStreamController.add((elapsed / length).toDouble());
  }

  static void skipTo(int position, int length) {
    _logger.d('skipTo $position of $length');
    resetProgress(position, length);
  }

  static void pause() {
    _progressSubscription?.pause();
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
