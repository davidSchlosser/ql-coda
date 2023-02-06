import 'package:coda/obsolete/saved_filters_bloc.dart';
import 'package:coda/communicator.dart';
import 'package:coda/logger.dart';
import 'package:coda/models/cover_model.dart';
import 'package:coda/models/volume_model.dart';
import 'package:coda/models/query_model.dart';
import 'package:coda/repositories/repositories.dart';
import 'package:coda/routing,dart.dart';
import 'package:coda/streams/cover_stream.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as old;
import 'package:logger/logger.dart';

import 'models/player_model.dart';


Logger _logger = getLogger('main', Level.debug);

void main() {
  runApp( const ProviderScope(child: CodaRP()) );
}

class CodaRP extends StatelessWidget {
  const CodaRP({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Coda()
    );
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

  final Player _player = Player();

  @override
  Widget build(BuildContext context) {
    _logger.w('build');
    return old.MultiProvider(
      providers: [
        /*old.StreamProvider<CurrentTrackModel>( // TODO migrate to RiverPod
          initialData: CurrentTrackModel(),
          create: (_) => CurrentTrackStream.currentTrackStreamController.stream
        ),*/
        old.StreamProvider<CoverModel>( // TODO migrate to RiverPod
          initialData: CoverModel(),
          create: (_) => CoverStream.coverStreamController.stream
        ),
        old.StreamProvider<Volume>( // TODO migrate to RiverPod
          initialData: Volume(0),
          create: (_) => VolumeModel.volumeStreamController.stream
        ),
        old.ChangeNotifierProvider(create: (context) => QueryModel()),  // TODO migrate to RiverPod
        old.ChangeNotifierProvider(create: (context) => SavedQueriesModel()), // TODO migrate to RiverPod
      ],
      child: MaterialApp.router(
        title: 'Coda',
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
      _player.refresh();
    }
  }
}
