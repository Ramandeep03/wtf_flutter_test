import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

import '../models/user_entity.dart';
import '../utils/app_logger.dart';
import '../utils/constants.dart';
import '../utils/log_mask.dart';
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

  /// The peer for 1:1 chat — resolved at connect time.
  ///
  /// - member side: `user.assignedTrainerId` (the trainer's uid)
  /// - trainer side: first user with `assignedTrainerId == self.uid`
  ///
  /// Necessary because trainers don't have `assignedTrainerId` populated,
  /// so we can't derive the peer from `UserEntity` alone.
  String? _peerUid;
  String? get peerUid => _peerUid;

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
      await _resolvePeer(user);
      _connected = true;
      _startMessageNotifications();
      AppLogger.i(
        LogTag.chat,
        'connected uid=${LogMask.uid(user.uid)} peer=${LogMask.uid(_peerUid)}',
      );
    } catch (e) {
      AppLogger.e(LogTag.chat, 'connect error', e);
      rethrow;
    }
  }

  Future<void> _resolvePeer(UserEntity user) async {
    if (user.isMember) {
      _peerUid = user.assignedTrainerId;
      return;
    }
    // Trainer: find the first member assigned to us.
    try {
      final users = await ApiClient.instance.getList('/users');
      for (final raw in users) {
        final m = raw as Map<String, dynamic>;
        if (m['role'] == 'member' && m['assignedTrainerId'] == user.uid) {
          _peerUid = (m['uid'] ?? m['id']) as String?;
          return;
        }
      }
      AppLogger.w(LogTag.chat, 'no member assigned to trainer uid=${LogMask.uid(user.uid)}');
    } catch (e) {
      AppLogger.w(LogTag.chat, 'peer lookup failed: $e');
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
    _peerUid = null;
    await client.disconnectUser();
    _connected = false;
    AppLogger.i(LogTag.chat, 'disconnected');
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

  /// Convenience: build the 1:1 channel between the connected user and
  /// their resolved peer. Returns `null` if the peer hasn't been resolved.
  Channel? channelWithPeer(UserEntity me) {
    final peer = _peerUid;
    if (peer == null || peer.isEmpty) return null;
    return getOrCreateChannel(
      me.isMember ? me.uid : peer,
      me.isTrainer ? me.uid : peer,
    );
  }
}
