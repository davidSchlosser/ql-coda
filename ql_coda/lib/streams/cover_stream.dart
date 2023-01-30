import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:coda/models/cover_model.dart';
import 'package:coda/communicator.dart';
import 'package:coda/logger.dart';
import 'package:logger/logger.dart';

Logger _logger = getLogger('coverStream', Level.warning);

class CoverStream {
  Uint8List cover = Uint8List(0);
  //static late final Uint8List blank; //Base64Decoder().convert('');
  String? id;
  int remaining = 0;
  String? name;

  static StreamController<CoverModel> coverStreamController = StreamController<CoverModel>();

  CoverStream(){
    Communicator().subscribe('mqinvoke/cover-image', coverMsgHandler);
    //_logger.d('CoverStream constructor');
  }

  void coverMsgHandler(String message) {
    //_logger.d('coverMsgHandler: $message');
    if (unslice(message)) {
      coverStreamController.add(CoverModel.fromUint8List(cover));
    }
  }

  Stream<CoverModel> coverStream() {
    //_logger.d('coverStream constructor');
    return coverStreamController.stream;
  }

  List<String> pieces = [];

  bool unslice(String message) {
    //_logger.d('unslice');
    Map c = const JsonDecoder().convert(message);
    if (id != c['pic_id']) {
      // reset for new image
      //self.cover = null;
      name = c['name'];
      id = c['pic_id'];
      remaining = c['size'] as int;
      pieces = List<String>.filled(c['size'] as int, '');
      if (remaining == 0) {
        cover = Uint8List(0);
        return true;
      }
    }
    // more of same cover..
    if (remaining > 0) {
      //print("pos: ${_c['pos']}");
      if (pieces[c['pos']] == '') {
        pieces[c['pos']] = c['data'];
        //print("fill piece at: ${_c['pos']}");
        remaining -= 1;
        if (remaining == 0) {
          cover = const Base64Decoder().convert(pieces.join(''));
          return true;
        }
      }
    }
    return false;
    //print('${coverImage.id}: ${coverImage.remaining} of ${_c['size']} remaining');
  }

}

