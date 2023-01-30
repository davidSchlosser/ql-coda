import 'dart:convert';

import 'package:coda/models/track_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coda/communicator.dart';
import 'package:coda/logger.dart';
import 'package:logger/logger.dart';

import 'collected_tracks_model.dart';

Logger _logger = getLogger('queue_model', Level.warning);

Future<List<Track>> fetchQueuedTracks(WidgetRef ref) async {
  var message = await Communicator().request('fetchqueue');

  _logger.w('fetchQueuedTracks: ${ref.read(tracksProvider('queue'))}');
  //_logger.d('message: $message');
  try {
    //var rawQueuedTracks = jsonDecode(message);
    //List <dynamic> rawQueuedTracks = jsonDecode(message).cast<Map <String, dynamic>>()
    List<dynamic> rawQueuedTracks = jsonDecode(message);
    List<Track> processedQueuedTracks = [];

    //_logger.d('rawQueuedTracks: $rawQueuedTracks');

    for (var raw in rawQueuedTracks) {
      processedQueuedTracks.add(rawTrack(raw));
      //_logger.d('retrieved and added albums');
    }
    _logger.d('processedQueuedTracks $processedQueuedTracks');
    ref
        .read(tracksProvider('queue').notifier)
        .loadTracks(processedQueuedTracks);
        //.loadQueuedTracks(processedQueuedTracks);
    return processedQueuedTracks;
  } catch (e) {
    //_logger.e('exception: $e');
    rethrow;
  }
}

void emptyQueue(WidgetRef ref) {
  Communicator().request('clearqueue', []);
  ref.read(tracksProvider('queue').notifier).loadTracks([]);
  //ref.read(queuedTracksProvider.notifier).loadQueuedTracks([]);
  _logger.d('cleared queue');
}

void unQueue(String fileName, WidgetRef ref) {
  final List<Track> processedQueue = ref.watch(tracksProvider('queue'));

  processedQueue.removeWhere((track) => track.filename == fileName);
  Communicator().request('unqueue', [fileName]);

  /*for (var track in processedQueue) {
    if (track.filename == fileName) {
      Communicator().request('unqueue', [fileName]);
      processedQueue.remove(track);
    }
  }*/
  ref.read(tracksProvider('queue').notifier).loadTracks(processedQueue);
  //ref.read(queuedTracksProvider.notifier).loadQueuedTracks(processedQueue);
  _logger.d('unqueue loaded $processedQueue');
}
