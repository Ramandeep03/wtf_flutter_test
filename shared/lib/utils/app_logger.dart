import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

enum LogTag { auth, chat, rtc, schedule, notif, nav, api }

class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 8,
      lineLength: 100,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    level: kDebugMode ? Level.trace : Level.off,
  );

  // 20-entry ring buffer for the DevPanel (P16+) — no PII per call-site
  // discipline; see LogMask.
  static final List<String> _recent = <String>[];

  static List<String> get recent => List.unmodifiable(_recent);

  static String _ts() => DateTime.now().toIso8601String().substring(11, 19);

  static void _record(LogTag tag, String msg) {
    final entry = '[${tag.name.toUpperCase()}] ${_ts()} $msg';
    if (_recent.length >= 20) _recent.removeAt(0);
    _recent.add(entry);
  }

  static String _prefix(LogTag tag) => '[${tag.name.toUpperCase()}]';

  static void i(LogTag tag, String msg) {
    _record(tag, msg);
    _logger.i('${_prefix(tag)} $msg');
  }

  static void w(LogTag tag, String msg) {
    _record(tag, msg);
    _logger.w('${_prefix(tag)} $msg');
  }

  static void e(LogTag tag, String msg, [Object? error, StackTrace? stackTrace]) {
    _record(tag, '$msg ${error ?? ''}');
    _logger.e('${_prefix(tag)} $msg', error: error, stackTrace: stackTrace);
  }

  static void t(LogTag tag, String msg) {
    _record(tag, msg);
    _logger.t('${_prefix(tag)} $msg');
  }

  /// Backwards-compatible alias for sites still calling `log()`. Logs at
  /// info level. New code should use `i/w/e/t` directly.
  @Deprecated('Use AppLogger.i / .w / .e / .t')
  static void log(LogTag tag, String msg) => i(tag, msg);
}
