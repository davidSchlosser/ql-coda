import 'package:coda/models/cover_model.dart';
import 'package:coda/models/current_track_model.dart';
import 'package:coda/screens/common_scaffold.dart';
import 'package:coda/logger.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as old;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coda/models/track_model.dart';

import '../models/control_panel_model.dart';

Logger _logger = getLogger('CurrentTrack', Level.warning);

class CurrentTrack extends ConsumerWidget {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  CurrentTrack({super.key});
  ControlPanelModel controlPanel = ControlPanelModel();

  // TODO clear image and display 'None playing' when playing is stopped

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Track? track;

    //final currentTrackModel = ref.watch(nowPlayingTrackModelProvider);
    final AsyncValue<CurrentTrackModel> currentTrackModel =
        ref.watch(nowPlayingTrackModelProvider);
    currentTrackModel.when(
      loading: () => _logger.d('currentTrackModel loading'),
      error: (error, stack) => _logger.d('currentTrackModel error'),
      data: (currentTrackModel) {
        track = currentTrackModel.track;
        _logger.d('currentTrackModel: ${track}');
      },
    );
    /*ref.read(editTracksProvider.notifier).state = [track];
    ref.read(trackProvider.notifier).state = track;*/

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
              controlPanel.refresh();
            },
            child: ListView(children: <Widget>[
              // cover image
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: old.Consumer<CoverModel>(
                    builder: (context, coverValue, child) {
                  return SizedBox(
                    height: 400.0,
                    child: (coverValue.cover().isEmpty
                        ? Center(child: Text('cover is unavailable'))
                        : Image.memory(coverValue.cover(),
                            fit: BoxFit.contain)),
                  );
                }),
              ),
              // artist~composer~title header
              Padding(
                padding: const EdgeInsets.only(
                    top: 24.0, bottom: 5.0, left: 24.0, right: 24.0),
                child: old.Consumer<CurrentTrackModel>(
                    builder: (context, currentTrackValue, child) {
                  return Text(currentTrackValue.header(),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 24.0));
                }),
              ),
              // subheader
              Padding(
                padding: const EdgeInsets.only(left: 24.0, right: 24.0),
                child: old.Consumer<CurrentTrackModel>(
                    builder: (context, currentTrackValue, child) {
                  String sh = currentTrackValue.subheader();
                  return sh.isEmpty
                      ? Container()
                      : Text(sh,
                          style: const TextStyle(
                              fontWeight: FontWeight.normal, fontSize: 18.0));
                }),
              ),
              Padding(
                padding: const EdgeInsets.only(
                    left: 24.0, right: 24.0, bottom: 10.0),
                child: old.Consumer<CurrentTrackModel>(
                    builder: (context, currentTrackValue, child) {
                  return Text(currentTrackValue.byArtist(),
                      style: const TextStyle(
                          fontWeight: FontWeight.normal, fontSize: 18.0));
                }),
              ),
              // with performers
              Padding(
                  padding: const EdgeInsets.only(
                      left: 24.0, right: 24.0, bottom: 5.0),
                  child: old.Consumer<CurrentTrackModel>(
                      builder: (context, currentTrackValue, child) {
                    return Column(
                        children:
                            withPerformers(currentTrackValue.withPerformers()),
                        crossAxisAlignment: CrossAxisAlignment.start);
                  })),
              Divider(),
              // album & summary
              Padding(
                padding: const EdgeInsets.only(left: 24.0, right: 24.0),
                child: old.Consumer<CurrentTrackModel>(
                    builder: (context, currentTrackValue, child) {
                  return Text(currentTrackValue.summary(),
                      style: const TextStyle(
                          fontWeight: FontWeight.normal, fontSize: 18.0));
                }),
              ),
            ]),
          ),
        ));
  }
}

List<Widget> withPerformers(performers) {
  List<Widget> wp = [];
  performers.forEach((p) => wp.add(Text(p, style: TextStyle(fontSize: 18.0))));
  return wp;
}
