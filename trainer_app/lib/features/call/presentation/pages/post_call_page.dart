import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/shared.dart';

class PostCallPage extends StatelessWidget {
  final Object? extra;
  const PostCallPage({super.key, this.extra});

  @override
  Widget build(BuildContext context) {
    final draft = extra is SessionLogDraft ? extra as SessionLogDraft : null;
    if (draft == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Post-Call')),
        body: const Center(child: Text('No active session to log.')),
      );
    }
    if (draft.memberId == null || draft.trainerId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Post-Call')),
        body: const Center(
          child: Text('Session log requires memberId + trainerId.'),
        ),
      );
    }
    return BlocProvider(
      create: (_) => PostCallCubit(
        repo: SessionLogRepository(),
        draft: draft,
        memberId: draft.memberId!,
        trainerId: draft.trainerId!,
      ),
      child: const PostCallView(),
    );
  }
}
