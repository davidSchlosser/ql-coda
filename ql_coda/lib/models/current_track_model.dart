import 'dart:async';
import 'dart:math';

import 'package:coda/logger.dart';
import 'package:coda/models/track_model.dart';
import 'package:coda/streams/current_track_stream.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:logger/logger.dart';
import 'dart:convert';

Logger _logger = getLogger('Current track model', Level.warning);

final nowPlayingTrackModelProvider = StreamProvider<CurrentTrackModel>((ref) {
  StreamController<CurrentTrackModel> streamController =
      CurrentTrackStream.currentTrackStreamController;
  return streamController.stream;
});

class CurrentTrackModel {
  Track track = rawTrack({});
  String genre = '';
  String style = '';
  String title = '';
  String album = '';
  List <String> performers = [];
  String composer = '';
  String length = '';
  String artist = '';
  String grouping = '';
  String version = '';
  String disc = '';
  String discsubtitle = '';
  String trackNumber = '';
  String mood = '';
  String date = '';
  String file = '';
  String labelid = '';

  CurrentTrackModel({
    //this.primaryIdentity = '',
    this.genre = '',
    this.style = '',
    this.title = 'none playing',
    this.album = '',
    this.performers = const [],
    this.composer = '',
    this.length = '',
    this.artist = '',
    this.grouping = '',
    this.version = '',
    this.disc = '',
    this.discsubtitle = '',
    this.trackNumber = '',
    this.mood = '',
    this.date = '',
    this.file = '',
    this.labelid = '',
  });

  CurrentTrackModel.fromString(String trackMsg) {
    genre = '';
    style = '';
    title = '';
    album = '';
    performers = [];
    composer = '';
    length = '';
    artist = '';
    grouping = '';
    version = '';
    disc = '';
    discsubtitle = '';
    trackNumber = '';
    mood = '';
    date = '';
    file = '';
    labelid = '';

    Map<String, dynamic> rawNowPlaying =
        (trackMsg.isNotEmpty) ? jsonDecode(trackMsg) : {};
    track = rawTrack(rawNowPlaying);

    rawNowPlaying.forEach((key, value) {
      List<String> tokens = [key, value.toString()];

      switch (tokens[0]) {
        case 'genre':
          genre = tokens[1];
          break;

        case 'style':
          style = tokens[1];
          break;

        case 'title':
          title = tokens[1];
          break;

        case 'album':
          album = tokens[1];
          break;

        /*case 'performers':
          performers = tokens[1];
          break;*/

        case 'composer':
          composer = tokens[1];
          break;

        case '~#length':
          length = tokens[1];
          break;

        case 'artist':
          artist = tokens[1];
          break;

        case 'grouping':
          grouping = tokens[1];
          break;

        case 'version':
          version = tokens[1];
          break;

        case 'disc':
          disc = tokens[1];
          break;

        case 'discsubtitle':
          discsubtitle = tokens[1];
          break;

        case 'track':
          trackNumber = tokens[1];
          break;

        case 'mood':
          mood = tokens[1];
          break;

        case 'date':
          date = tokens[1];
          break;

        case 'file':
          file = tokens[1];
          break;

        case 'labelid':
          labelid = tokens[1];
          break;

        default:
          if (tokens[0].startsWith('performer:')) {  // eg ['performer:banjo',Béla Fleck]
            performers.add( '${tokens[1]} (${tokens[0].substring(10)})');
          }
          break;
      }
    });
  }

  @override
  String toString() {
    return (track.toString());
  }

  String header() {
    bool isClassical = genre.startsWith('Classical');
    String primaryIdentity = isClassical ? composer : artist;

    return
        //"${ primaryIdentity.isNotEmpty ?  primaryIdentity + ': ' : ''}${ grouping.isNotEmpty ?  grouping + ' - ' : ''}${ title}";
        "${primaryIdentity.isNotEmpty ? '$primaryIdentity: ' : ''}${grouping.isNotEmpty ? '$grouping - ' : ''}$title";
  }

  String subheader() {
    bool isClassical = genre.startsWith('Classical');
    return "${version.isEmpty ? '' : '$version '}${!isClassical & composer.isNotEmpty ? '($composer)' : ''}";
  }

  String byArtist() {
    bool isClassical = genre.startsWith('Classical');
    return isClassical & artist.isNotEmpty ? 'by $artist' : '';
  }

  List<String> withPerformers() {
    /*List<String> performerRoles = [];
    RegExp re = RegExp(r"([^,(]*\([^)]*\))*[^,]*(,|$)");
    List l = re.allMatches(performers).toList();
    for (Match e in l) {
      String s0 = e.group(0)!.trimLeft();

      // strip trailing ','
      String s1 = s0.isNotEmpty && s0.endsWith(',')
          ? s0.substring(0, s0.length - 1)
          : s0;

      _logger.d('performer role: $s1');
      performerRoles.add(s1);
    }
    */
    return performers;
  }

  String summary() {
    return "${album.isNotEmpty ? album : ''}${disc.isNotEmpty ? '- disc $disc' : ''}${discsubtitle.isNotEmpty ? ', $discsubtitle' : ''}${trackNumber.isNotEmpty ? ' - Track $trackNumber ' : ''}${length.isNotEmpty ? (length) : ''}${date.isEmpty ? '' : ' $date'}${genre.isNotEmpty ? ', $genre' : ''}${style.isNotEmpty ? ', $style' : ''}${mood.isNotEmpty ? ', $mood' : ''}";
  }

  double lengthInSeconds() {
    if (length.isEmpty) return 0.0;
    // Quodlibet uses charcode 8758 as its time separator!
    var tI = length.split(String.fromCharCode(8758)).reversed;
    var i = 0;
    var t = 0.0;
    for (var tp in tI) {
      t += (double.parse(tp) * pow(60, i++));
    }
    return t;
  }
}
