import 'package:coda/communicator.dart';
import 'package:coda/models/player_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coda/logger.dart';
import 'package:logger/logger.dart';

Logger _logger = getLogger('volume_widget', Level.warning);

class VolumeWidget extends ConsumerStatefulWidget {
  const VolumeWidget({Key? key}) : super(key: key);

  @override
  ConsumerState<VolumeWidget> createState() => _VolumeWidgetState();
}

class _VolumeWidgetState extends ConsumerState<VolumeWidget> {
  late double _value;

  @override
  initState() {
    super.initState();
    _value = ref.read(volumeProvider).value ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {

    return Card(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Player volume ${(_value*100).toInt()}%',
            style: DefaultTextStyle.of(context).style.apply(fontSizeFactor: 2.0),
          ),
          RotatedBox(
            quarterTurns: -1,
            child: SizedBox(
              width: 350,
              child: SliderTheme(
                data: const SliderThemeData(
                    trackHeight: 30,
                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 15),
                    overlayShape: RoundSliderOverlayShape(overlayRadius: 30),
                    activeTickMarkColor: Colors.transparent,
                    inactiveTickMarkColor: Colors.transparent),
                child: Slider(
                  value: _value,
                  onChanged: (double value) {
                    _logger.d('slider onChanged: $value');
                    setState(() {
                      _value = value;
                    });
                  },
                  onChangeStart: (double value) {
                    _logger.d('slider onChangeStart: $value');
                    //Dashboard.pause();
                  },
                  onChangeEnd: (double value) {
                    _logger.d('slider onChangeEnd: $value');
                    Communicator().request('volume', [(_value*100).toInt().toString()]);
                  },
                ),
              ),
            ),
          ),
          const Icon(Icons.volume_up_outlined, size: 60, color: Colors.blueGrey),
        ],
      ),
    );
  }
}
