import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/shared.dart';

class PreJoinPage extends StatelessWidget {
  final String callRequestId;
  final String role;
  const PreJoinPage({super.key, required this.callRequestId, required this.role});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => PreJoinCubit(callRequestId: callRequestId, role: role),
        ),
        BlocProvider(create: (_) => CallBloc()),
      ],
      child: PreJoinView(role: role),
    );
  }
}
