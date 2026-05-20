import 'package:api_state/api_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../blocs/auth_cubit.dart';
import '../blocs/call_bloc.dart';
import '../blocs/pre_join_cubit.dart';
import '../models/session_log_draft.dart';
import '../utils/app_theme.dart';
import '../utils/snackbar_helper.dart';
import 'call_view.dart';

/// Pre-join + in-call swap-on-phase. Keeping both views inside the same
/// route preserves the `CallBloc` across the join → in-call transition;
/// pushReplacement would have destroyed the bloc mid-SDK-handshake.
class PreJoinView extends StatelessWidget {
  final String role;
  final String memberId;
  final String trainerId;
  const PreJoinView({
    super.key,
    required this.role,
    required this.memberId,
    required this.trainerId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CallBloc, CallState>(
      listener: (ctx, callState) {
        switch (callState.phase) {
          case CallPhase.failed when callState.joinedAt == null:
            if (callState.errorMessage != null) {
              SnackbarHelper.showError(ctx, callState.errorMessage!);
            }
            ctx.pop();
          case CallPhase.ended || CallPhase.failed:
            if (callState.joinedAt != null) {
              final draft = SessionLogDraft(
                joinedAt: callState.joinedAt!,
                endedAt: DateTime.now(),
                memberId: memberId,
                trainerId: trainerId,
              );
              ctx.pushReplacement('/post-call', extra: draft);
            }
          case _:
        }
      },
      builder: (ctx, callState) {
        if (callState.phase == CallPhase.inCall ||
            (callState.phase == CallPhase.joining && callState.joinedAt != null)) {
          return const CallView();
        }
        return _PreJoinScaffold(role: role);
      },
    );
  }
}

class _PreJoinScaffold extends StatelessWidget {
  final String role;
  const _PreJoinScaffold({required this.role});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthCubit>().state.userOrNull;
    return BlocBuilder<PreJoinCubit, PreJoinState>(
      builder: (ctx, s) => BlocBuilder<CallBloc, CallState>(
        builder: (ctx, callState) => Scaffold(
          body: SafeArea(
            child: Column(
              children: [
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
                          child: callState.phase == CallPhase.joining
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
      s.loadStatus is ApiSuccess<String> &&
      callState.phase == CallPhase.idle;
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
