import 'package:flutter/material.dart';

class PostCallPage extends StatelessWidget {
  final Object? extra;
  const PostCallPage({super.key, this.extra});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Post-Call')),
        body: const Center(child: Text('Post-Call — implemented in a later phase.')),
      );
}
