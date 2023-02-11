import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coda/models/track_model.dart';
import 'package:coda/communicator.dart';
import 'package:coda/logger.dart';
import 'package:logger/logger.dart';

Logger _logger = getLogger('collected_tracks_model', Level.warning);

final tracksProvider =
StateNotifierProvider.family<TracksNotifier, List<Track>, String>(
        (ref, sibling) {
      return TracksNotifier(sibling);   // 'queue', 'playlist' and 'album' browsers are siblings, each has multiple tracks
    });

final albumTracksProvider = StateNotifierProvider<TracksNotifier, List<Track>>((ref) {
  return TracksNotifier('albums');
});
final playlistTracksProvider = StateNotifierProvider<TracksNotifier, List<Track>>((ref) {
  return TracksNotifier('playlist');
});
final queueTracksProvider = StateNotifierProvider<TracksNotifier, List<Track>>((ref) {
  return TracksNotifier('queue');
});


class TracksNotifier extends StateNotifier<List<Track>> {
  String sibling;
  TracksNotifier(this.sibling): super([]);

  void loadTracks(List <Track> tracks) {
    state = [... tracks];
    _logger.d('state set: $tracks');
  }

}

void enQueueTrack(Track track) {
  Communicator().request('enqueue', [track.filename]);
}

void playTrack(Track track) {
  Communicator().request('playfile', [track.filename]);
}

final selectedTracksProvider = StateNotifierProvider<SelectedTracksNotifier, List<Track>>((ref) {
  return SelectedTracksNotifier();
});

class SelectedTracksNotifier extends StateNotifier<List<Track>> {
  SelectedTracksNotifier(): super([]);

  bool contains(Track track){
    bool ret = state.contains(track);
    return ret;
  }
  
  void toggle(Track track) {
    this.contains(track) ? remove(track) : add(track);
  }
  
  void add(Track track){
    List<Track> a = state;
    if (!a.contains(track)) {
      a.add(track);
      state = List.from(a);
    };
  }
  
  void remove(Track track){
    List<Track> a = state;
    a = [
      for (final _track in a)
        if (track !=_track) _track,
    ];
    state = List.from(a);
  }
  
  void clear(){
    state = [];
  }
  
  bool isEmpty() {
    return state.isEmpty;
  }
  
  List<Track> tracks() {
    List <Track> trax = state.fold<List<Track>>([], (nlist, track) {
      nlist.add(track);
      return nlist;
    });
    return trax;
  }

  void enQueueSelectedTracks() {
    for (Track track in state) {
      Communicator().request('enqueue', [track.filename]);
    }
  }

  void selectAll(List<Track> tracks){
    state = [...tracks];  // overwrite any that were already there
  }

}