import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import 'core/bloc_observer.dart';
import 'core/hive_init.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveInit.initialize();
  Bloc.observer = AppBlocObserver();
  runApp(const TrainerApp());
}

class TrainerApp extends StatelessWidget {
  const TrainerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trainer',
      themeMode: ThemeMode.system,
      theme: AppTheme.light(AppColors.trainerPrimary),
      darkTheme: AppTheme.dark(AppColors.trainerPrimary),
      home: Scaffold(
        appBar: AppBar(title: const Text('Trainer')),
        body: const Center(
          child: Text('P06 — ApiClient + Hive + theme ready. Auth screens land in P07.'),
        ),
      ),
    );
  }
}
