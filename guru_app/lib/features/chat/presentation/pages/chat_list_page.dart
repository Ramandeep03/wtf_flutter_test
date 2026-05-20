import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/shared.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<StreamChatCubit, StreamChatState>(
      listenWhen: (prev, curr) => prev is! ApiSuccess && curr is ApiSuccess,
      listener: (ctx, _) async {
        final user = ctx.read<AuthCubit>().state.userOrNull;
        if (user == null) return;
        final channel = StreamChatService.instance.getOrCreateChannel(
          user.isMember ? user.uid : user.assignedTrainerId ?? '',
          user.isTrainer ? user.uid : user.assignedTrainerId ?? '',
        );
        await channel.watch();
        logChannelWatched(channel);
      },
      child: const ChatListView(),
    );
  }
}
