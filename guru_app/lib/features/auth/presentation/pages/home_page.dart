import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (ctx, state) {
        final user = state.userOrNull;
        return Scaffold(
          appBar: RoleAppBar(
            userName: user?.name ?? '—',
            roleName: 'Guru',
            primaryColor: AppColors.guruPrimary,
            onLogout: () => ctx.read<AuthCubit>().logout(),
          ),
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Text('Hi, ${user?.name ?? ''} 👋', style: AppTypography.h1),
              const SizedBox(height: AppSpacing.lg),
              _HomeCard(
                icon: Icons.chat_bubble_outline,
                label: 'Chat with Trainer',
                onTap: () => ctx.push('/chat'),
              ),
              _HomeCard(
                icon: Icons.calendar_today_outlined,
                label: 'Schedule Call',
                onTap: () => ctx.push('/scheduler'),
              ),
              _HomeCard(
                icon: Icons.history,
                label: 'My Sessions',
                onTap: () => ctx.push('/sessions'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HomeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HomeCard(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        child: ListTile(
          leading: Icon(icon, color: AppColors.guruPrimary),
          title: Text(label, style: AppTypography.body),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );
}
