import 'package:flutter/material.dart';

void main() => runApp(const GuruApp());

class GuruApp extends StatelessWidget {
  const GuruApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Guru',
      home: Scaffold(
        appBar: AppBar(title: const Text('Guru')),
        body: const Center(child: Text('P01 scaffold — wired up in later phases.')),
      ),
    );
  }
}
