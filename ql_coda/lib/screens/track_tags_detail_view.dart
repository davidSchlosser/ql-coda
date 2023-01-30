import 'package:coda/models/clipboard_model.dart';
import 'package:coda/models/tags_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/edited_tags_model.dart';
import 'package:logger/logger.dart';
import 'package:coda/logger.dart';

import 'edit_single_tag_view.dart';

Logger _logger = getLogger('edit_tags_details_view', Level.warning);

class EditTagsDetails extends ConsumerWidget {
  const EditTagsDetails({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<Tag> editTags = ref.watch(editedTagsProvider);
    List<Clipping> clipboard = ref.watch(clipboardProvider);
    _logger.d('Clipboard count: ${clipboard.length}'); // force build when clipboard changes
    _logger.d('EditTagsDetails building');
    return Expanded(
        child: SizedBox(
            height: MediaQuery.of(context).size.height - 285,
            width: MediaQuery.of(context).size.width,
            child: ListView.builder(
                itemCount: editTags.length,
                shrinkWrap: true,
                itemBuilder: (BuildContext context, int index) {
                  Tag tag = editTags[index];
                  _logger.d('itembuilder: $tag');
                  return Row(
                    children: <Widget>[
                      Expanded(
                        child: InkWell(
                          child: Slidable(
                            key: ObjectKey(tag),
                            startActionPane: tag.name.startsWith('~')
                                ? null // internal tag
                                : ActionPane(
                                    motion:
                                        const BehindMotion(), //ScrollMotion(),
                                    extentRatio: 0.7,
                                    children: [
                                      SlidableAction(
                                        onPressed: (BuildContext context) {
                                          //remove the tag;
                                          //Tag removedTag = editTags.removeAt(index);
                                          Tag removedTag = ref
                                              .read(editedTagsProvider.notifier)
                                              .remove(index);
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text(
                                                    "${removedTag.name} will be removed"),
                                                action: SnackBarAction(
                                                    label: "ADD IT BACK",
                                                    onPressed: () {
                                                      _logger.d(
                                                          "SnackBar Action, onPressed");
                                                      editTags.add(removedTag);
                                                      ref
                                                          .read(
                                                              editedTagsProvider
                                                                  .notifier)
                                                          .add(removedTag);
                                                    })),
                                          );
                                        },
                                        backgroundColor:
                                            const Color(0xFFFE4A49),
                                        foregroundColor: Colors.white,
                                        icon: Icons.delete,
                                        label: 'Remove',
                                      ),
                                      SlidableAction(
                                        onPressed: (BuildContext context) {
                                          //edit the tag;
                                          Navigator.push(context, EditSingleTagPopup(tagIndex: index));
                                          /*GoRouter.of(context).push(
                                              '/editSingleTag',
                                              extra: index);*/
                                        },
                                        backgroundColor:
                                            const Color(0xFF21B7CA),
                                        foregroundColor: Colors.white,
                                        icon: Icons.edit,
                                        label: 'Edit',
                                      ),
                                      SlidableAction(
                                        onPressed: (BuildContext context) {
                                          //duplicate the tag;
                                          ref
                                              .read(editedTagsProvider.notifier)
                                              .cloneTagAt(index);
                                        },
                                        backgroundColor:
                                            const Color(0xFF21B7CA),
                                        foregroundColor: Colors.white,
                                        icon: Icons.edit,
                                        label: 'Duplicate',
                                      ),
                                      SlidableAction(
                                        onPressed: (BuildContext context) {
                                          // copy the tag to the clipboard
                                          if (ref.watch(clipboardProvider.notifier).contains(tag)) {
                                            ref.read(clipboardProvider.notifier)
                                                .remove(tag);
                                          } else {
                                            ref
                                                .read(
                                                    clipboardProvider.notifier)
                                                .add(tag);
                                          }
                                        },
                                        backgroundColor:
                                            const Color(0xFF4CAF50),
                                        foregroundColor: Colors.white,
                                        icon: (ref.watch(clipboardProvider.notifier).contains(tag))
                                            ? Icons.remove
                                            : Icons.attach_file,
                                        label: (ref
                                                .watch(
                                                    clipboardProvider.notifier)
                                                .contains(tag))
                                            ? 'Unclip'
                                            : 'Clip',
                                      ),
                                    ],
                                  ),
                            child: Card(
                              color: tag.name.startsWith('~') // internal tag
                                  ? null
                                  : Colors.teal[50],
                              child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: //ListTile(title: Text('${tag.value}'), subtitle: Text('${tag.name}')),
                                      Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: <Widget>[
                                        Text(
                                          tag.name,
                                          style: TextStyle(
                                              fontWeight: ref.watch(clipboardProvider.notifier).contains(tag)
                                                  ? FontWeight.w600
                                                  : FontWeight.w300,
                                              fontSize: 12.0),
                                        ),
                                        const Padding(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 2.0)),
                                        Text(
                                          tag.value,
                                          style: TextStyle(
                                            fontWeight: ref.watch(clipboardProvider.notifier).contains(tag)
                                                ? FontWeight.bold
                                                : FontWeight.w400,
                                            fontSize: 16.0,
                                          ),
                                        ),
                                      ])),
                            ),
                          ),
                          /*DisplayTag( tag: tag, inClipboard: clipboard.contains(tag)),*/
                        ),
                      ),
                    ],
                  );
                })
            //return const SizedBox.shrink();
            ));
  }
}
