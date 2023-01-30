import 'dart:async';
import 'package:coda/logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:logger/logger.dart';

Logger _logger = getLogger('progress stream', Level.debug);

class ProgressStream with ChangeNotifier {
  Progress progress = Progress(0);
  static StreamController<Progress> progressStreamController = StreamController<Progress>();

  ProgressStream();

  void addEvent(p) {
    //_logger.d('add event progress: $p');
    progress = Progress(p);
    progressStreamController.add(progress);
  }

  Stream<Progress> progressStream() {
    return progressStreamController.stream;
  }
}

class Progress {
  double value;
  Progress(this.value);
}