import 'dart:convert';

import 'package:coda/models/track_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../communicator.dart';
import 'albums_model.dart';
import 'package:coda/logger.dart';
import 'package:logger/logger.dart';

import 'collected_tracks_model.dart';

Logger _logger = getLogger('album_tracks_view', Level.debug);


Future <List <Track>> fetchAlbumTracks(Album album, WidgetRef ref) async {
  var message = await Communicator().request('fetchalbumtracks', [album.directory]);

  //_logger.d('message: $message');
  try {
    List <dynamic> rawAlbumTracks = jsonDecode(message);
    List <Track> processedAlbumTracks = [];

    //_logger.d('rawAlbumTracks: $rawAlbumTracks');

    for (var raw in rawAlbumTracks) {
      processedAlbumTracks.add(rawTrack(raw));
      //_logger.d('retrieved and added albums');
    }
    _logger.d('processedAlbumTracks $processedAlbumTracks');
    ref.read(tracksProvider('albums').notifier).loadTracks(processedAlbumTracks);
    return processedAlbumTracks;

  } catch (e) {
    //_logger.e('exception: $e');
    rethrow;
  }

}

