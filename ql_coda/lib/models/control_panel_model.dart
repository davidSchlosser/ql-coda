import 'dart:convert';
//import 'dart:math';

import 'package:coda/communicator.dart';
import 'package:coda/models/volume_model.dart';
//import 'package:coda/obsolete/playlist_model.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'package:coda/logger.dart';
import 'package:logger/logger.dart';

import '../streams/progress_stream.dart';
import 'current_track_model.dart';

Logger _logger = getLogger('ControlPanelModel', Level.warning);



class ControlPanelModel with ChangeNotifier {
  double volume = 0;
  double progress = 0;
  bool playing = false;
  static bool alreadyPlaying = false;
  static String currentTrackFile = '';
  static Timer trackTimer = Timer(const Duration(), (){});
  static ProgressStream progressStream = ProgressStream();
  //static PlaylistHandler _playlist = PlaylistHandler();

  ControlPanelModel() { // TODO convert ControlPanel to a Provider to avoid re-subscribing multiple times.
    _logger.d('ControlPanelModel constructor');
    Communicator().subscribe('quodlibet/now-playing', nowPlayingMsgHandler);
    Communicator().subscribe('mqinvoke/response', responseMsgHandler);
    Communicator().doRemote('status');
    //Communicator().onReady((){ PlaylistHandler().refreshPlaylist();} );
  }

  void responseMsgHandler(String message) {

    _logger.d('message: $message');
    try {
      Map response = const JsonDecoder().convert(message);

      /*
      if (response.containsKey('zonestates')) {
        Map zs = response['zonestates'];
        zs.forEach((k, v) =>  zone[k.toLowerCase()] = (v == 'RUNNING'));
      }
      */
      if (response.containsKey('status')) {
        _logger.d('is status');

        String resp = response['status'];
        PlayerStatus playerStatus = PlayerStatus(resp.split(' '));

        playing = playerStatus.playstate == 'playing';
        if (playing ^ alreadyPlaying) {
          alreadyPlaying = playing;
          notifyListeners();
        }
        progress = playerStatus.progress;
        _logger.d('status _progress: $progress');
        progressStream.addEvent(progress);

        VolumeModel(0).addEvent(playerStatus.volume);
      }
    } on FormatException {
      _logger.d('FormatException');
    }

  }

  void nowPlayingMsgHandler(String message) {

    // check for switch between playing - pauesed
    playing = !message.contains('[paused]');
    if (playing ^ alreadyPlaying) {
      alreadyPlaying = playing;
      notifyListeners();
    }

    // check if a different track has started
    CurrentTrackModel track = CurrentTrackModel.fromString(message);
    if (track.file != currentTrackFile) {
      currentTrackFile = track.file;

      // let the Playlist know
      //PlaylistHandler().index(currentTrackFile);

      // reset the timer for the progress display
      double length = track.lengthInSeconds();
      //print('length: $_length');
      double progress = 0.0;
      //_elapsed = 0.0;

      trackTimer.cancel();
      trackTimer = Timer.periodic(
        const Duration(seconds: 1),
        //timerProgress
        (Timer t) {
          //_logger.d('in timer');
          if (playing) {
            //_logger.d('in timer playing');
            progress += length != 0.0 ? 1 / length : 0.0;
            progressStream.addEvent(progress);
          }
        }
      );
    }
  }

  void showVolume(double newVolume) {}

  void adjustVolume(double newVolume) {
      // double vol = 100 * pow(newVolume, 3.0) as double;
      double vol = 100 * newVolume;
      Communicator().doRemote('volume $vol');
  }

  void previous() {Communicator().doRemote('previous');}

  void next() {Communicator().doRemote('next');}

  void togglePlayPause() {Communicator().doRemote('play');}

  void randomAlbum() {
    Communicator().doRemote('skipalbum');
    Communicator().doRemote('next');
  }

  void stopAfter() {Communicator().doRemote('stopafter');}

  void refresh() {
    Communicator().doRemote('status');
    Communicator().doRemote('nowplaying');
  }

  String getCurrentTrackFile() {return currentTrackFile;}

}

class PlayerStatus {
  late String playstate, view, order, repeat;
  late double progress, volume;

  PlayerStatus(List<String> a) {
    _logger.d('PlayerStatus $a');
    playstate = a[0];
    view = a[1];
    volume = double.parse(a[2]);
    order = a[3];
    repeat = a[4];
    progress = double.parse(a[5]);
  }
}



void applyQueryOnPlayer(String queryText) {
  _logger.d('apply query $queryText');
  Communicator().doRemote('query "$queryText"');
  //PlaylistHandler().refreshPlaylist();
}

void queueAlbum(String albumDirectoryName) {
  String quoteEscaped = albumDirectoryName.replaceAll("'", "\'");
  Communicator().doRemote('enqueuealbum "$quoteEscaped"');
}