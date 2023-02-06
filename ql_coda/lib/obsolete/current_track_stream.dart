import 'dart:async';
import 'package:coda/models/current_track_model.dart';
import 'package:coda/communicator.dart';
import 'package:coda/logger.dart';
import 'package:logger/logger.dart';

Logger _logger = getLogger('main', Level.debug);

/*
class CurrentTrackStream {
  static StreamController<CurrentTrackModel> currentTrackStreamController = StreamController.broadcast();
  //static StreamController<CurrentTrackModel> currentTrackStreamController = StreamController<CurrentTrackModel>();

  CurrentTrackStream(){
    Communicator().subscribe('quodlibet/now-playing', currentTrackMsgHandler);
    //_logger.d('CurrentTrackStream constructor');
  }

  void currentTrackMsgHandler(String message) {
    //_logger.d('nowPlayingMsgHandler: $message');
    //if (!message.contains('paused')) {
      currentTrackStreamController.add(CurrentTrackModel.fromString(message));
    //};
  }

  Stream<CurrentTrackModel> currentTrackStream() { // TODO delete this?
    //_logger.d('currentTrackStream()');
    return currentTrackStreamController.stream;
  }

}
*/

