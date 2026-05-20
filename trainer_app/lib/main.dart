import 'package:flutter/material.dart';

void main() => runApp(const TrainerApp());

class TrainerApp extends StatelessWidget {
  const TrainerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trainer',
      home: Scaffold(
        appBar: AppBar(title: const Text('Trainer')),
        body: const Center(child: Text('P01 scaffold — wired up in later phases.')),
      ),
    );
  }
}
