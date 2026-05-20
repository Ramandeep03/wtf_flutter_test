import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

import '../blocs/auth_cubit.dart';
import '../services/stream_chat_service.dart';
import '../utils/app_logger.dart';
import '../utils/app_theme.dart';

/// Shared chat conversation view. Per-app `ConversationPage` wraps it
/// inside a `StreamChatTheme` configured with the role's primary color
/// so own-message bubbles match the brand.
class ConversationView extends StatefulWidget {
  const ConversationView({super.key});

  @override
  State<ConversationView> createState() => _ConversationViewState();
}

class _ConversationViewState extends State<ConversationView> {
  Channel? _channel;
  StreamSubscription<List<Message>>? _msgSub;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthCubit>().state.userOrNull;
    if (user == null) return;
    final channel = StreamChatService.instance.channelWithPeer(user);
    _channel = channel;
    if (channel == null) return;
    _initChannel(channel);
  }

  Future<void> _initChannel(Channel channel) async {
    try {
      await channel.watch();
      await channel.markRead();
      AppLogger.i(LogTag.chat,
          'marked read channel=${channel.id} unread=${channel.state?.unreadCount}');
    } catch (e) {
      AppLogger.w(LogTag.chat, 'initial markRead failed: $e');
    }

    // While the conversation is open, every new message arriving in this
    // channel should immediately be marked read too (otherwise an incoming
    // ping while you're staring at the screen leaves a stale unread count).
    _msgSub = channel.state?.messagesStream.listen((messages) async {
      try {
        await channel.markRead();
      } catch (e) {
        AppLogger.w(LogTag.chat, 'live markRead failed: $e');
      }
    });
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final channel = _channel;
    if (channel == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return StreamChannel(
      channel: channel,
      child: Scaffold(
        appBar: _ConvAppBar(channel: channel),
        body: Column(
          children: [
            Expanded(
              child: StreamMessageListView(messageBuilder: _messageBuilder),
            ),
            _QuickReplies(channel: channel),
            const StreamMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _messageBuilder(
    BuildContext ctx,
    MessageDetails details,
    List<Message> messages,
    StreamMessageWidget defaultWidget,
  ) {
    if (details.message.extraData['isSystem'] == true) {
      return _SystemBubble(text: details.message.text ?? '');
    }
    return defaultWidget;
  }
}

class _ConvAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Channel channel;
  const _ConvAppBar({required this.channel});

  String _peerName() {
    final myUid = StreamChatService.instance.client.state.currentUser?.id;
    final members = channel.state?.members ?? const [];
    if (members.isEmpty) return 'User';
    final peer = members.firstWhere(
      (m) => m.userId != myUid,
      orElse: () => members.first,
    );
    return peer.user?.name ?? 'User';
  }

  @override
  Widget build(BuildContext context) => AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_peerName(), style: AppTypography.body),
            const Text(
              'Online',
              style: TextStyle(fontSize: 12, color: AppColors.success),
            ),
          ],
        ),
        actions: const [
          // Wired to start a call in P13.
          IconButton(
            icon: Icon(Icons.videocam_outlined),
            onPressed: null,
            tooltip: 'Call (P13)',
          ),
        ],
      );

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _QuickReplies extends StatelessWidget {
  final Channel channel;
  const _QuickReplies({required this.channel});

  static const _chips = ['Got it 👍', 'Can we talk at 6?', 'Share plan?'];

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 44,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          children: _chips
              .map(
                (s) => Padding(
                  padding: const EdgeInsets.only(right: 6, top: 6),
                  child: ActionChip(
                    label: Text(s, style: AppTypography.bodySmall),
                    onPressed: () => channel.sendMessage(Message(text: s)),
                  ),
                ),
              )
              .toList(),
        ),
      );
}

class _SystemBubble extends StatelessWidget {
  final String text;
  const _SystemBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = isDark ? AppColors.bgSurfaceDark : AppColors.bgSurface;
    final border = isDark ? AppColors.borderDark    : AppColors.borderLight;
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Text(
          text,
          style: AppTypography.label.copyWith(
            fontStyle: FontStyle.italic,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Sends a centred-pill system message in the DK↔Aarav channel. Called
/// from approve/decline use cases — *not* the user — in later phases.
Future<void> sendSystemMessage({
  required String memberUid,
  required String trainerUid,
  required String text,
}) async {
  final channel = StreamChatService.instance.getOrCreateChannel(memberUid, trainerUid);
  await channel.sendMessage(
    Message(text: text, extraData: const {'isSystem': true}),
  );
  AppLogger.i(LogTag.chat, 'system msg sent: $text');
}
