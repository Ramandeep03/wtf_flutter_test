import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// `/call` is now reached only by stale deep-link or programmatic push —
/// the live in-call UI lives inside `PreJoinView` and swaps based on
/// `CallPhase` so the `CallBloc` survives the join → in-call transition.
/// If a user lands here directly, send them home.
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
              onPressed: () => context.go('/home'),
              child: const Text('Back home'),
            ),
          ],
        ),
      ),
    );
  }
}
