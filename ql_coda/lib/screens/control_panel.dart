
import 'package:coda/models/current_track_model.dart';
import 'package:coda/streams/progress_stream.dart';
import 'package:flutter/material.dart';
//import 'package:co2/models/player.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:coda/models/control_panel_model.dart';
import 'package:coda/logger.dart';
import 'package:logger/logger.dart';

import '../models/volume_model.dart';

Logger _logger = getLogger('ControlPanelModel', Level.debug);

class ControlPanel extends StatefulWidget {

  const ControlPanel({super.key});

  @override
  State<ControlPanel> createState() => _ControlPanelState();
}

class _ControlPanelState extends State<ControlPanel> {
  final ControlPanelModel controlPanel = ControlPanelModel();
  final VolumeModel volumeModel = VolumeModel(0);

  double vol = 0.0;

  @override
  Widget build(BuildContext context) {
    Provider.debugCheckInvalidValueType = null;
    double progress = Provider.of<Progress>(context).value;
    double length = Provider.of<CurrentTrackModel>(context).lengthInSeconds();

    return BottomAppBar(
      child: SizedBox(
        height: 140.0,
        child: Column(
          children: [
            const Padding(padding: EdgeInsets.only(bottom: 5.0)),
            //LinearProgressIndicator(value: progress),
            // TODO show correct progress - eg after 'stop after song'
            // TODO control progress manually
            LinearPercentIndicator(
                width: MediaQuery.of(context).size.width - 90,
                lineHeight: 14.0,
                percent: progress <= 1.0 ? progress : 1.0,
                leading: Text(progressToTime(length, progress)),
                trailing: Text('-${progressToTime(length, 1-progress)}'),
                backgroundColor: Colors.grey,
                progressColor: Colors.blue,
                alignment: MainAxisAlignment.center,
              ),

            const Padding(padding: EdgeInsets.only(bottom: 15.0)),

            // volume
            Row(
              //mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 30.0),
                    child: Icon(Icons.volume_down),
                  ),
                  Flexible(
                    flex: 1,
                    child: Slider(
                        //activeColor: Colors.indigoAccent,
                        min: 0.0,
                        max: 1.0,
                        onChanged: (double newValue) {

                          _logger.d('Volume: $newValue');
                          /*setState(() {
                            vol = newValue;
                          });*/
                          volumeModel.addEvent(newValue);
                          //(Provider.of<ControlPanelModel>(context, listen:false)).showVolume(newValue); // update slider
                        },
                        onChangeEnd: (double newValue) {
                          controlPanel.adjustVolume(newValue);
                        },
                        value: Provider.of<Volume>(context).value,
                      ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(right: 30.0),
                    child: Icon(Icons.volume_up),
                  ),
                ]),

            // prev, pause/play, next, random
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                IconButton(
                    icon: const Icon(Icons.skip_previous),
                    iconSize: 30.0,
                    onPressed: () {
                      controlPanel.previous();
                    }),
                IconButton(
                    icon: Consumer<ControlPanelModel>(builder: (context, controlPanel, child) {
                      return Icon(controlPanel.playing ? Icons.pause : Icons.play_arrow);}),
                    iconSize: 30.0,
                    onPressed: () {
                      controlPanel.togglePlayPause();
                    }),
                IconButton(
                    icon: const Icon(Icons.skip_next),
                    iconSize: 30.0,
                    onPressed: () {
                      controlPanel.next();
                    }),
                IconButton(
                    icon: const Icon(Icons.autorenew),
                    iconSize: 30.0,
                    onPressed: () {
                      controlPanel.randomAlbum();
                    }),
                IconButton(
                  //icon: Icon(Icons.control_point),
                    icon: const Icon(Icons.not_interested),
                    iconSize: 30.0,
                    onPressed: () {
                      controlPanel.stopAfter();
                    }
                )
              ],
            )],
        ),
      ),
    );
  }

  String progressToTime(double length, double progress) {
    Duration d = Duration(seconds: (length * progress).toInt());
    int h = d.inHours;
    int m = d.inMinutes.remainder(60);
    int s = d.inSeconds.remainder(60);
    String mt = (h > 0) & (m < 10) ? '0$m' : '$m';
    String st = (s < 10) ? '0$s' : '$s';
    return '${h > 0 ? '$h:' : ''}$mt:$st';
  }
}


