import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/shared.dart';

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
    return BlocProvider.value(
      value: deps.authCubit,
      child: MaterialApp.router(
        title: 'Trainer',
        themeMode: ThemeMode.system,
        theme: AppTheme.light(AppColors.trainerPrimary),
        darkTheme: AppTheme.dark(AppColors.trainerPrimary),
        routerConfig: buildRouter(deps.authCubit),
      ),
    );
  }
}
