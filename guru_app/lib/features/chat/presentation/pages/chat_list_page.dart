import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/shared.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<StreamChatCubit, StreamChatState>(
      listener: (ctx, state) async {
        if (state is! ApiSuccess) return;
        final user = ctx.read<AuthCubit>().state.userOrNull;
        if (user == null) return;
        final channel = StreamChatService.instance.getOrCreateChannel(
          user.isMember ? user.uid : user.assignedTrainerId ?? '',
          user.isTrainer ? user.uid : user.assignedTrainerId ?? '',
        );
        await channel.watch();
        AppLogger.log(LogTag.chat, 'channel watching id=${channel.id}');
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Chats')),
        body: BlocBuilder<StreamChatCubit, StreamChatState>(
          builder: (ctx, state) => Center(
            child: switch (state) {
              ApiInitial() || ApiLoading() => const CircularProgressIndicator(),
              ApiSuccess() => const Text('Connected — channel list lands in P09.'),
              ApiFailure(:final error) =>
                Text('Chat connection failed:\n${error.message}', textAlign: TextAlign.center),
              _ => const SizedBox.shrink(),
            },
          ),
        ),
      ),
    );
  }
}
