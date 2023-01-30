import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'dart:collection';

Logger getLogger(String className, [Level level = Level.debug]) {
  final Logger logger = Logger(
    printer: SimpleLogPrinter(className),
    level: level
  );
  //Logger.level = level;
  return  logger;
}

class SimpleLogPrinter extends LogPrinter {
  final String className;
  final Log _log = Log();
  SimpleLogPrinter(this.className);

  @override
  List<String>  log(LogEvent event) {   // Level level, message, error, StackTrace stackTrace) {
    //var color = PrettyPrinter.levelColors[Level.info];
    //var color = PrettyPrinter.levelColors[Level.debug]; // no color -> cleaner in IDE console
    var color = PrettyPrinter.levelColors[event.level];
    var emoji = PrettyPrinter.levelEmojis[event.level];
    String msg = color!('$emoji ${event.message} [$className]');
    //println(_msg);
    _log.message = msg;
    return [msg];
  }
}

const int _lenQ = 100;

class Log extends ChangeNotifier {
  static final Log _log = Log._internal();
  String logTxt = 'logging commenced';
  final Queue _logQ = Queue();

  factory Log() {
    return _log;
  }

  Log._internal() {
    _logQ.add(logTxt);
  }

  set message(msg) => _logMessage(msg);
  List get messages => _logQ.toList();

  void _logMessage(msg) {
    if (_logQ.length >= _lenQ) {
      _logQ.removeFirst();
    }
    DateTime t = DateTime.now().toLocal();
    _logQ.add('${t.hour}:${t.minute}:${t.second}: $msg');

    // avoid errors when navigating to other pages that cause logs_page to rebuild
    scheduleMicrotask((){
      notifyListeners();
    });
  }
}