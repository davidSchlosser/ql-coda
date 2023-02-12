import 'dart:convert';

import 'package:coda/models/track_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';


import '../communicator.dart';
import 'tags_model.dart';

bool tagsAreDifferent(List<Tag> tags, List<Tag> editTags) {
  Function eq = const DeepCollectionEquality().equals;
  return (!eq(tags, editTags));
}

final editedTagsProvider = StateNotifierProvider<EditTagsNotifier, List<Tag>>((ref) {  // ClipboardNotifier, List<Clipping>>
  return EditTagsNotifier();
});


class EditTagsNotifier  extends StateNotifier<List<Tag>>{
  EditTagsNotifier() : super([]);

  void add(Tag tag) {
    //_products.sorted((a, b) => a.name.compareTo(b.name));
    List<Tag> a = state;
    a.add(tag);
    a.sort((a, b) => a.name.compareTo(b.name));
    state = List.from(a);
    //state = [...state, EditTag(name:tag.name, value:tag.value)];
  }

  Tag remove(int index) {
    List<Tag> a = state;
    Tag removedTag = a.removeAt(index);
    state = List.from(a);
    return removedTag;
  }

  void replace(int index, Tag editTag) {  // add new tag if index is -1
    List<Tag> a = state;
    if (index < 0) {a.add(editTag);}  // new tag
    else { a[index] = editTag; }      // existing tag
    a.sort((a, b) => a.name.compareTo(b.name));
    state = List.from(a);
  }

  void replaceAll(List<Tag> tags) {
    tags.sort((a, b) => a.name.compareTo(b.name));
    state = List.from(tags);
  }

  void cloneTagAt(int index) {
    List<Tag> a = state;
    a.insert(index, a[index]);
    state = List.from(a);
  }

}

void saveEditedTags(List<Tag> editedTags, List<Track>tracks) {
  List<Tag> editableTags = editedTags.where((tag) => !tag.name.startsWith('~')).toList(); // don't edit Quodlibet internal tags

  List<String> trackFiles = tracks.map((track) => track.filename).toList();

  Map x = {
    'tags': editableTags,
    'tracks': trackFiles
  };

  Communicator().doRemote('replacetags', "'${jsonEncode(x)}'");
}