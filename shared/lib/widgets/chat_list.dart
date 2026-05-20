import 'dart:async';

import 'package:api_state/api_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' hide StreamChatState;

import '../blocs/auth_cubit.dart';
import '../blocs/stream_chat_cubit.dart';
import '../services/stream_chat_service.dart';
import '../utils/app_logger.dart';
import '../utils/app_theme.dart';
import '../utils/extensions.dart';
import 'error_retry_widget.dart';
import 'role_app_bar.dart';
import 'skeleton_list.dart';

/// Shared chat list — same widget in both apps. Per-app `ChatListPage`
/// just instantiates it (and the router slot supplies the role from
/// the authenticated user).
class ChatListView extends StatefulWidget {
  const ChatListView({super.key});

  @override
  State<ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends State<ChatListView> {
  StreamChannelListController? _ctrl;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthCubit>().state.userOrNull;
    if (user == null) return;
    _ctrl = StreamChannelListController(
      client: StreamChatService.instance.client,
      filter: Filter.in_('members', [user.uid]),
      channelStateSort: const [SortOption<ChannelState>('last_message_at')],
      limit: 20,
    );
    _ctrl!.doInitialLoad();
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthCubit>().state.userOrNull;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final primary = user.isTrainer ? AppColors.trainerPrimary : AppColors.guruPrimary;

    return Scaffold(
      appBar: RoleAppBar(
        userName: user.name,
        roleName: user.isTrainer ? 'Trainer' : 'Member',
        primaryColor: primary,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primary,
        onPressed: () => context.push('/chat/conv'),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: BlocBuilder<StreamChatCubit, StreamChatState>(
        builder: (ctx, chatState) {
          if (chatState is ApiLoading || chatState is ApiInitial) {
            return const SkeletonList(itemCount: 3);
          }
          if (chatState case ApiFailure(:final error)) {
            return ErrorRetryWidget(
              message: error.message,
              onRetry: () => ctx.read<StreamChatCubit>().connect(user),
            );
          }
          // Connected — render the channel list.
          if (_ctrl == null) {
            return const SkeletonList(itemCount: 3);
          }
          return StreamChannelListView(
            controller: _ctrl!,
            onChannelTap: (_) => context.push('/chat/conv'),
            emptyBuilder: (_) => const _EmptyChat(),
            errorBuilder: (_, e) => ErrorRetryWidget(
              message: e.toString(),
              onRetry: _ctrl!.doInitialLoad,
            ),
            loadingBuilder: (_) => const SkeletonList(itemCount: 3),
            itemBuilder: (_, channels, i, __) => _ChannelTile(
              channel: channels[i],
              primaryColor: primary,
              onTap: () => context.push('/chat/conv'),
            ),
          );
        },
      ),
    );
  }
}

class _ChannelTile extends StatefulWidget {
  final Channel channel;
  final Color primaryColor;
  final VoidCallback onTap;

  const _ChannelTile({
    required this.channel,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  State<_ChannelTile> createState() => _ChannelTileState();
}

class _ChannelTileState extends State<_ChannelTile> {
  // Subscribe to the channel's in-place state changes — Stream mutates
  // ChannelState in-place on every event, so the parent list controller
  // never tells us to rebuild. We listen to messages + unread streams
  // directly and setState to redraw this tile when either changes.
  StreamSubscription<List<Message>>? _msgSub;
  StreamSubscription<int>? _unreadSub;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(covariant _ChannelTile old) {
    super.didUpdateWidget(old);
    if (old.channel.cid != widget.channel.cid) {
      _msgSub?.cancel();
      _unreadSub?.cancel();
      _subscribe();
    }
  }

  void _subscribe() {
    final state = widget.channel.state;
    if (state == null) return;
    _msgSub = state.messagesStream.listen((_) {
      if (mounted) setState(() {});
    });
    _unreadSub = state.unreadCountStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    _unreadSub?.cancel();
    super.dispose();
  }

  String _peerName() {
    final myUid = StreamChatService.instance.client.state.currentUser?.id;
    final members = widget.channel.state?.members ?? const [];
    if (members.isEmpty) return 'User';
    final peer = members.firstWhere(
      (m) => m.userId != myUid,
      orElse: () => members.first,
    );
    return peer.user?.name ?? 'User';
  }

  @override
  Widget build(BuildContext context) {
    final channel = widget.channel;
    final primaryColor = widget.primaryColor;
    final onTap = widget.onTap;
    final unread  = channel.state?.unreadCount ?? 0;
    final lastMsg = channel.state?.messages.lastOrNull;
    final name = _peerName();
    final initial = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: primaryColor,
        child: Text(
          initial,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      title: Text(name, style: AppTypography.body),
      subtitle: Text(
        lastMsg?.text ?? 'No messages yet',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (lastMsg != null)
            Text(lastMsg.createdAt.toRelativeString(), style: AppTypography.label),
          if (unread > 0) ...[
            const SizedBox(height: 4),
            CircleAvatar(
              radius: 9,
              backgroundColor: AppColors.error,
              child: Text(
                '$unread',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.chat_bubble_outline,
              size: 72,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'No messages yet. Start the conversation.',
              style: AppTypography.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: () => context.push('/chat/conv'),
              child: const Text('Say hi 👋'),
            ),
          ],
        ),
      );
}

/// Used by ChatListView to log the watched channel id once it appears.
void logChannelWatched(Channel channel) {
  AppLogger.i(LogTag.chat, 'channel watching id=${channel.id}');
}
