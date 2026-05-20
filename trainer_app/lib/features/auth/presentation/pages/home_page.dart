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
            roleName: 'Trainer',
            primaryColor: AppColors.trainerPrimary,
            onLogout: () => ctx.read<AuthCubit>().logout(),
          ),
          body: GridView.count(
            crossAxisCount: 2,
            padding: const EdgeInsets.all(AppSpacing.md),
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            children: [
              _Tile(
                  icon: Icons.people_outline,
                  label: 'Members',
                  onTap: () => ctx.push('/members')),
              _Tile(
                  icon: Icons.chat_bubble_outline,
                  label: 'Chats',
                  onTap: () => ctx.push('/chat')),
              _Tile(
                  icon: Icons.event_available,
                  label: 'Requests',
                  onTap: () => ctx.push('/requests')),
              _Tile(
                  icon: Icons.history,
                  label: 'Sessions',
                  onTap: () => ctx.push('/sessions')),
            ],
          ),
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _Tile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 36, color: AppColors.trainerPrimary),
                const SizedBox(height: AppSpacing.sm),
                Text(label, style: AppTypography.body),
              ],
            ),
          ),
        ),
      );
}
