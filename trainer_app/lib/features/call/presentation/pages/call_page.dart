import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// See guru_app/.../call_page.dart for why this is a redirect stub.
class CallPage extends StatelessWidget {
  const CallPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Call')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('No active call.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.push('/home'),
              child: const Text('Back home'),
            ),
          ],
        ),
      ),
    );
  }
}
