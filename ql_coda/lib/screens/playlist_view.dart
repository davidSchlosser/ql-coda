import 'package:coda/logger.dart';
import 'package:coda/models/playlist_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../models/collected_tracks_model.dart';
import '../models/track_model.dart';
import 'assemble_route.dart';
import 'clipboard_tags_view.dart';
import 'collected_tracks_view.dart';

Logger _logger = getLogger('playlist_view', Level.debug);

class PlaylistView extends ConsumerStatefulWidget {
  const PlaylistView({super.key});

  @override
  ConsumerState<PlaylistView> createState() => _PlaylistViewState();
}

class _PlaylistViewState extends ConsumerState<PlaylistView> {
  @override
  initState() {
    super.initState();
    // get the current playlist
    //
    fetchPlaylist(ref);
  }

  @override
  Widget build(BuildContext context) {
    return TracksView(
        'Playlist tracks',
        // playlistPopupMenu
        PopupMenuButton(
          itemBuilder: (BuildContext context) => [
            PopupMenuItem(
              onTap: () => {},
              child: Text('Update selected from tags in clipboard'),
            ),
            PopupMenuItem<void Function(BuildContext context, WidgetRef? ref)>(
              onTap: () {
                List<Track> tracks = ref.read(tracksProvider('playlist'));
                ref.read(selectedTracksProvider.notifier).selectAll(tracks);
                return;
              },
              child: Text('Select all'),
            ),
            PopupMenuItem<
                void Function(BuildContext context, WidgetRef? ref)>(
              onTap: () => ref.read(selectedTracksProvider.notifier).clear(),
              child: Text('Deselect all'),
            ),
            PopupMenuItem<
                void Function(BuildContext context, WidgetRef? ref)>(
              onTap: () {
                Navigator.push(context, AssembleRoute(
                  builder: (context) {
                    return ClipboardView(
                      title: 'Clipboard',
                      onDone: (_) {},
                    );
                  },
                ));
              },
              child: Text('View clipboard tags'),
            ),
            PopupMenuItem<void Function(BuildContext context, WidgetRef? ref)>(
              onTap: () => ref
                  .read(selectedTracksProvider.notifier)
                  .enQueueSelectedTracks(), // _enqueueSelected(context, ref),
              child: Text('Queue selected tracks'),
            ),
            PopupMenuItem<
                void Function(BuildContext context, WidgetRef? ref)>(
              onTap: () => fetchPlaylist(ref),
              child: Text('Reload playlist from Quodlibet'),
            ),
            PopupMenuItem<
                void Function(BuildContext context, WidgetRef? ref)>(
              onTap: () => {},
              child: Text('Player credits on selected tracks'),
            ),
          ],
        ),
      sibling: 'playlist',
      canQueue: true,
      canPlay: true,
      //canDequeue: true,
      canEditTags: true,
    );
  }
}

