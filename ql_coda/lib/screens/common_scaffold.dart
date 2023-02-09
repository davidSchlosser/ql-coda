// import 'package:coda/logger.dart';
import 'package:coda/screens/queue_view.dart';
import 'package:coda/screens/ui_util.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
//import 'package:coda/screens/control_panel.dart';
import 'package:coda/screens/current_track.dart';
import 'package:coda/screens/playlist_view.dart';
import 'package:coda/screens/cache_tags.dart';
import 'package:coda/screens/queries_view.dart';

import 'album_tracks_view.dart';
import 'albums_view.dart';
import 'edit_single_tag_view.dart';
import 'track_tags_view.dart';

GoRouter router() {
  return GoRouter(
    initialLocation: '/nowPlaying',
    routes: [
      GoRoute(
        path: '/nowPlaying',
        builder: (context, state) => CurrentTrack(),
      ),
      GoRoute(
        path: '/playlist',
        builder: (context, state) => const PlaylistView(),
      ),
      GoRoute(
        path: '/cacheTags',
        builder: (context, state) => const CachePage(),
      ),
      GoRoute(
        path: '/queue',
        builder: (context, state) => const QueueView(),
      ),
      GoRoute(
        path: '/albums',
        builder: (context, state) => const AlbumsView(),
      ),
      GoRoute(
        path: '/albumtracks',
        name: 'albumtracks',
        builder: (context, state) => const AlbumTracksView(),
      ),
      GoRoute(
        path: '/edittags',
        builder: (context, state) => const EditTagsView(),
      ),
      GoRoute(
        path: '/editSingleTag',
        // builder: (context, state) => FamilyScreen(family: state.extra! as Family),
        builder: (context, state) => EditSingleTagView(tagIndex: state.extra as int),
      ),
      GoRoute(
        path: '/queries',
        builder: (context, state) => const QueriesView(),
      ),
      GoRoute(
        path: '/speakers',
        builder: (context, state) => const NilWidget(),
      ),
      GoRoute(
        path: '/logs',
        builder: (context, state) => const NilWidget(),
      ),
    ],
  );
}


// Logger _logger = getLogger('main', Level.debug);

class CommonScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? floatingActionButton;   // pages don't have to have a FAB
  final Widget? popupMenu;

  const CommonScaffold(
      {super.key,
      required this.title,
      required this.child,
      this.floatingActionButton,
      this.popupMenu});

  @override
  Widget build(BuildContext context) {

    List<Widget>actions = [
      IconButton(
        icon: const Icon(Icons.music_note),
        tooltip: 'Now playing',
        onPressed: () { context.go('/nowPlaying'); },
      ),
      IconButton(
        icon: const Icon(Icons.playlist_play),
        tooltip: 'Playlist',
        onPressed: () { context.go('/playlist'); },
      ),
      (popupMenu != null) ? popupMenu! : const NilWidget(),
    ];
    //if (popupMenu != null) { actions.add(popupMenu!); };

    return WillPopScope(
      onWillPop: () async {
        return _onWillPop(context);
      },
      child: Scaffold(
        appBar: AppBar(
            title: Text(
                title), //Text(_pageMap[Page.values[_currentPage]]['menuText']),
            actions: actions),
        body: child,
        floatingActionButton: floatingActionButton,
        //bottomNavigationBar: const ControlPanel(),
        drawer: Drawer(
          child: ListView(
            children: <Widget>[
              const DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.blue,
                ),
                child: Text('Coda', style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.0,
                )),
              ),
              ListTile(
                title: const Text('Now playing'),
                leading: const Icon(Icons.music_note),
                onTap: () {
                  context.go('/nowPlaying');
                  Navigator.pop(context);
                }),
              ListTile(
                  title: const Text('Playlist'),
                  leading: const Icon(Icons.playlist_add_check),
                  onTap: () {
                    context.go('/playlist');
                    Navigator.pop(context);
                  }),
              ListTile(
                  title: const Text('Queue'),
                  leading: const Icon(Icons.queue_music),
                  onTap: () {
                    context.go('/queue');
                    Navigator.pop(context);
                  }),
              ListTile(
                  title: const Text('Albums'),
                  leading: const Icon(Icons.library_music),
                  onTap: () {
                    context.go('/albums');
                    Navigator.pop(context);
                  }),
              /*ListTile(
                  title: const Text('Saved queries'),
                  leading: const Icon(Icons.filter_alt_sharp),
                  onTap: () {
                    context.go('/queries');
                    Navigator.pop(context);
                  }),*/
              ListTile(
                  title: const Text('Speaker zones'),
                  leading: const Icon(Icons.speaker),
                  onTap: () {
                    context.go('/speakers');
                    Navigator.pop(context);
                  }),
              ListTile(
                  title: const Text('Logs'),
                  leading: const Icon(Icons.music_note),
                  onTap: () {
                  context.go('/logs');
                  Navigator.pop(context);
                  }),
              ListTile(
                  title: const Text('Tag suggestions cache'),
                  leading: const Icon(Icons.cached),
                  onTap: () {
                  context.go('/cacheTags');
                  Navigator.pop(context);
                  }),
            ],
          ),
        ),
      ),
    );
  }
}

Future<bool> _onWillPop(BuildContext context) {
  return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Are you sure?'),
          content: const Text('Do you really want to exit Coda?'),
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
        );
      }
  ).then((exit) {
    return exit ?? false;
  });
}