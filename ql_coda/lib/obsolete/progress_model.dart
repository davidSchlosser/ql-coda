import 'dart:async';
import 'dart:math';
import 'package:coda/logger.dart';
import 'package:coda/models/current_track_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

Logger _logger = getLogger('progress_model', Level.debug);

final progressProvider = StreamProvider<double>((ref) {
  StreamController<double> streamController =
      ProgressStream.progressStreamController;
  return streamController.stream;
});

class ProgressStream {
  static Timer trackTimer = Timer(const Duration(), (){});
  double progress = 0;
  double length = 0;

  static StreamController<double> progressStreamController = StreamController<double>();

  ProgressStream() {
    _logger.d('progressStream');
  }


  void toggleOnOff(bool resume) {
    if (resume) {}
    else {
      trackTimer.cancel();
    }
  }

  void resetProgress(bool playing, double progress, double increment) {
    // reset the timer for the progress display
    _logger.d('resetProgress playing:$playing, progress:$progress, increment:$increment');

    if (increment == 0 || !playing) {
      _logger.d('resetProgress cancelling timer');
      trackTimer.cancel();
      progressStreamController.add(progress);
    }
    else {
      _logger.d('timer reset');
      trackTimer = Timer.periodic(
          const Duration(seconds: 1),
          //timerProgress
              (Timer t) {
              //_logger.d('in timer playing');
              progress = min(progress+increment, 1); // don't run away

              progressStreamController.add(progress);
              _logger.d('timer $progress');
              }
      );

      //progressStreamController.add(progress);
    }
  }
  /*void resetProgress(bool playing, double progress, double length) {
    // reset the timer for the progress display
    _logger.d('resetProgress playing:$playing, progress:$progress, length:$length');

    trackTimer.cancel();
    if (!playing) {
      _logger.d('resetProgress cancelling timer');
      progressStreamController.add(progress);
    }
    else {
      _logger.d('timer reset');
      trackTimer = Timer.periodic(
          const Duration(seconds: 1),
          //timerProgress
              (Timer t) {
            //_logger.d('in timer playing');
            progress += length != 0.0 ? 1 / length : 0.0;
            progressStreamController.add(progress);
            _logger.d('timer $progress');
          }
      );

      //progressStreamController.add(progress);
    }
  }*/

}

/*
class Progress {
  double value;
  Progress(this.value);
}
*/
