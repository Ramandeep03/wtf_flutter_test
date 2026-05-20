import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

import '../models/user_entity.dart';
import '../utils/app_logger.dart';
import '../utils/constants.dart';
import 'api_client.dart';
import 'notification_service.dart';

/// Wraps the Stream Chat client and gates lifecycle on the backend token.
/// Singleton so the `StreamChat` widget can read `instance.client` directly.
class StreamChatService {
  static final StreamChatService instance = StreamChatService._();
  StreamChatService._();

  final StreamChatClient client = StreamChatClient(
    AppConstants.streamChatApiKey,
    logLevel: Level.OFF,
  );

  bool _connected = false;
  StreamSubscription<Event>? _msgSub;
  bool get isConnected => _connected;

  Future<void> connect(UserEntity user) async {
    if (_connected) return;
    try {
      final data = await ApiClient.instance.get('/stream-token');
      final token = data['token'] as String;
      await client.connectUser(
        User(id: user.uid, extraData: {
          'name': user.name,
          'role': user.role,
        }),
        token,
      );
      _connected = true;
      _startMessageNotifications();
      AppLogger.log(LogTag.chat, 'Stream connected uid=${user.uid}');
    } catch (e) {
      AppLogger.log(LogTag.chat, 'Stream connect error: $e');
      rethrow;
    }
  }

  /// Notify the user about incoming messages — but only when the app
  /// isn't in the foreground (otherwise the in-app chat UI already shows them).
  void _startMessageNotifications() {
    _msgSub?.cancel();
    _msgSub = client.on(EventType.messageNew).listen((event) async {
      final myUid = client.state.currentUser?.id;
      if (event.message?.user?.id == myUid) return; // skip own messages
      final isForeground = SchedulerBinding.instance.lifecycleState ==
          AppLifecycleState.resumed;
      if (isForeground) return;
      await NotificationService.instance.show(
        id: NotifId.newMessage,
        title: 'New message from ${event.message?.user?.name ?? 'Trainer'}',
        body: event.message?.text ?? '',
        payload: 'chat:${event.channelId ?? ''}',
      );
    });
  }

  Future<void> disconnect() async {
    if (!_connected) return;
    await _msgSub?.cancel();
    _msgSub = null;
    await client.disconnectUser();
    _connected = false;
    AppLogger.log(LogTag.chat, 'Stream disconnected');
  }

  /// Deterministic 1:1 channel id (sorted UIDs avoid order-dependent dupes).
  Channel getOrCreateChannel(String memberUid, String trainerUid) {
    final ids = [memberUid, trainerUid]..sort();
    return client.channel(
      'messaging',
      id: 'chat-${ids[0]}-${ids[1]}',
      extraData: {
        'members': [memberUid, trainerUid],
      },
    );
  }
}
