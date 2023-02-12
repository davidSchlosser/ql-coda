import 'dart:convert';
import 'dart:io';
import 'package:coda/logger.dart';
import 'package:coda/models/track_model.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:coda/communicator.dart';

Logger _logger = getLogger('Tags', Level.warning);

enum FileTagOp { append, replace, remove }

class Tag extends Equatable {
  final String name;
  final String value;

  @override
  List<Object> get props => [name, value];

  const Tag({required this.name, required this.value});

  Map<String, dynamic> toJson() => {
    'name': name,
    'value': value,
  };
}

final tagsProvider = StateProvider<List<Tag>>((ref) {
  return [];
});

class Tags extends Equatable {
  final List<Tag> tags;

  const Tags(this.tags);

  @override
  List<Object> get props => [tags];

  @override
  String toString() {
    String s = '';
    for (var tag in tags) {
      s += '${tag.name} = ${tag.value}, ';
    }
    return s;
  }

  /*String _sanitise(String s) {
    // standardise the quote marks - iOS is a culprit
    s = s.replaceAll(RegExp('["”]'), '\\\\\\"');
    s = s.replaceAll(RegExp('’'), '\'');
    return s;
  }*/
}

Future<Tags> fetchTrackTags(Track track, WidgetRef ref) async {
  final List<Tag> tags = [];

  String exportTags =
      await Communicator().request('exporttags', [track.filename]);
  _logger.d('exportTags: $exportTags');
  try {
    Map t = jsonDecode(exportTags);
    t.forEach((key, value) {
      _logger.d('tag: $key: $value');
      tags.add( Tag(name: key, value: value.toString()));});
    /*for (var tag in t) {
      tags.add(Tag(name: tag[0], value: tag[1]));
    }*/
    _logger.d('fetchTrackTags: $tags');
    ref.read(tagsProvider.notifier).state = tags;

    return Tags(tags);
  } catch (e) {
    _logger.d('fetchTrackTags exception: $e');
    rethrow;
  }
}

class TagCache {
  static Map<String, List<String>> cache = {};

  TagCache() {
    if (cache.isEmpty) {
      reloadCacheFromLocalFile();
    }
  }
  Map get tagCache => cache;
  List<String> get cacheNames =>
      cache.keys.toList(); // [ for (String k in cache.keys) k.toString()];

  List<String> valuesFor(String tagName) {
    if (!cache.containsKey(tagName)) {
      if (tagName.startsWith('performer')) {
        tagName = 'artist';
      }
    }
    return (cache.containsKey(tagName)) ? cache[tagName]! : [];
  }

  // cache file is in json
  //
  Future reloadCacheFromLocalFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final File tagCacheFile = File('${directory.path}/tag_cache.txt');

    cache.clear();
    _logger.d('Log file is at ${directory.path}');
    if (await tagCacheFile.exists()) {
      await tagCacheFile.readAsString().then((message) {
        cache = textToCache(message);
        cache['albumartist'] = cache['artist']!;
        cache['albumartistsort'] = cache['artist']!;
        _logger.d('Reloaded cache from local file');
      });
    }
  }

  // T_ODO do this in an isolate
  Future<bool> rebuildFromQl() async {
    //Map<String, List<String>>  tagvalues;
    final directory = await getApplicationDocumentsDirectory();
    final File tagCacheFile = File('${directory.path}/tag_cache.txt');

    cache = {};
    if (await tagCacheFile.exists()) {
      _logger.d('Delete local cache file');
      tagCacheFile.delete();
    }

    await Communicator().request('tagvalues').then((message) {
      _logger.d('retrieved tags');
      _logger.d('message: $message');
      tagCacheFile.writeAsString(message, mode: FileMode.append, flush: true);
      cache = textToCache(message);
    });

    cache['albumartist'] = cache['artist']!;
    cache['albumartistsort'] = cache['artist']!;

    return true;
  }

  Map<String, List<String>> textToCache(String message) {
    final Map<String, List<String>> cache = {};

    Map<String, dynamic> rawCacheMap = const JsonDecoder().convert(message);

    rawCacheMap.forEach((key, value) {
      List<String> tags = [];

      value.forEach((element) {
        tags.add(element.toString());
      });
      cache[key] = tags;
    });
    return cache;
  }
}

