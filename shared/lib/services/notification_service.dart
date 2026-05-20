import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../utils/app_logger.dart';

class NotifId {
  static const int callApproved = 1;
  static const int callDeclined = 2;
  static const int callReminder = 3;
  static const int newMessage   = 4;
}

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const AndroidNotificationDetails _channel = AndroidNotificationDetails(
    'wtf_channel',
    'WTF Fitness',
    importance: Importance.high,
    priority: Priority.high,
  );

  static NotificationDetails get _details => const NotificationDetails(
        android: _channel,
        iOS: DarwinNotificationDetails(),
      );

  Future<void> initialize() async {
    if (_ready) return;
    tz_data.initializeTimeZones();
    try {
      final tzName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzName));
    } catch (e) {
      AppLogger.w(LogTag.notif, 'tz lookup failed, falling back to UTC: $e');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (r) {
        AppLogger.i(LogTag.notif, 'tapped payload=${r.payload}');
        // TODO P17: deep-link via payload (e.g. call_join:<id> → /pre-join).
      },
    );
    _ready = true;
    AppLogger.i(LogTag.notif, 'initialized');
  }

  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _details,
      payload: payload,
    );
    AppLogger.i(LogTag.notif, 'shown: $title');
  }

  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
    String? payload,
  }) async {
    if (scheduledAt.isBefore(DateTime.now())) return;
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledAt, tz.local),
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
    AppLogger.i(LogTag.notif, 'scheduled at $scheduledAt: $title');
  }

  Future<void> cancel(int id) async {
    await _plugin.cancel(id: id);
    AppLogger.i(LogTag.notif, 'cancelled id=$id');
  }
}
