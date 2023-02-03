import 'package:flutter/material.dart';
import 'package:coda/models/dashboard_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coda/logger.dart';
import 'package:logger/logger.dart';

Logger _logger = getLogger('dashboard_view', Level.warning);

double tickDuration = 1.0;
int trackLengthInSeconds = 40;

void main() {
  runApp(const ProviderScope(child: PB()));
}

class PB extends StatelessWidget {
  const PB({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(debugShowCheckedModeBanner: false, home: DashboardApp());
  }
}

class DashboardApp extends StatelessWidget {
  const DashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Test App')),
      body: Center(
        child: Dashboard(
            length: trackLengthInSeconds,
            onPause: (int elapsed) {
              _logger.w('onPause at $elapsed');
            },
            onResume: (int elapsed) {
              _logger.w('onResume at $elapsed');
            },
            onNext: () {
              _logger.w('onNext');
            },
            onPrevious: () {
              _logger.w('onPrevious');
            },
            onDragged: (elapsed) {
              _logger.w('onDragged to $elapsed');
            },
            onRandom: () {
              _logger.w('onRandom');
            }),
      ),
    );
  }
}

class Dashboard extends ConsumerStatefulWidget {
  final int length; // track length in seconds
  final Function onPause;
  final Function onResume;
  final Function onNext;
  final Function onPrevious;
  final Function onDragged;
  final Function onRandom;

  const Dashboard(
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

class _DashboardState extends ConsumerState<Dashboard> {

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Future.delayed(Duration.zero, () {
      // start the progres bar as soon as build is fininshed
      ref.read(progressProvider.notifier).start(widget.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        TimerBarWidget(onDragged: widget.onDragged),
        const SizedBox(height: 40),
        ButtonsContainer(
          onPause: widget.onPause,
          onResume: widget.onResume,
          onNext: widget.onNext,
          onPrevious: widget.onPrevious,
          onRandom: widget.onRandom,
        ),
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
      {super.key, required this.onPause,
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
        FloatingActionButton(
          onPressed: () => onPrevious(),
          child: const Icon(Icons.skip_previous),
        ),
        const SizedBox(width: 40),

        // start
        FloatingActionButton(
          onPressed: () {
            ref.read(progressProvider.notifier).start(trackLengthInSeconds);
          },
          child: const Icon(Icons.play_arrow),
        ),
        const SizedBox(width: 20),

        // pause/resume
        FloatingActionButton(
          onPressed: () {
            if (ref.read(progressProvider).playerState == PlayerState.playing) {
              ref.read(progressProvider.notifier).pause();
              onPause(ref.read(progressProvider).elapsedTrackTime);
            } else {
              ref.read(progressProvider.notifier).resume();
              onResume(ref.read(progressProvider).elapsedTrackTime);
            }
          },
          child: Icon(ref.watch(progressProvider).playerState == PlayerState.playing ? Icons.pause : Icons.play_arrow),
        ),
        const SizedBox(width: 20),

        // random
        FloatingActionButton(
          onPressed: () {
            onRandom();
          },
          child: const Icon(Icons.autorenew),
        ),
        const SizedBox(width: 20),

        // next track
        FloatingActionButton(
          onPressed: () => onNext(),
          child: const Icon(Icons.skip_next),
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
    Progress progress = ref.watch(progressProvider);
    double currentSliderValue = progress.elapsedTrackTime.toDouble();
    //print('building TimerTextWidget ${progress.elapsedTrackTime}');
    return Column(
      children: [
        SliderTheme(
          data: const SliderThemeData(
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
                    value: currentSliderValue,
                    max: progress.trackLength.toDouble(),
                    divisions: progress.trackLength == 0 ? 1 : progress.trackLength,
                    label: currentSliderValue.round().toString(),
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
                      onDragged(value.toInt());
                    },
                  ),
                ),
                buildSideLabel('-${secondsToTime(progress.trackLength - progress.elapsedTrackTime)}'),
              ],
            ),
          ),
        ),
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
