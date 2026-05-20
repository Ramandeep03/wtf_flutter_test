import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) => const LoginForm(
        prefillEmail: 'dk@wtf.fit',
        prefillPassword: 'Wtf@1234',
        headline: 'WTF Fitness — Guru',
      );
}
