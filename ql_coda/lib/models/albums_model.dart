import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coda/communicator.dart';
import 'package:coda/logger.dart';
import 'package:logger/logger.dart';

Logger _logger = getLogger('albums_model', Level.warning);

final albumsProvider = StateNotifierProvider<AlbumsNotifier, List<Album>>((ref) {
  return AlbumsNotifier();
});

final albumProvider = StateProvider<Album>((ref) {
  return const Album(albumName:'', artists:[], dates:[], genres:[], styles:[], moods:[], directory:'');
});

@immutable
class Album {

  const Album(
      { required this.albumName, required this.artists, required this.dates, required this.genres, required this.styles, required this.moods, required this.directory });

  final String albumName; // "Left of Cool",
  final Iterable<String> artists; // ["Béla Fleck","The Flecktones"],
  final Iterable<String> dates; // ["1998"],
  final Iterable<String> genres; // ["Jazz"],
  final Iterable<String> styles; // ["Fusion","Cool"],
  final Iterable<String> moods; // ["moderate","dynamic"],
  final String directory; // "/media/david/StarTechcom8Tb/qlMusic/Béla Fleck & The Flecktones - 1998, Left of Cool/",

  @override
  String toString() {
    return '$albumName\n';
  }

  static Album rawAlbum(Map<String, dynamic> raw) {
    //_logger.d('rowAlbum: $raw');
    Album a = Album(
        albumName: (raw.containsKey('album')) ? raw['album'] : '',
        directory: (raw.containsKey('directory')) ? raw['directory'] : '',
        artists: (raw.containsKey('artists')) ? List<String>.from(raw['artists']) : [],      //type 'List<dynamic>' is not a subtype of type 'List<String>'
        dates: (raw.containsKey('dates')) ? List<String>.from(raw['dates']) : [],
        genres: (raw.containsKey('genres')) ? List<String>.from(raw['genres']) : [],
        styles: (raw.containsKey('styles')) ? List<String>.from(raw['styles']) : [],
        moods: (raw.containsKey('moods')) ? List<String>.from(raw['moods']) : []
    );
    //_logger.d('album: $a');
    return a;
  }

  String value(tagName) {
    switch (tagName) {
      case 'title': return albumName;
      case 'genre': return genres.join();
      case 'date': return dates.join();
      case 'style': return styles.join();
      case 'mood': return moods.join();
      case 'artist':  return artists.join();
    }
    String errorMsessage = 'unknown sort value: $tagName';
    _logger.e(errorMsessage);
    throw Exception(errorMsessage);
  }

}

class AlbumsNotifier extends StateNotifier<List<Album>> {
  AlbumsNotifier(): super([]);

  void loadAlbums(List <Album> albums) {
    state = [... albums];
    _logger.d('state set: $albums');
  }

}

void sortAlbums(String sortTagName, WidgetRef ref){
  final List<Album> albums = ref.watch(albumsProvider);
  var processedAlbums = albums;

  processedAlbums.sort((albumA, albumB) => albumA
      .value(sortTagName)
      .compareTo(albumB.value(sortTagName)));
  ref.read(albumsProvider.notifier).loadAlbums(processedAlbums);
  _logger.d('sort loaded as $albums');

}

Future <List <Album>> fetchAlbumsMatchingQuery(String query, WidgetRef ref) async {
  _logger.d('query: $query');
  var message = await Communicator().request('queryalbums', [query]);

  //_logger.d('message: $message');
  try {
    List <dynamic> rawAlbums = jsonDecode(message).cast<Map <String, dynamic>>();
    List <Album> processedAlbums = [];

    //_logger.d('rawAlbums: $rawAlbums');

    for (var raw in rawAlbums) {
      processedAlbums.add(Album.rawAlbum(raw));
      //_logger.d('retrieved and added albums');
    }
    _logger.d('processedAlbums $processedAlbums');
    ref.read(albumsProvider.notifier).loadAlbums(processedAlbums);
    return processedAlbums;

  } catch (e) {
    //_logger.e('exception: $e');
    rethrow;
  }

}
