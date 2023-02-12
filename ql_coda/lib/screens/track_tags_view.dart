import 'package:coda/logger.dart';
import 'package:coda/models/clipboard_model.dart';
import 'package:coda/models/tags_model.dart';
import 'package:coda/models/track_model.dart';
import 'package:coda/screens/ui_util.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/edited_tags_model.dart';
import 'assemble_route.dart';
import 'clipboard_tags_view.dart';
import 'common_scaffold.dart';
import 'edit_single_tag_view.dart';
import 'track_tags_detail_view.dart';

Logger _logger = getLogger('edit_tags_view', Level.warning);

class EditTagsView extends ConsumerStatefulWidget {
  const EditTagsView({super.key});

  @override
  ConsumerState<EditTagsView> createState() => EditTagsViewState();
}

class EditTagsViewState extends ConsumerState<EditTagsView> {
  late Track track;
  List<Track> editTracks = [];
  late int editTracksIndex;
  List<Tag>? initialTrackTags;

  @override
  initState() {
    super.initState();

    //get the tags for the current track
    track = ref.read(trackProvider);
    syncTags();

    // get the list of tracks we came from - for next/prior
    editTracks = ref.read(editTracksProvider);
    editTracksIndex =
        editTracks.indexWhere((trk) => trk.filename == track.filename);
  }

  void syncTags() {
    fetchTrackTags(track, ref).then((value) {
      initialTrackTags = value.tags;
      ref
          .read(editedTagsProvider.notifier)
          .replaceAll(value.tags); //state = value.tags as List<EditTag>;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Tag> tags = ref.watch(editedTagsProvider);
    _logger.d('EditTagsView building');

    void saveTags(){
      List<Tag> editedTags = ref.read(editedTagsProvider);
      saveEditedTags(editedTags, [track]);
      initialTrackTags = editedTags.toList();
      _logger.d('save tags');
    }

    return WillPopScope(
      onWillPop: () {
        return (track != editTracks[editTracksIndex])
            ? isItOkToLoseChanges(context)
            : Future.value(true);
      },
      child: CommonScaffold(
          title: 'Tags',
          floatingActionButton: FloatingActionButton.extended(
            label: const Text('Add tag'),// add new tag
            onPressed: () {
              Navigator.push(context, EditSingleTagPopup(tagIndex: -1));  // not an existing or clipbaord tag
              // EditSingleTagView(tagIndex: -1); // not an existing or clipbaord tag
            },
            backgroundColor: Colors.green,
            icon: const Icon(Icons.add),
          ),
          popupMenu: PopupMenuButton(
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                onTap: () => saveTags(),
                child: const Text('Save tag changes to track'),
              ),
              PopupMenuItem(
                onTap: () => {},
                child: const Text('Clip selected tags'),
              ),
              PopupMenuItem(
                onTap: () => {},
                child: const Text('Unclip selected tags'),
              ),
              PopupMenuItem(
                onTap: () => {},
                child: const Text('Select all'),
              ),
              PopupMenuItem(
                onTap: () => {},
                child: const Text('Deselect all'),
              ),
              PopupMenuItem(
                onTap: () {
                  var clipboard = ref.watch(clipboardProvider.notifier);
                  clipboard.apply([track]);
                  syncTags();
                  },
                child: const Text('Apply clipped edits'),
              ),
            ],
          ),
          child: Column(
            children: [
              //
              // display track list summary queue, playlist, album tracks, with option to get prior or next track's tags
              //
              Card(
                child: Column(
                  //mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4.0, vertical: 5.0),
                      child: Consumer(builder: (context, ref, child) {
                        track = ref.watch(trackProvider);
                        return ListTile(
                            title: Text(track.title),
                            subtitle: Text(
                                'Track ${track.trackNumber}/${editTracks.length} has ${ref.watch(editedTagsProvider).length} tags (${ref.watch(clipboardProvider).length} clipped)'),
                            leading: const Icon(
                              Icons.insert_drive_file,
                              size: 18.0,
                            ));
                      }),
                    ),

                    Row(
                      children: [
                        ButtonBar(
                            alignment: MainAxisAlignment.start,
                            children: [
                              ElevatedButton.icon(
                                icon: const Icon(Icons.attach_file),
                                  onPressed: (){
                                  // display the tags in the clipboard
                                  Navigator.push(context, AssembleRoute(
                                    builder: (context) {
                                      return ClipboardView(
                                        title: 'Clipboard',
                                        onDone: (_){},
                                      );
                                    },
                                  ));},
                                  label: const Text('Clipboard'),
                              ),
                              initialTrackTags != null && tagsAreDifferent(initialTrackTags!, tags)
                              ? ElevatedButton.icon(
                                icon: const Icon(Icons.save),
                                onPressed: () => saveTags(),
                                label: const Text('Save'),
                              )
                                  : const NilWidget(),
                            ]),
                        const Spacer(),
                        (editTracks.length > 1)
                            ? ButtonBar(
                                alignment: MainAxisAlignment.end,
                                children: <Widget>[
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.skip_previous),
                                      onPressed: (editTracksIndex > 0)
                                          ? () {
                                              moveTo(context, track, -1);
                                            }
                                          : null,
                                      label: const Text('Previous'),
                                    ),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.skip_next),
                                      onPressed: (editTracksIndex <
                                              editTracks.length - 1)
                                          ? () {
                                              moveTo(context, track, 1);
                                            }
                                          : null,
                                      label: const Text('Next'),
                                    )
                                  ])
                            : const NilWidget()
                      ],
                    )
                  ],
                ),
              ),
              //
              // listview of tag tiles - slide to delete, copy, edit
              //
              const EditTagsDetails(),
            ],
          )),
    );
  }

  Future moveTo(context, Track track, int direction) async {
    // move to tags of next/prior track
    // warn if changes might be lost
    //
    bool itsOkToMove = true;
    List<Tag> tags = ref.read(editedTagsProvider);
    if (tagsAreDifferent(initialTrackTags!, tags)) {
      // if (tags != initialTrackTags) {
      // tags were edited
      itsOkToMove = await isItOkToLoseChanges(context);
    }
    if (itsOkToMove) {
      int newIndex = editTracksIndex + direction;
      if ((0 <= newIndex) & (newIndex < editTracks.length)) {
        track = editTracks[newIndex];
        editTracksIndex = newIndex;
        ref.read(trackProvider.notifier).state = track;
        fetchTrackTags(track, ref).then((value) {
          initialTrackTags = value.tags;
          ref.read(editedTagsProvider.notifier).replaceAll(value.tags);
          //ref.read(editedTagsProvider.notifier).state = value.tags as List<EditTag>;
        });
      }
    }
  }

  // check wheiher it's ok to lose the unsaved tag edits
  //
  Future<bool> isItOkToLoseChanges(context) async {
    bool ret = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Please confirm'),
        content: const Text('Do you want to lose the changes?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    return (ret);
  }
}
