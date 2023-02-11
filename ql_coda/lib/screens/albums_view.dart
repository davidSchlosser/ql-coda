import 'package:coda/models/albums_model.dart';
import 'package:coda/screens/common_scaffold.dart';
import 'package:coda/screens/queries_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coda/logger.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';

import '../models/query_model.dart';
import '../models/queue_model.dart';

Logger _logger = getLogger('albums_view', Level.warning);

enum SortOption { date, title, genre, artist }

class AlbumsView extends ConsumerStatefulWidget {
  const AlbumsView({super.key});

  @override
  ConsumerState<AlbumsView> createState() => _AlbumsViewState();
}

class _AlbumsViewState extends ConsumerState<AlbumsView> {
  @override
  initState() {
    super.initState();
    fetchAlbumsMatchingQuery(ref.read(queryProvider), ref);
  }

  @override
  Widget build(BuildContext context) {
    _logger.d('building albums view');
    ScrollController scrollController = ScrollController();
    _logger.d('build AlbumListView');
    final List<Album> albums = ref.watch(albumsProvider);
    List<Album> selectedAlbums = ref.watch(selectedAlbumsProvider); // needed for forcing build

    return CommonScaffold(
      title: 'Browse Albums',
      popupMenu: PopupMenuButton(
        itemBuilder: (BuildContext context) => [
          PopupMenuItem(
            onTap: () => ref.read(selectedAlbumsProvider.notifier).enQueueSelectedAlbums(),
            child: const Text('Queue selected'),
          ),
          PopupMenuItem(
            onTap: () => ref.read(selectedAlbumsProvider.notifier).selectAll(albums),
            child: const Text('Select all'),
          ),
          PopupMenuItem(
            onTap: () => ref.read(selectedAlbumsProvider.notifier).clear(),
            child: const Text('Deselect all'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: const Text('Filter albums'), // add new tag
        onPressed: () {
          Navigator.push(context, QueriesPopup(ref));
        },
        backgroundColor: Colors.green,
        icon: const Icon(Icons.filter_alt_sharp),
      ),
      child: (albums.isEmpty)
          ? const Center(child: Text('Set a filter, then search'))
          : Builder(builder: (context) {
              _logger.d('albums view - list is not empty');

              return Column(
                children: [
                  // display query text, and a button to sort the albums
                  Card(
                    child: Column(
                      //mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 5.0),
                          child: Consumer(builder: (context, ref, child) {
                            return ListTile(
                              title: Text('Albums are filtered on: ${ref.watch(queryProvider)}'),
                              //subtitle: Text('display the number of albums received'),
                              leading: const Icon(
                                Icons.filter_alt_sharp,
                                size: 18.0,
                              ),
                              trailing: IconButton(
                                  icon: const Icon(Icons.sort), //Icon(Icons.sort)
                                  onPressed: () {
                                    if (albums.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("There are no albums to sort!"),
                                        ),
                                      );
                                    } else {
                                      SortOption? sortOp; // = SortOption.date;
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          // template for radio buttons to select the sort option
                                          //
                                          RadioListTile<SortOption> sortTile(String title, SortOption? sortOpValue) {
                                            return RadioListTile<SortOption>(
                                              title: Text(title),
                                              value: sortOpValue!,
                                              groupValue: sortOp,
                                              onChanged: (SortOption? op) {
                                                sortAlbums(describeEnum(op!), ref);
                                                Navigator.of(context).pop();
                                              },
                                            );
                                          }

                                          return AlertDialog(
                                              title: const Text('Sort by..'),
                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: <Widget>[
                                                  sortTile('Date', SortOption.date),
                                                  sortTile('Genre', SortOption.genre),
                                                  sortTile('Title', SortOption.title),
                                                  sortTile('Artist', SortOption.artist),
                                                ],
                                              ));
                                        },
                                      );
                                    }
                                  }),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  ListView.builder(
                    controller: scrollController,
                    itemCount: albums.length,
                    itemExtent: 100,
                    shrinkWrap: true,
                    itemBuilder: (BuildContext context, int index) {
                      Album album = albums[index];
                      return Slidable(
                        key: ObjectKey(album),
                        startActionPane: ActionPane(
                          motion: const ScrollMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (BuildContext context) {
                                ref.read(albumProvider.notifier).state = album;
                                context.goNamed('albumtracks');
                              },
                              backgroundColor: const Color(0xFF21B7CA),
                              foregroundColor: Colors.white,
                              icon: Icons.open_in_full,
                              label: 'Open',
                            ),
                            SlidableAction(
                              onPressed: (BuildContext context) {
                                // add album tracks to the queue
                                queueAlbum(album.directory);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                  content: Text("Album is being added to the queue"),
                                ));
                              },
                              backgroundColor: const Color(0xFF21B7CA),
                              foregroundColor: Colors.white,
                              icon: Icons.playlist_add,
                              label: 'Queue',
                            )
                          ],
                        ),
                        child: CheckboxListTile(
                          title: Text(album.albumName),
                          subtitle: Text('${album.dates.toString()}, ${album.genres}\n${album.artists}'),
                          isThreeLine: true,
                          value: ref.watch(selectedAlbumsProvider.notifier).contains(album),
                          onChanged: (_) {
                            ref.read(selectedAlbumsProvider.notifier).toggle(album);
                          },
                        ),
                      );
                    },
                  ),
                ],
              );
            }),
    );
  }
}

/*
typedef PlayerDestination = Function(
    BuildContext context, String albumFileName);

PlayerDestination? toQueue(context, albumDirectoryName) {
  queueAlbum(albumDirectoryName);

  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
    content: Text("Songs are being added to the queue"),
  ));

  return null;
}
*/
