

import 'dart:async';
import 'dart:convert';

import 'package:coda/models/volume_model.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../communicator.dart';
import '../streams/cover_stream.dart';
import 'current_track_model.dart';


import 'package:coda/logger.dart';
import 'package:logger/logger.dart';

Logger _logger = getLogger('player_model', Level.debug);

// example status: 'paused AlbumList 0.749 inorder off 0.000'
class PlayerStatus {
  bool? isPlaying;
  double? volume;
  String? view;
  double? elapsedProportion;

  PlayerStatus(this.isPlaying, [this.volume, this.view, this.elapsedProportion]);

  PlayerStatus.fromString(String statusString){
    List <String> playerStatus = statusString.split(' ');
    isPlaying = playerStatus[0] == 'playing';
    view = playerStatus[1];
    volume = double.parse(playerStatus[2]);
    elapsedProportion = double.parse(playerStatus[5]);
  }

}

class Player {
  bool alreadyPlaying = false;
  static StreamController<PlayerStatus> playerStatusStreamController = StreamController<PlayerStatus>.broadcast();
  
  Player(){
    Communicator().subscribe('mqinvoke/response', _statusMsgHandler);
    Communicator().subscribe('quodlibet/now-playing', _playerMsgHandler);
    CurrentTrackStream();
    CoverStream();
    refresh();
  }

  void refresh() {
    Communicator().doRemote('status');
    Communicator().doRemote('nowplaying');
  }

  void _playerMsgHandler(String message) {
    Map<String, dynamic> rawPlayer = (message.isNotEmpty) ? jsonDecode(message) : {};

    if (rawPlayer.containsKey('player')) {
      PlayerStatus playerStatus = PlayerStatus(rawPlayer['player'].toString() == 'playing');
      playerStatusStreamController.add(playerStatus);  // let listeners know, eg Dashboard
    }
  }

  void _statusMsgHandler(String message) {

    _logger.d('message: $message');
    try {
      Map response = const JsonDecoder().convert(message);

      if (response.containsKey('status')) {
        _logger.d('is status');

        // example status: 'paused AlbumList 0.749 inorder off 0.000'
        PlayerStatus playerStatus = PlayerStatus.fromString(response['status']);
        playerStatusStreamController.add(playerStatus);  // let listeners know, eg Dashboard

        VolumeModel(0).addEvent(playerStatus.volume);
      }
    } on FormatException {
      _logger.d('FormatException');
    }

  }
  
}

class PlayerStatusStream {
  static StreamController<PlayerStatus> playerStatusStreamController = StreamController<PlayerStatus>.broadcast();

  Stream<PlayerStatus> playerStatusStream() => playerStatusStreamController.stream;
}




