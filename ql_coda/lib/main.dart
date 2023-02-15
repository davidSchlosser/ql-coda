import 'package:coda/communicator.dart';
import 'package:coda/logger.dart';
import 'package:coda/routing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import 'models/player_model.dart';

Logger _logger = getLogger('main', Level.warning);

void main() {
  runApp(ProviderScope(child: Coda()));
}

Communicator? communicator;

class Coda extends StatelessWidget with WidgetsBindingObserver {

  Coda({super.key}) {
    WidgetsFlutterBinding.ensureInitialized();
    WidgetsBinding.instance.addObserver(this);
    Player();
  }

  @override
  Widget build(BuildContext context) {
    _logger.d('build');
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Coda',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
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
