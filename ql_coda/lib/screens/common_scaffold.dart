import 'package:coda/logger.dart';
import 'package:coda/screens/ui_util.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';

Logger _logger = getLogger('main', Level.warning);

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
        drawer: Drawer(
          child: ListView(
            children: <Widget>[
              const DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.blueGrey,
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