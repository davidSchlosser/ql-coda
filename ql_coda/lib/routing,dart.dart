import 'package:coda/screens/album_tracks_view.dart';
import 'package:coda/screens/albums_view.dart';
import 'package:coda/screens/cache_tags.dart';
import 'package:coda/screens/current_track.dart';
import 'package:coda/screens/edit_single_tag_view.dart';
import 'package:coda/screens/playlist_view.dart';
import 'package:coda/screens/queries_view.dart';
import 'package:coda/screens/queue_view.dart';
import 'package:coda/screens/track_tags_view.dart';
import 'package:coda/screens/ui_util.dart';
import 'package:go_router/go_router.dart';


GoRouter router() {
  return GoRouter(
    initialLocation: '/nowPlaying',
    routes: [
      /*GoRoute(
        path: '/dashboard',
        builder: (context, state) => DashboardView(),
      ),*/
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
