import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../blocs/auth_cubit.dart';
import '../blocs/post_call_cubit.dart';
import '../utils/app_theme.dart';
import '../utils/extensions.dart';
import '../utils/snackbar_helper.dart';

class PostCallView extends StatelessWidget {
  const PostCallView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthCubit>().state.userOrNull;
    final isMember = user?.isMember ?? true;
    return BlocConsumer<PostCallCubit, PostCallState>(
      listenWhen: (p, c) => p.phase != c.phase,
      listener: (ctx, state) {
        switch (state.phase) {
          case PostCallPhase.saved:
            SnackbarHelper.showSuccess(ctx, 'Session saved to your logs.');
            ctx.push('/sessions');
          case PostCallPhase.failed:
            SnackbarHelper.showError(
                ctx, state.error ?? 'Could not save session');
          case _:
        }
      },
      builder: (ctx, state) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: switch (state.phase) {
              PostCallPhase.creating =>
                const Center(child: CircularProgressIndicator()),
              _ => isMember ? const _MemberSheet() : const _TrainerSheet(),
            },
          ),
        ),
      ),
    );
  }
}

class _MemberSheet extends StatelessWidget {
  const _MemberSheet();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PostCallCubit, PostCallState>(
      builder: (ctx, state) {
        final cubit = ctx.read<PostCallCubit>();
        final saving = state.phase == PostCallPhase.saving;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('How was your session?', style: AppTypography.h2),
            const SizedBox(height: AppSpacing.lg),
            _StarRating(selected: state.rating, onSelect: cubit.setRating),
            const SizedBox(height: AppSpacing.md),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Add a note…',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: cubit.setMemberNote,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saving ? null : cubit.save,
                child: saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit Rating'),
              ),
            ),
            TextButton(
              onPressed: () => context.push('/sessions'),
              child: const Text('Skip'),
            ),
          ],
        );
      },
    );
  }
}

class _TrainerSheet extends StatelessWidget {
  const _TrainerSheet();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PostCallCubit, PostCallState>(
      builder: (ctx, state) {
        final cubit = ctx.read<PostCallCubit>();
        final saving = state.phase == PostCallPhase.saving;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Session complete', style: AppTypography.h2),
            const SizedBox(height: AppSpacing.sm),
            if (state.log != null)
              Text(
                'Duration: ${state.log!.durationSec.toMMSS()}',
                style:
                    AppTypography.body.copyWith(color: AppColors.textSecondary),
              ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Add session notes…',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              onChanged: cubit.setTrainerNote,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saving ? null : cubit.save,
                child: saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Mark as Complete'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StarRating extends StatelessWidget {
  final int? selected;
  final void Function(int) onSelect;
  const _StarRating({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          5,
          (i) => GestureDetector(
            onTap: () => onSelect(i + 1),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: Icon(
                i < (selected ?? 0) ? Icons.star : Icons.star_border,
                key: ValueKey('star_${i}_${selected ?? 0}'),
                color: Colors.amber,
                size: 36,
              ),
            ),
          ),
        ),
      );
}
