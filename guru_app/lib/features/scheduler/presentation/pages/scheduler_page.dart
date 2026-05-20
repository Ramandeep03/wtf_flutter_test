import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

import '../bloc/scheduler_cubit.dart';

class SchedulerPage extends StatelessWidget {
  const SchedulerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthCubit>().state.userOrNull;
    if (user == null || user.assignedTrainerId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Schedule a Call')),
        body: const Center(child: Text('No trainer assigned yet.')),
      );
    }
    return BlocProvider(
      create: (_) => SchedulerCubit(
        repo: CallRequestRepository(),
        memberId: user.uid,
        trainerId: user.assignedTrainerId!,
      ),
      child: const _SchedulerView(),
    );
  }
}

class _SchedulerView extends StatelessWidget {
  const _SchedulerView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SchedulerCubit, SchedulerFormState>(
      listenWhen: (p, c) => p.submitStatus != c.submitStatus,
      listener: (ctx, state) {
        switch (state.submitStatus) {
          case ApiSuccess():
            SnackbarHelper.showSuccess(
              ctx,
              'Call requested. Waiting for trainer approval.',
            );
            ctx.read<SchedulerCubit>().acknowledgeSubmitResult();
            ctx.push('/requests');
          case ApiFailure(:final error):
            SnackbarHelper.showError(ctx, error.message);
            ctx.read<SchedulerCubit>().acknowledgeSubmitResult();
          case _:
        }
      },
      builder: (ctx, state) {
        final cubit = ctx.read<SchedulerCubit>();
        final dates = List<DateTime>.generate(
          3,
          (i) => DateTime.now().add(Duration(days: i)),
        );
        final slots = generateSlots(state.selectedDate);
        final isLoading = state.submitStatus is ApiLoading;

        return Scaffold(
          appBar: AppBar(title: const Text('Schedule a Call')),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                const Text('Pick a day', style: AppTypography.h2),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: dates
                      .map((d) => Padding(
                            padding:
                                const EdgeInsets.only(right: AppSpacing.sm),
                            child: _DayChip(
                              date: d,
                              selected: d.isSameDay(state.selectedDate),
                              onTap: () => cubit.selectDate(d),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: AppSpacing.lg),
                const Text('Pick a time', style: AppTypography.h2),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: slots.map((s) {
                    final isPast = s.isBefore(DateTime.now());
                    final isSelected = state.selectedSlot == s;
                    return _SlotChip(
                      time: s,
                      selected: isSelected,
                      disabled: isPast,
                      onTap: isPast ? null : () => cubit.selectSlot(s),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.lg),
                const Text('Note (optional)', style: AppTypography.h2),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  maxLength: AppConstants.maxNoteLength,
                  decoration: const InputDecoration(
                    hintText: 'What would you like to discuss?',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: cubit.updateNote,
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (state.selectedSlot == null || isLoading)
                        ? null
                        : cubit.submit,
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Request Call'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DayChip extends StatelessWidget {
  final DateTime date;
  final bool selected;
  final VoidCallback onTap;
  const _DayChip(
      {required this.date, required this.selected, required this.onTap});

  String _label() {
    final today = DateTime.now();
    if (date.isSameDay(today)) return 'Today';
    if (date.isSameDay(today.add(const Duration(days: 1)))) return 'Tomorrow';
    return date.toDateLabel();
  }

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AppColors.guruPrimary : Colors.transparent;
    final fg = selected ? Colors.white : AppColors.textPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.guruPrimary),
        ),
        child:
            Text(_label(), style: AppTypography.bodySmall.copyWith(color: fg)),
      ),
    );
  }
}

class _SlotChip extends StatelessWidget {
  final DateTime time;
  final bool selected;
  final bool disabled;
  final VoidCallback? onTap;
  const _SlotChip({
    required this.time,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    if (disabled) {
      bg = AppColors.bgSurface;
      fg = AppColors.textSecondary;
    } else if (selected) {
      bg = AppColors.guruPrimary;
      fg = Colors.white;
    } else {
      bg = Colors.transparent;
      fg = AppColors.textPrimary;
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: disabled ? AppColors.borderLight : AppColors.guruPrimary,
          ),
        ),
        child: Text(time.toSlotLabel(),
            style: AppTypography.bodySmall.copyWith(color: fg)),
      ),
    );
  }
}
