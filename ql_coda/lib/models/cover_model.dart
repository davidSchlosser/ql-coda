//import 'package:coda/communicator.dart';
import 'package:coda/logger.dart';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

Logger _logger = getLogger('cover', Level.debug);

class CoverModel extends ChangeNotifier {
  Uint8List image = Uint8List(0);

  CoverModel();

  CoverModel.fromUint8List(Uint8List u8l) {
    this.image = u8l;
  }

  Uint8List  cover() {
    return image;
  }
}


