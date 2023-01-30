import 'dart:convert';

import 'package:coda/logger.dart';
import 'package:coda/models/collected_tracks_model.dart';
import 'package:coda/models/track_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../communicator.dart';

Logger _logger = getLogger('playlist_model', Level.debug);

Future <List <Track>> fetchPlaylist(WidgetRef ref) async {

  var message = await Communicator().request('playlist');

  //_logger.d('message: $message');
  try {
    List <dynamic> rawTracks = jsonDecode(message);
    List <Track> processedTracks = [];

    for (var raw in rawTracks) {
      processedTracks.add(rawTrack(raw));
    }
    _logger.d('processedTracks $processedTracks');
    ref.read(tracksProvider('playlist').notifier).loadTracks(processedTracks);
    return processedTracks;

  } catch (e) {
    //_logger.e('exception: $e');
    rethrow;
  }

}
