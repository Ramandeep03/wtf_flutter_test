import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/shared.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

import 'core/bloc_observer.dart';
import 'core/di.dart';
import 'core/hive_init.dart';
import 'core/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveInit.initialize();
  Bloc.observer = AppBlocObserver();
  runApp(TrainerApp(deps: AppDependencies()));
}

class TrainerApp extends StatelessWidget {
  final AppDependencies deps;
  const TrainerApp({super.key, required this.deps});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>.value(value: deps.authCubit),
        BlocProvider<StreamChatCubit>.value(value: deps.streamChatCubit),
      ],
      child: BlocListener<AuthCubit, AuthState>(
        listener: (ctx, state) {
          switch (state) {
            case ApiSuccess(:final data):
              ctx.read<StreamChatCubit>().connect(data);
            case _:
              ctx.read<StreamChatCubit>().disconnect();
          }
        },
        child: MaterialApp.router(
          title: 'Trainer',
          themeMode: ThemeMode.system,
          theme: AppTheme.light(AppColors.trainerPrimary),
          darkTheme: AppTheme.dark(AppColors.trainerPrimary),
          routerConfig: buildRouter(deps.authCubit),
          builder: (ctx, child) => StreamChat(
            client: StreamChatService.instance.client,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
