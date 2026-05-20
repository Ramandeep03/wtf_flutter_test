import 'package:flutter/material.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Chats')),
        body: const Center(child: Text('Chats — implemented in a later phase.')),
      );
}
