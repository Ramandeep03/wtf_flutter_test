import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import 'core/bloc_observer.dart';
import 'core/hive_init.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveInit.initialize();
  Bloc.observer = AppBlocObserver();
  runApp(const GuruApp());
}

class GuruApp extends StatelessWidget {
  const GuruApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Guru',
      themeMode: ThemeMode.system,
      theme: AppTheme.light(AppColors.guruPrimary),
      darkTheme: AppTheme.dark(AppColors.guruPrimary),
      home: Scaffold(
        appBar: AppBar(title: const Text('Guru')),
        body: const Center(
          child: Text('P06 — ApiClient + Hive + theme ready. Auth screens land in P07.'),
        ),
      ),
    );
  }
}
