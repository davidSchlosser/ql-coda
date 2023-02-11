import 'package:coda/screens/ui_util.dart';
import 'package:flutter/material.dart';
import 'package:coda/models/dashboard_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coda/logger.dart';
import 'package:logger/logger.dart';

import '../models/player_model.dart';

Logger _logger = getLogger('dashboard_view', Level.warning);

double tickDuration = 1.0;

class DashboardWidget extends ConsumerStatefulWidget {
  final int length; // track length in seconds
  final Function onPause;
  final Function onResume;
  final Function onNext;
  final Function onPrevious;
  final Function onDragged;
  final Function onRandom;

  const DashboardWidget(
      {super.key,
      required this.length,
      required this.onPause,
      required this.onResume,
      required this.onNext,
      required this.onPrevious,
      required this.onDragged,
      required this.onRandom});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _DashboardState();
}

class _DashboardState extends ConsumerState<DashboardWidget> {
  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () {
      _logger.d('_DashboardState initState');

      // start the progress bar as soon as build is fininshed

      // player status let's us know if it's playing/paused, progress proportion
      Dashboard.monitorPlayerStatus(widget.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        TimerBarWidget(onDragged: widget.onDragged),
        const SizedBox(height: 0),
        ButtonsContainer(
          onPause: widget.onPause,
          onResume: widget.onResume,
          onNext: widget.onNext,
          onPrevious: widget.onPrevious,
          onRandom: widget.onRandom,
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class ButtonsContainer extends ConsumerWidget {
  final Function onPause;
  final Function onResume;
  final Function onNext;
  final Function onPrevious;
  final Function onRandom;
  const ButtonsContainer(
      {super.key,
      required this.onPause,
      required this.onResume,
      required this.onNext,
      required this.onPrevious,
      required this.onRandom});

  @override
  Widget build(BuildContext context, ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // previous track
        IconButton(
          iconSize: 50,
          onPressed: () => onPrevious(),
          icon: const Icon(Icons.skip_previous),
        ),
        const SizedBox(width: 60),

        // pause/resume
        IconButton(
          iconSize: 50,
          onPressed: () {
            if (ref.read(playerStateProvider).value != PlayerState.playing) {
              _logger.d('pause/resume - resume');  // paused, stopped, ...
              onResume();
            } else {
              _logger.d('pause/resume - pause');  // playing
              onPause();
            }
          },
          icon: Icon(ref.watch(playerStateProvider).value == PlayerState.playing ? Icons.pause : Icons.play_arrow),
        ),
        const SizedBox(width: 60),

        // random
        IconButton(
          iconSize: 50,
          onPressed: () {
            onRandom();
          },
          icon: const Icon(Icons.autorenew),
        ),
        const SizedBox(width: 60),

        // next track
        IconButton(
          iconSize: 50,
          onPressed: () {
            Dashboard.resetProgress(0,0);
            onNext();
          },
          icon: const Icon(Icons.skip_next),
        ),
      ],
    );
  }
}

class TimerBarWidget extends ConsumerWidget {
  final Function onDragged;
  const TimerBarWidget({required this.onDragged, Key? key}) : super(key: key);

  Widget buildSideLabel(text) {
    return Text(text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.normal,
        ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    double elapsedProportion = ref.watch(elapsedProportionProvider).value ?? 0;
    _logger.d('elapsedProportion $elapsedProportion');
    int trackLength = ref.watch(nowPlayingTrackModelProvider).value?.track.length ?? 0;
    double currentSliderValue = trackLength * elapsedProportion;

    //_logger.d('currentSliderValue $currentSliderValue');

    return Column(
      children: [
        SliderTheme(
          data: const SliderThemeData(
            trackHeight: 3,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10),
            overlayShape: RoundSliderOverlayShape(overlayRadius: 60),
            activeTickMarkColor: Colors.transparent,
            inactiveTickMarkColor: Colors.transparent,
          ),
          child: SizedBox(
            width: MediaQuery.of(context).size.width - 80,
            child: Row(
              children: [
                buildSideLabel(secondsToTime(currentSliderValue.toInt())),
                Expanded(
                  child: Slider(
                    value: currentSliderValue,
                    max: trackLength.toDouble(),
                    divisions: trackLength == 0 ? 1 : trackLength,
                    label: secondsToTime(currentSliderValue.toInt()), // currentSliderValue.round().toString(),

                    onChanged: (double value) {
                      _logger.d('slider onChanged: $value');
                      Dashboard.forceProgress(value.toInt(), trackLength);
                    },

                    onChangeStart: (double value) {
                      _logger.d('slider onChangeStart: $value');
                      //Dashboard.pause();
                    },

                    onChangeEnd: (double value) {
                      _logger.d('slider onChangeEnd: $value');
                       //Dashboard.skipTo(value.toInt(), trackLength);
                      onDragged(value.toInt());
                    },
                  ),
                ),
                //buildSideLabel('-${secondsToTime( (trackLength * (1 - currentSliderValue)).toInt() )}'),
                buildSideLabel('-${secondsToTime( trackLength - currentSliderValue.toInt()) }'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
