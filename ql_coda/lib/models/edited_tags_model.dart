

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tags_model.dart';

@immutable
class EditTag extends Tag {
  const EditTag({required String name, required String value}) : super(name: name, value: value);



}

bool tagsAreDifferent(List<Tag> tags, List<Tag> editTags) {
  if (editTags.length == tags.length) return false;
  if (editTags.hashCode ==tags.hashCode) return false;

  return true;
}

final editedTagsProvider = StateNotifierProvider<EditTagsNotifier, List<EditTag>>((ref) {  // ClipboardNotifier, List<Clipping>>
  return EditTagsNotifier();
});


class EditTagsNotifier  extends StateNotifier<List<EditTag>>{
  EditTagsNotifier() : super([]);

  void add(Tag tag) {
    //_products.sorted((a, b) => a.name.compareTo(b.name));
    List<EditTag> a = state;
    a.add(EditTag(name: tag.name, value:tag.value));
    a.sort((a, b) => a.name.compareTo(b.name));
    state = List.from(a);
    //state = [...state, EditTag(name:tag.name, value:tag.value)];
  }

  Tag remove(int index) {
    List<EditTag> a = state;
    Tag removedTag = a.removeAt(index);
    state = List.from(a);
    return removedTag;
  }

  void replace(int index, Tag tag) {  // add new tag if index is -1
    List<EditTag> a = state;
    EditTag editTag = EditTag(name: tag.name, value: tag.value);
    if (index < 0) {a.add(editTag);}  // new tag
    else { a[index] = editTag; }      // existing tag
    a.sort((a, b) => a.name.compareTo(b.name));
    state = List.from(a);
  }

  void replaceAll(List<Tag> tags) {
    List<EditTag> a = [...tags.map((e)=> EditTag(name: e.name, value: e.value))];
    a.sort((a, b) => a.name.compareTo(b.name));
    state = List.from(a);
  }

  void cloneTagAt(int index) {
    List<EditTag> a = state;
    a.insert(index, a[index]);
    state = List.from(a);
  }

}


