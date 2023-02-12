import 'package:coda/models/tags_model.dart';
import 'package:coda/models/track_model.dart';
//import 'package:coda/models/track_model.dart';
import 'package:flutter/foundation.dart';
//import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:coda/logger.dart';

import 'edited_tags_model.dart';

Logger _logger = getLogger('clipboard_model', Level.info);

// Clipboard is a map of clippings - each clipping is a tag (name & value),
// with an op to indicate the tag is to be added (op=true) or deleted (false)

final clipboardProvider = StateNotifierProvider<ClipboardNotifier, List<Clipping>>((ref) {
  return ClipboardNotifier();
});

@immutable
class Clipping {
  final Tag tag;
  final bool op;

  Clipping(this.tag, this.op);
}

class ClipboardNotifier extends StateNotifier<List<Clipping>>{
  ClipboardNotifier() : super([]);

  void add(Tag tag, [bool op = true]){
    List<Clipping> a = state;
    a.add(Clipping(tag, op));
    state = List.from(a);
  }

  void remove(Tag tag) {
    List<Clipping> a = state;
    a = [
      for (final clipping in a)
        if (tag !=clipping.tag) clipping,
    ];
    state = List.from(a);
  }

  void toggle(Tag tag) {
    state = [
      for (final clipping in state)
        (tag == clipping.tag) ? Clipping(clipping.tag, !clipping.op) : clipping,
    ];
  }

  bool contains(Tag tag) {
    return -1 != state.indexWhere((element) => element.tag == tag);
  }

  void clear() {
    state = [];
  }

  Tags tags() {
    List <Tag> tags = state.fold<List<Tag>>([], (nlist, element) {
      nlist.add(element.tag);
      return nlist;
    });
    return Tags(tags);
  }

  bool isEmpty() {
    return state.isEmpty;
  }

  @override
  String toString() {
    String rtn = '';
    for (var entry in state) {
      rtn += '${entry.tag.name} - ${entry.op}';
    }
    return rtn;
  }

  //void apply(List<String> songFiles) {
  void apply(List<Track> tracks) {
    List<Clipping> clippings = state;

    List<Tag> addTags = [];
    List<Tag> removeTags = [];

    clippings.forEach((clipping) {
      if (clipping.op) { addTags.add(clipping.tag); }
      else {removeTags.add(clipping.tag);}
    });

    try {
      if (addTags.isNotEmpty) {
        addEditedTags(addTags, tracks);
      }
      if (removeTags.isNotEmpty) {
        removeEditedTags(removeTags, tracks);
      }
    } on Exception catch (e) {
      print('apply failed: $e');
    }
  }

}


