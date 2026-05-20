import 'package:api_state/api_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../blocs/auth_cubit.dart';
import '../blocs/call_bloc.dart';
import '../blocs/pre_join_cubit.dart';
import '../utils/app_theme.dart';
import '../utils/snackbar_helper.dart';

/// Shared pre-join screen. Per-app `PreJoinPage` instantiates the cubits
/// and provides this view inside a `MultiBlocProvider`.
class PreJoinView extends StatelessWidget {
  final String role;
  const PreJoinView({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthCubit>().state.userOrNull;
    return BlocConsumer<CallBloc, CallState>(
      listener: (ctx, callState) {
        switch (callState) {
          case ApiSuccess():
            ctx.pushReplacement('/call');
          case ApiFailure(:final error):
            SnackbarHelper.showError(ctx, error.message);
          case _:
        }
      },
      builder: (ctx, callState) => BlocBuilder<PreJoinCubit, PreJoinState>(
        builder: (ctx, s) => Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                // Camera placeholder — actual local preview lands with the
                // 100ms SDK plumbing in P13.
                Expanded(
                  child: Container(
                    color: Colors.black,
                    child: const Center(
                      child: Icon(Icons.videocam, size: 80, color: Colors.white38),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      switch (s.loadStatus) {
                        ApiInitial() || ApiLoading() => const Text(
                            'Loading room…',
                            style: AppTypography.bodySmall,
                          ),
                        ApiFailure(:final error) => Text(
                            error.message,
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ApiSuccess() => const Text(
                            'Ready to join? Check mic and camera.',
                            style: AppTypography.body,
                            textAlign: TextAlign.center,
                          ),
                        _ => const SizedBox.shrink(),
                      },
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _DeviceToggle(
                            icon: s.isMicOn ? Icons.mic : Icons.mic_off,
                            label: 'Mic',
                            active: s.isMicOn,
                            onTap: () => ctx.read<PreJoinCubit>().toggleMic(),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          _DeviceToggle(
                            icon: s.isCameraOn ? Icons.videocam : Icons.videocam_off,
                            label: 'Camera',
                            active: s.isCameraOn,
                            onTap: () => ctx.read<PreJoinCubit>().toggleCamera(),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Role: ${role == 'trainer' ? 'Trainer' : 'Member'}',
                        style: AppTypography.label.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _joinEnabled(s, callState)
                              ? () {
                                  final roomId = (s.loadStatus as ApiSuccess<String>).data;
                                  ctx.read<CallBloc>().add(CallJoinRequested(
                                        roomId: roomId,
                                        userId: user!.uid,
                                        userName: user.name,
                                        role: role,
                                      ));
                                }
                              : null,
                          child: callState is ApiLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Join Call'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextButton(
                        onPressed: () => context.pop(),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _joinEnabled(PreJoinState s, CallState callState) =>
      s.loadStatus is ApiSuccess<String> && callState is! ApiLoading;
}

class _DeviceToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _DeviceToggle({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final restingBg = isDark ? AppColors.bgSurfaceDark : AppColors.bgSurface;
    final restingBorder = isDark ? AppColors.borderDark : AppColors.borderLight;
    final restingFg = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: active ? restingBg : AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: active ? restingBorder : AppColors.error,
                width: 1.5,
              ),
            ),
            child: Icon(icon, color: active ? restingFg : AppColors.error),
          ),
          const SizedBox(height: 4),
          Text(label, style: AppTypography.label),
        ],
      ),
    );
  }
}
