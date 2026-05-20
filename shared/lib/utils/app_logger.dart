import 'package:flutter/foundation.dart';

enum LogTag { chat, rtc, schedule, auth, notif }

class AppLogger {
  static final List<String> _logs = <String>[];

  static void log(LogTag tag, String message) {
    final entry = '[${tag.name.toUpperCase()}] ${_ts()} $message';
    if (_logs.length >= 20) _logs.removeAt(0);
    _logs.add(entry);
    if (kDebugMode) debugPrint(entry);
  }

  static String _ts() => DateTime.now().toIso8601String().substring(11, 19);

  static List<String> get recent => List.unmodifiable(_logs);
}
