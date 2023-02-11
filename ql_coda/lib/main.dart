import 'package:coda/obsolete/saved_filters_bloc.dart';
import 'package:coda/communicator.dart';
import 'package:coda/logger.dart';
import 'package:coda/repositories/repositories.dart';
import 'package:coda/routing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import 'models/player_model.dart';

Logger _logger = getLogger('main', Level.warning);

void main() {
  runApp(const ProviderScope(child: CodaRP()));
}

class CodaRP extends StatelessWidget {
  const CodaRP({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: Coda());
  }
}

Communicator? communicator;

class Coda extends StatelessWidget with WidgetsBindingObserver {
  final FilteredAlbumsRepository filteredAlbumsRepository = // TODO migrate to RiverPod
      FilteredAlbumsRepository(
    filteredAlbumsApiClient: FilteredAlbumsApiClient(),
  );
  final SavedFiltersRepository savedFiltersRepository = SavedFiltersRepository(
    // TODO migrate to RiverPod
    savedFiltersApiClient: SavedFiltersApiClient(),
  );

  Coda({super.key}) {
    WidgetsFlutterBinding.ensureInitialized();
    WidgetsBinding.instance.addObserver(this);
    Player();
  }

  // final Player _player = Player();

  @override
  Widget build(BuildContext context) {
    _logger.d('build');
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Coda',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      routerConfig: router(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _logger.d('$state');
    if (state == AppLifecycleState.resumed) {
      Player.refresh();
    }
  }
}
