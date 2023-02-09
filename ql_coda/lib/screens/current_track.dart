import 'package:coda/models/cover_model.dart';
import 'package:coda/models/current_track_model.dart';
import 'package:coda/screens/common_scaffold.dart';
import 'package:coda/logger.dart';
import 'package:coda/screens/ui_util.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coda/models/track_model.dart';

import '../communicator.dart';
import '../models/player_model.dart';
import 'dashboard_view.dart';

Logger _logger = getLogger('CurrentTrack', Level.warning);

class CurrentTrack extends ConsumerWidget {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  CurrentTrack({super.key});
  //ControlPanelModel controlPanel = ControlPanelModel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Track? track;
    CurrentTrackModel? currentTrack;

    final AsyncValue<CurrentTrackModel> currentTrackModel = ref.watch(nowPlayingTrackModelProvider);

    currentTrackModel.when(
      loading: () => _logger.d('currentTrackModel loading'),
      error: (error, stack) => _logger.d('currentTrackModel error $error'),
      data: (currentTrackModel) {
        track = currentTrackModel.track;
        currentTrack = currentTrackModel;
        _logger.d('currentTrackModel: ${track}');
      },
    );

    return CommonScaffold(
        title: 'Now playing',
        floatingActionButton: (track == null) || track!.filename.isEmpty
            ? null // don't show if there's no track to edit
            : FloatingActionButton(
                child: const Icon(Icons.edit),
                onPressed: () {
                  _logger.w('Now playing track: $track');
                  ref.read(editTracksProvider.notifier).state = [track!];
                  ref.read(trackProvider.notifier).state = track!;
                  context.go('/edittags');
                },
              ),
        child: InkWell(
          onTap: () {
            // TODO: PlayerDeck().togglePlayPause();
          },
          child: RefreshIndicator(
            key: _refreshIndicatorKey,
            onRefresh: () async {
              _logger.d('onRefresh');
              // controlPanel.refresh(); // TODO refresh current track??
            },
            child: track == null
                ? Center(child: Text('Track information isn\'t available', style: TextStyle(fontSize: 30)))
                : Column(
                    children: [
                      Expanded(
                        child: ListView(children: <Widget>[
                          // cover image
                          Padding(
                              padding: const EdgeInsets.only(top: 10.0),
                              child: /*old.Consumer<CoverModel>(builder: (context, coverValue, child) {
                              return*/
                                  Builder(builder: (context) {
                                CoverModel? coverValue = ref.watch(coverProvider).value;
                                return (coverValue == null)
                                    ? Center(child: Text('cover is unavailable'))
                                    : SizedBox(
                                        height: 400.0,
                                        child: (coverValue.cover().isEmpty
                                            ? Center(child: Text('cover is unavailable'))
                                            : Image.memory(coverValue.cover(), fit: BoxFit.contain)),
                                      );
                              })),
                          // artist~composer~title header
                          Padding(
                            padding: const EdgeInsets.only(top: 24.0, bottom: 5.0, left: 24.0, right: 24.0),
                            child: Text(currentTrack!.header(),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24.0)),
                          ),
                          // subheader
                          Padding(
                            padding: const EdgeInsets.only(left: 24.0, right: 24.0),
                            child: currentTrack!.subheader().isEmpty
                                ? NilWidget()
                                : Text(currentTrack!.subheader(),
                                    style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 18.0)),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 10.0),
                            child: Text(currentTrack!.byArtist(),
                                style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 18.0)),
                          ),
                          // with performers
                          Padding(
                            padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 5.0),
                            child: Column(
                                children: withPerformers(currentTrack!.withPerformers()),
                                crossAxisAlignment: CrossAxisAlignment.start),
                          ),
                          Divider(),
                          // album & summary
                          Padding(
                            padding: const EdgeInsets.only(left: 24.0, right: 24.0),
                            child: Text(currentTrack!.summary(),
                                style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 18.0)),
                          ),
                        ]),
                      ),
                      DashboardWidget(
                        length: track == null ? 0 : track!.length,
                        onNext: () {
                          _logger.w('next');
                          Communicator().doRemote('next');
                          Player.refresh();
                        },
                        onPrevious: () {
                          _logger.d('previous');
                          Communicator().doRemote('previous');
                          Player.refresh();
                        },
                        onPause: () {
                          _logger.d('pause');
                          Communicator().doRemote('pause');
                          Player.refresh();
                        },
                        onDragged: (elapsedSeconds) {
                          _logger.d('dragged to ${secondsToTime(elapsedSeconds)}');
                          Communicator().doRemote('seek ${secondsToTime(elapsedSeconds)}');
                          Player.refresh();
                        },
                        onRandom: () {
                          _logger.d('random');
                          Communicator().doRemote('skipalbum');
                          Communicator().doRemote('next');
                        },
                        onResume: () {
                          _logger.d('resume');
                          Communicator().doRemote('play');
                          Player.refresh();
                        },
                      ),
                    ],
                  ),
          ),
        ));
  }
}

List<Widget> withPerformers(performers) {
  List<Widget> wp = [];
  performers.forEach((p) => wp.add(Text(p, style: TextStyle(fontSize: 18.0))));
  return wp;
}
