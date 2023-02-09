//
// player_model.dart
// Receives communications from Quodlibet regarding its state (playing/paused, volume, elapsed proportion) and current playing track.
// Makes status and current track data available to UI via streams
//

import 'dart:async';
import 'dart:convert';

import 'package:coda/models/volume_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../communicator.dart';
import '../streams/cover_stream.dart';
import 'current_track_model.dart';


import 'package:coda/logger.dart';
import 'package:logger/logger.dart';

Logger _logger = getLogger('player_model', Level.warning);

enum PlayerState {
  playing,
  paused,
  stopped,
  unresponsive, // Quodlibet or ql_coda_host is not running
}

class Player {
  //bool alreadyPlaying = false;
  //static StreamController<QuodlibetReportedStatus> quodlibetReportedStatusStreamController = StreamController<QuodlibetReportedStatus>.broadcast();
  static StreamController<CurrentTrackModel> currentTrackStreamController = StreamController<CurrentTrackModel>.broadcast();
  static StreamController<PlayerState> playerStateController = StreamController<PlayerState>.broadcast();
  static StreamController<double> volumeStreamController = StreamController<double>.broadcast();
  static StreamController<double> elapsedProportionStreamController = StreamController<double>.broadcast();
  
  Player(){
    Communicator().subscribe('mqinvoke/response', _quodlibetReportedStatusMsgHandler);
    Communicator().subscribe('quodlibet/now-playing', _quodlibetEventMsgHandler);

    CoverStream();
    refresh();
  }

  static void refresh() {
    _logger.d('refresh');
    Communicator().doRemote('nowplaying');  // provides player state, track tag details
    Communicator().doRemote('status');      // provides player state, progress proportion, volume
  }

  void _quodlibetEventMsgHandler(String message) {
    PlayerState? playerState;
    Map<String, dynamic> rawPlayer = (message.isNotEmpty) ? jsonDecode(message) : {};

    if (rawPlayer.containsKey('player')) {

      String reportedState = rawPlayer['player'].toString();

      switch (reportedState) {
        case 'playing':
            playerState = PlayerState.playing; break;
        case 'paused':
          playerState = PlayerState.paused; break;
        case 'stopped':
          playerState = PlayerState.stopped; break;
        default:
          playerState = PlayerState.unresponsive; break;
      }
      playerStateController.add(playerState);
    }

    CurrentTrackModel? track;
    if (rawPlayer.containsKey('trackData')) {
      track = CurrentTrackModel.fromString(message);
      currentTrackStreamController.add(track);
    }

    _logger.d('quodlibetEventMsgHandler: $playerState, $track');
  }

  void _quodlibetReportedStatusMsgHandler(String message) {
    PlayerState? playerState;

    // example status: 'paused AlbumList 0.749 inorder off 0.000'

    _logger.d('_quodlibetReportedStatusMsgHandler: $message');
    if (message != '') {
      try {
        Map response = const JsonDecoder().convert(message);

        if (response.containsKey('status')) {
          //_logger.d('is status');

          QuodlibetReportedStatus quodlibetReportedStatus = QuodlibetReportedStatus.fromString(response['status']);
          String reportedState = response['status'].split(' ')[0];

          switch (reportedState) {
            case 'playing':
              playerState = PlayerState.playing;
              break;
            case 'paused':
              playerState = PlayerState.paused;
              break;
            case 'stopped':
              playerState = PlayerState.stopped;
              break;
            default:
              playerState = PlayerState.unresponsive;
              break;
          }

          playerStateController.add(playerState);
          volumeStreamController.add(quodlibetReportedStatus.volume!);
          elapsedProportionStreamController.add(quodlibetReportedStatus.elapsedProportion!);

          //eliminate following?
          VolumeModel(0).addEvent(quodlibetReportedStatus.volume);

          _logger.d('_quodlibetReportedStatusMsgHandler $quodlibetReportedStatus');
        }
      } on FormatException {
        _logger.d('FormatException');
      }
    }

  }
  
}

final playerStateProvider = StreamProvider<PlayerState>((ref) {
  return Player.playerStateController.stream;
});

final volumeProvider = StreamProvider<double>((ref) {
  return Player.volumeStreamController.stream;
});

final nowPlayingTrackModelProvider = StreamProvider<CurrentTrackModel>((ref) {
  return Player.currentTrackStreamController.stream;
});

final elapsedProportionProvider = StreamProvider<double>((ref) {
  return Player.elapsedProportionStreamController.stream;
});


// example status reported by Quodlibet: 'paused AlbumList 0.749 inorder off 0.000'
class QuodlibetReportedStatus {
  bool? isPlaying;
  double? volume;
  String? view;
  double? elapsedProportion;

  QuodlibetReportedStatus(this.isPlaying, [this.volume, this.view, this.elapsedProportion]);

  QuodlibetReportedStatus.fromString(String statusString){
    List <String> playerStatus = statusString.split(' ');
    isPlaying = playerStatus[0] == 'playing';
    view = playerStatus[1];
    volume = double.parse(playerStatus[2]);
    elapsedProportion = double.parse(playerStatus[5]);
  }

  @override
  String toString() {
    return 'QuodlibetReportedStatus $isPlaying, $volume, $view, $elapsedProportion';
  }

}
