import 'package:flutter/material.dart';

class PreJoinPage extends StatelessWidget {
  final String roomId;
  final String role;
  const PreJoinPage({super.key, required this.roomId, required this.role});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Pre-Join')),
        body: Center(child: Text('Pre-Join — roomId=$roomId, role=$role (later phase).')),
      );
}
