import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../blocs/auth_cubit.dart';
import '../blocs/post_call_cubit.dart';
import '../models/session_log_draft.dart';
import '../services/session_log_repository.dart';
import '../utils/app_theme.dart';
import '../utils/extensions.dart';
import '../utils/snackbar_helper.dart';

/// Renders post-call as a bottom-sheet body (no outer Scaffold), so it
/// can be presented via [showPostCallSheet] *or* embedded in the existing
/// `/post-call` route page.
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
            // Pops the bottom sheet (or the /post-call route page if used as one).
            ctx.pop();
          case PostCallPhase.failed:
            SnackbarHelper.showError(
                ctx, state.error ?? 'Could not save session');
          case _:
        }
      },
      builder: (ctx, state) {
        // Bottom-sheet content lifts above the keyboard; SafeArea handles
        // the home indicator on iOS.
        final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.lg + bottomInset,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _SheetHandle(),
                const SizedBox(height: AppSpacing.md),
                switch (state.phase) {
                  PostCallPhase.creating => const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  _ => isMember ? const _MemberSheet() : const _TrainerSheet(),
                },
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Presents [PostCallView] as a modal bottom sheet. Returns when the
/// sheet is dismissed (save completed or user dragged it away).
Future<void> showPostCallSheet(BuildContext context, SessionLogDraft draft) {
  if (draft.memberId == null || draft.trainerId == null) {
    SnackbarHelper.showError(
      context,
      'Session log requires memberId + trainerId.',
    );
    return Future.value();
  }
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true, // lets the sheet expand for the keyboard
    enableDrag: true,
    isDismissible: true,
    showDragHandle: false, // we render our own handle inside
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetCtx) => BlocProvider(
      create: (_) => PostCallCubit(
        repo: SessionLogRepository(),
        draft: draft,
        memberId: draft.memberId!,
        trainerId: draft.trainerId!,
      ),
      child: const PostCallView(),
    ),
  );
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();
  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Theme.of(context).dividerColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
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
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: AppSpacing.lg),
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
              onPressed: () => context.pop(),
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
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: AppSpacing.lg),
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
