import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/shared.dart';

class SessionsPage extends StatelessWidget {
  const SessionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthCubit>().state.userOrNull;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return BlocProvider(
      create: (_) => SessionLogsCubit(
        repo: SessionLogRepository(),
        userId: user.uid,
      ),
      child: const SessionsView(),
    );
  }
}
