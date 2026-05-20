import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

class ConversationPage extends StatelessWidget {
  const ConversationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamChatTheme(
      data: StreamChatThemeData.fromTheme(Theme.of(context)).copyWith(
        ownMessageTheme: const StreamMessageThemeData(
          messageBackgroundColor: AppColors.guruPrimary,
        ),
        otherMessageTheme: StreamMessageThemeData(
          messageBackgroundColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.bgSurfaceDark
              : AppColors.bgSurface,
        ),
      ),
      child: const ConversationView(),
    );
  }
}
