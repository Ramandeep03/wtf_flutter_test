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
  runApp(GuruApp(deps: AppDependencies()));
}

class GuruApp extends StatelessWidget {
  final AppDependencies deps;
  const GuruApp({super.key, required this.deps});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: deps.authCubit,
      child: MaterialApp.router(
        title: 'Guru',
        themeMode: ThemeMode.system,
        theme: AppTheme.light(AppColors.guruPrimary),
        darkTheme: AppTheme.dark(AppColors.guruPrimary),
        routerConfig: buildRouter(deps.authCubit),
      ),
    );
  }
}
