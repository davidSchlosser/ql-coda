import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import '../models/collected_tracks_model.dart';
import '../models/player_model.dart';
import '../models/track_model.dart';
import 'common_scaffold.dart';
import 'package:coda/logger.dart';
import 'package:logger/logger.dart';

Logger _logger = getLogger('album_tracks_view', Level.debug);

// TODO menu: analyse player credits

class TracksView extends ConsumerStatefulWidget {
  final String title;
  final PopupMenuButton popupMenu;
  final bool canPlay;
  final bool canQueue;
  final bool canDequeue;
  final bool canEditTags;
  final String sibling;

  const TracksView(this.title, this.popupMenu,
      {this.canPlay = true,
      this.canQueue = true,
      this.canDequeue = false,
      this.canEditTags = true,
      this.sibling = 'albums',
      super.key});

  @override
  ConsumerState<TracksView> createState() => _TracksViewState();
}

class _TracksViewState extends ConsumerState<TracksView> {
  @override
  Widget build(BuildContext context) {
    _logger.d('building tracks view');
    ScrollController scrollController = ScrollController();
    final List<Track> tracks = ref.watch(tracksProvider(widget.sibling));
    List<Track> selectedTracks = ref.watch(selectedTracksProvider); // needed for forcing build
    Track? nowPlayingTrack = ref.watch(nowPlayingTrackModelProvider).value?.track;

    return CommonScaffold(
        title: widget.title,
        // queue selected tracks, update selected tracks with tags from clipboard, select all, uncselect all, view clipboard, reset from server, analyse player credits
        popupMenu: widget.popupMenu,
        child: ListView.builder(
          controller: scrollController,
          itemCount: tracks.length,
          itemExtent: 100,
          shrinkWrap: true,
          itemBuilder: (BuildContext context, int index) {
            Track track = tracks[index];
            return Slidable(
              key: ObjectKey(track),
              startActionPane: ActionPane(
                motion: const ScrollMotion(),
                children: [
                  if (widget.canPlay) ...[
                    SlidableAction(
                      onPressed: (BuildContext context) {
                        playTrack(track);
                      },
                      backgroundColor: const Color(0xFFFE4A49),
                      foregroundColor: Colors.white,
                      icon: Icons.play_arrow,
                      label: 'Play',
                    )
                  ],
                  if (widget.canQueue) ...[
                    SlidableAction(
                      onPressed: (BuildContext context) {
                        enQueueTrack(track);
                      },
                      backgroundColor: const Color(0xFF21B7CA),
                      foregroundColor: Colors.white,
                      icon: Icons.playlist_add,
                      label: 'Queue',
                    )
                  ],
                  if (widget.canDequeue) ...[
                    SlidableAction(
                      onPressed: (BuildContext context) {
                        enQueueTrack(track);
                      },
                      backgroundColor: const Color(0xFF21B7CA),
                      foregroundColor: Colors.white,
                      icon: Icons.playlist_remove,
                      label: 'Unqueue',
                    )
                  ],
                  if (widget.canEditTags) ...[
                    SlidableAction(
                      onPressed: (BuildContext context) {
                        ref.read(editTracksProvider.notifier).state = tracks;
                        ref.read(trackProvider.notifier).state = track;
                        context.go('/edittags');
                      },
                      backgroundColor: const Color(0xFF21B7CA),
                      foregroundColor: Colors.white,
                      icon: Icons.label_rounded,
                      label: 'Tags',
                    )
                  ],
                ],
              ),
              child: Card(
                child: Builder(builder: (context) {
                  return CheckboxListTile(
                    key: UniqueKey(),
                    title: Text(
                        style: TextStyle(
                            fontWeight:
                                nowPlayingTrack?.filename == track.filename ? FontWeight.bold : FontWeight.normal),
                        (track.grouping.isNotEmpty ? "$track.grouping " : '') + track.title),
                    subtitle: Text(
                        style: TextStyle(
                            fontWeight:
                            nowPlayingTrack?.filename == track.filename ? FontWeight.bold : FontWeight.normal),
                        'Track ${track.trackNumber}, ${track.artist}: ${track.albumName}'),
                    isThreeLine: true,
                    value: ref.watch(selectedTracksProvider.notifier).contains(track),
                    onChanged: (_) {
                      ref.read(selectedTracksProvider.notifier).toggle(track);
                    },
                  );
                }),
              ),
            );
          },
        ));
  }
}
