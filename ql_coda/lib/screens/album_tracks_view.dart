import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/album_tracks_model.dart';
import '../models/albums_model.dart';
import '../models/collected_tracks_model.dart';
import '../models/track_model.dart';
import 'assemble_route.dart';
import 'clipboard_tags_view.dart';
import 'collected_tracks_view.dart';

class AlbumTracksView extends ConsumerStatefulWidget {
  const AlbumTracksView({super.key});

  @override
  ConsumerState<AlbumTracksView> createState() => _AlbumTracksViewState();
}

class _AlbumTracksViewState extends ConsumerState<AlbumTracksView> {
  @override
  initState() {
    super.initState();
    Album album = ref.read(albumProvider);
    fetchAlbumTracks(album, ref);
  }

  @override
  build(BuildContext context) {
    return TracksView('Album tracks',
        PopupMenuButton(
          itemBuilder: (BuildContext context) => [
            PopupMenuItem(
              onTap: () => {},
              child: Text('Update selected from tags in clipboard'),
            ),
            PopupMenuItem<void Function(BuildContext context, WidgetRef? ref)>(
              onTap: () {
                List<Track> tracks = ref.read(tracksProvider('albums'));
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
              onTap: () => {},
              child: Text('Player credits on selected tracks'),
            ),
          ],
        ),
      sibling: 'albums',
      canQueue: true,
      canPlay: true,
      //canDequeue: true,
      canEditTags: true,
    );
  }
}
