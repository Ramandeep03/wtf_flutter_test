import 'package:api_state/api_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/auth_cubit.dart';
import '../models/user_entity.dart';
import '../utils/app_theme.dart';
import '../utils/snackbar_helper.dart';

/// Email + password form. Per-app `LoginPage` wraps this with role-specific
/// prefill (dk@wtf.fit for guru, aarav@wtf.fit for trainer).
class LoginForm extends StatefulWidget {
  final String prefillEmail;
  final String prefillPassword;
  final String headline;

  const LoginForm({
    super.key,
    this.prefillEmail = '',
    this.prefillPassword = '',
    this.headline = 'WTF Fitness',
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  late final TextEditingController _emailCtrl;
  late final TextEditingController _passwordCtrl;

  @override
  void initState() {
    super.initState();
    _emailCtrl    = TextEditingController(text: widget.prefillEmail);
    _passwordCtrl = TextEditingController(text: widget.prefillPassword);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, ApiStatus<UserEntity>>(
      listener: (ctx, state) {
        if (state is ApiFailure<UserEntity>) {
          SnackbarHelper.showError(ctx, state.error.message);
        }
      },
      builder: (ctx, state) {
        final isLoading = state is ApiLoading;
        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(widget.headline, style: AppTypography.h1),
                    const SizedBox(height: AppSpacing.xxl),
                    TextField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _passwordCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password'),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () => ctx.read<AuthCubit>().login(
                                  _emailCtrl.text.trim(),
                                  _passwordCtrl.text.trim(),
                                ),
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Sign In'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
