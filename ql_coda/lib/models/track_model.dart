import 'package:coda/models/tags_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final trackProvider = StateProvider<Track>((ref) {
  return const Track([]);
});


final editTracksProvider = StateProvider<List <Track>>((ref) {
  return [];
});


@immutable
class Track {
  final List <Tag> tags; // tracks can have multiple tags with same name!

  const Track(this.tags);

  String getTag(tagName) {
    try {
      Tag match = tags.firstWhere((tag) => tag.name == tagName);
      return match.value;
    }
    catch (_) {
      return '';
    }
  }

  String get albumName { return getTag('album');}
  String get trackNumber { return getTag('tracknumber');}
  String get artist { return getTag('artist');}
  String get filename {return getTag('~filename');}
  String get grouping { return getTag('grouping'); }
  String get title { return getTag('title'); }
  int get length {
    return getTag('~#length') == '' ? 0 : double.parse(getTag('~#length')).toInt();
  }

  @override
  String toString() {
    return '$trackNumber: ${grouping.isNotEmpty ? "$grouping " : ""} $title\n$artist$albumName'; //'title: $title\nartist: $artist\nalbum: $album'
  }
}

Track rawTrack(Map<String, dynamic> raw) {
  List<Tag> processedTags = [];
  raw.forEach((tag, rawValue) {
      processedTags.add(Tag(name:tag, value: rawValue.toString()));
  });
  return Track(processedTags);
}

/*  example track
    {
      "album": "Art Blakey's Jazz Messengers with Thelonious Monk [Deluxe Edition]",
      "artist": "Art Blakey's Jazz Messengers",
      "comment": "exystence.net",
      "copyright": "? 2022 Atlantic Recording Corporation.",
      "date": "2022",
      "genre": "Jazz",
      "organization": "Atlantic/Rhino",
      "performer": "Art Blakey",
      "title": "Purple Shades (Take 4) [with Thelonious Monk] [2022 Remaster]",
      "tracknumber": "12",
      "~#added": 1671770047,
      "~#bitrate": 320,
      "~#channels": 2,
      "~#filesize": 17383355,
      "~#length": 432.4946258503401,
      "~#mtime": 1653358682,
      "~#samplerate": 44100,
      "~encoding": "LAME 3.99.1+\nCBR\n-b 320",
      "~filename": "/media/david/StarTechcom8Tb/qlMusic/Art Blakey - Art Blakey's Jazz Messengers with Thelonious Monk [Deluxe Edition] (2022)/12 - Purple Shades (Take 4) [with Thelonious Monk] [2022 Remaster].mp3",
      "~format": "MP3",
      "~mountpoint": "/media/david/StarTechcom8Tb",
    "~picture": "y"
    }*/

