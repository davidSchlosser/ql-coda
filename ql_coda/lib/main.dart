import 'package:coda/obsolete/saved_filters_bloc.dart';
import 'package:coda/communicator.dart';
import 'package:coda/logger.dart';
import 'package:coda/models/current_track_model.dart';
//import 'package:coda/obsolete/playlist_model.dart';
import 'package:coda/models/clipboard_model.dart';
import 'package:coda/models/control_panel_model.dart';
import 'package:coda/models/cover_model.dart';
import 'package:coda/models/volume_model.dart';
import 'package:coda/models/query_model.dart';
import 'package:coda/repositories/repositories.dart';
//import 'package:coda/screens/current_track.dart';
//import 'package:coda/screens/playlist_view.dart';
//import 'package:coda/screens/cache_tags.dart';
import 'package:coda/screens/common_scaffold.dart';
import 'package:coda/streams/current_track_stream.dart';
import 'package:coda/streams/cover_stream.dart';
import 'package:coda/streams/progress_stream.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as old_way;
import 'package:logger/logger.dart';

//import 'models/albums_model.dart';

Logger _logger = getLogger('main', Level.debug);

void main() {
  runApp( const ProviderScope(child: CodaRP()) );
}

class CodaRP extends StatelessWidget {
  const CodaRP({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: Coda());
  }

}

Communicator? communicator;

class Coda extends StatelessWidget with WidgetsBindingObserver {
  final FilteredAlbumsRepository filteredAlbumsRepository = // TODO migrate to RiverPod
  FilteredAlbumsRepository(
    filteredAlbumsApiClient: FilteredAlbumsApiClient(),
  );
  final SavedFiltersRepository savedFiltersRepository = SavedFiltersRepository( // TODO migrate to RiverPod
    savedFiltersApiClient: SavedFiltersApiClient(),
  );

  Coda({super.key}){
    WidgetsFlutterBinding.ensureInitialized();
    WidgetsBinding.instance.addObserver(this);
  }

  final CurrentTrackStream cts = CurrentTrackStream();
  final CoverStream cs = CoverStream();

  @override
  Widget build(BuildContext context) {
    _logger.w('build');
    return old_way.MultiProvider(
      providers: [
        old_way.StreamProvider<CurrentTrackModel>( // TODO migrate to RiverPod
          initialData: CurrentTrackModel(),
          create: (_) => CurrentTrackStream.currentTrackStreamController.stream
        ),
        old_way.StreamProvider<CoverModel>( // TODO migrate to RiverPod
          initialData: CoverModel(),
          create: (_) => CoverStream.coverStreamController.stream
        ),
        old_way.StreamProvider<Progress>( // TODO migrate to RiverPod
          initialData: Progress(0.0),
          create: (_) => ProgressStream.progressStreamController.stream
        ),
        old_way.StreamProvider<Volume>( // TODO migrate to RiverPod
          initialData: Volume(0),
          create: (_) => VolumeModel.volumeStreamController.stream
        ),
        old_way.Provider<ControlPanelModel>(create: (_) => ControlPanelModel()), // TODO migrate to RiverPod
        old_way.ChangeNotifierProvider(create: (context) => QueryModel()),  // TODO migrate to RiverPod
        old_way.ChangeNotifierProvider(create: (context) => SavedQueriesModel()), // TODO migrate to RiverPod
        /*old_way.ChangeNotifierProvider(
            create: (context) => CheckedPlaylistTracks()),*/ // TODO migrate to RiverPod
      ],
      child: MaterialApp.router(
        title: 'Quodlibet Coda',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        //home: const CodaHomePage(title: 'Quodlibet Coda'),
        routerConfig: router(),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _logger.d('$state');
    if (state == AppLifecycleState.resumed) {
      //Communicator().reset();   // this causes issue if it occurs during tag cache rebuild
      ControlPanelModel().refresh();
    }
  }
}
