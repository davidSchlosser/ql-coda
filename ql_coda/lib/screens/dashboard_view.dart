import 'dart:math';

import 'package:flutter/material.dart';
import 'package:coda/models/dashboard_model.dart';
import 'package:coda/screens/ui_util.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:coda/logger.dart';
import 'package:logger/logger.dart';

Logger _logger = getLogger('dashboard_view', Level.debug);

double tickDuration = 1.0;
int trackLengthInSeconds = 40;

void main() {
  runApp(const ProviderScope(child: PB()));
}

class PB extends StatelessWidget {
  const PB({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false, home: ProgressBar(length: 0));
  }
}

class ProgressBar extends ConsumerStatefulWidget {
  final double length; // track length
  final double
      startAt; // fraction of track length to start the progress display

  ProgressBar(
      {required this.length,
      this.startAt =
          0}); // tracks can be paused & restarted, or advanced from the control

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ProgressState();
}

class _ProgressState extends ConsumerState<ProgressBar> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Timer App')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TimerBarWidget(),
            SizedBox(height: 40),
            ButtonsContainer(),
          ],
        ),
      ),
    );
  }
}

class ButtonsContainer extends ConsumerWidget {
  @override
  Widget build(BuildContext context, ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // previous track
        FloatingActionButton(
          onPressed: () {

          },
          child: Icon(Icons.skip_previous),
        ),
        SizedBox(width: 40),

        // start
        FloatingActionButton(
          onPressed: () {
            ref.read(progressProvider.notifier).start(trackLengthInSeconds);
          },
          child: Icon(Icons.play_arrow),
        ),
        SizedBox(width: 20),

        // pause/resume
        FloatingActionButton(
          onPressed: () {
            if (ref.read(progressProvider).playerState == PlayerState.playing) {
              ref.read(progressProvider.notifier).pause();
            } else {
              ref.read(progressProvider.notifier).resume();
            }
          },
          child: Icon( ref.watch(progressProvider).playerState == PlayerState.playing
              ? Icons.pause
              : Icons.play_arrow
          ),
        ),
        SizedBox(width: 20),

        // restart
        FloatingActionButton(
          onPressed: () {
            ref.read(progressProvider.notifier).resume();
          },
          child: Icon(Icons.autorenew),
        ),
        SizedBox(width: 20),


        // next track
        FloatingActionButton(
          onPressed: () {

          },
          child: Icon(Icons.skip_next),
        ),
      ],
    );
  }
}

class TimerBarWidget extends ConsumerWidget {
  const TimerBarWidget({Key? key}) : super(key: key);

  Widget buildSideLabel(text) {
    return Text(
        text,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.normal,
    ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Progress progress = ref.watch(progressProvider);
    double _currentSliderValue = progress.elapsedTrackTime.toDouble();
    //print('building TimerTextWidget ${progress.elapsedTrackTime}');
    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 10,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 30),
            overlayShape: RoundSliderOverlayShape(overlayRadius: 60),
            activeTickMarkColor: Colors.transparent,
            inactiveTickMarkColor: Colors.transparent,
          ),
          child: SizedBox(
            width: MediaQuery.of(context).size.width - 80,
            child: Row(
              children: [
                buildSideLabel(secondsToTime(progress.elapsedTrackTime)),
                Expanded(
                  child: Slider(
                    value: _currentSliderValue,
                    max: progress.trackLength.toDouble(),
                    divisions: progress.trackLength == 0 ? 1 : progress.trackLength,
                    label: _currentSliderValue.round().toString(),
                    onChanged: (double value) {
                      _logger.d('slider onChanged: $value');
                      ref.read(progressProvider.notifier).skipTo(value.toInt());
                    },
                    onChangeStart: (double value) {
                      _logger.d('slider onChangeStart: $value');
                      ref.read(progressProvider.notifier).pause();
                      //ref.read(progressProvider.notifier).skipTo(value.toInt());
                    },
                    onChangeEnd: (double value) {
                      _logger.d('slider onChangeEnd: $value');
                      ref.read(progressProvider.notifier).skipTo(value.toInt());
                      ref.read(progressProvider.notifier).resume();
                    },
                  ),
                ),
                buildSideLabel('-${secondsToTime(progress.trackLength - progress.elapsedTrackTime)}'),
              ],
            ),
          ),
        ),
        LinearPercentIndicator(
          width: MediaQuery.of(context).size.width - 150,
          lineHeight: 30.0,
          barRadius: Radius.circular(10.0),
          percent: progress.trackLength == 0
              ? 0
              : progress.elapsedTrackTime <= progress.trackLength
                  ? progress.elapsedTrackTime / progress.trackLength
                  : 1.0,
          leading: Text(secondsToTime(progress.elapsedTrackTime)),
          trailing: Text(
              '-${secondsToTime(progress.trackLength - progress.elapsedTrackTime)}'),
          backgroundColor: Colors.grey,
          progressColor: Colors.blue,
          alignment: MainAxisAlignment.center,
        ),
        /*Text(
            'state: ${progress.playerState}, elapsed: ${progress.elapsedTrackTime}, remaining ${progress.trackLength - progress.elapsedTrackTime}'),*/
      ],
    );
  }
}

String secondsToTime(int seconds) {
  Duration d = Duration(seconds: seconds);
  int h = d.inHours;
  int m = d.inMinutes.remainder(60);
  int s = d.inSeconds.remainder(60);
  String mt = (h > 0) & (m < 10) ? '0$m' : '$m';
  String st = (s < 10) ? '0$s' : '$s';
  return '${h > 0 ? '$h:' : ''}$mt:$st';
}

/*
LinearPercentIndicator(
width: MediaQuery.of(context).size.width - 90,
lineHeight: 14.0,
percent: progress <= 1.0 ? progress : 1.0,
leading: Text(progressToTime(length, progress)),
trailing: Text('-${progressToTime(length, 1-progress)}'),
backgroundColor: Colors.grey,
progressColor: Colors.blue,
alignment: MainAxisAlignment.center,
)*/
