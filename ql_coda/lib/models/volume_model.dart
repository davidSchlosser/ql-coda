import 'dart:async';
import 'package:coda/logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:logger/logger.dart';

Logger _logger = getLogger('progress stream', Level.debug);

class VolumeModel with ChangeNotifier {
  Volume volume = Volume(0);
  static StreamController<Volume> volumeStreamController = StreamController<Volume>();

  VolumeModel(double vol){
    volume = Volume(vol);
  }

  void addEvent(p) {
    //_logger.d('add event progress: $p');
    volume = Volume(p);
    volumeStreamController.add(volume);
  }

  Stream<Volume> progressStream() {
    return volumeStreamController.stream;
  }
}

class Volume {
  double value;
  Volume(this.value);
}