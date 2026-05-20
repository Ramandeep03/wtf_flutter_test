import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/shared.dart';

import '../bloc/my_requests_cubit.dart';

class MyRequestsPage extends StatelessWidget {
  const MyRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthCubit>().state.userOrNull;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return BlocProvider(
      create: (_) => MyRequestsCubit(repo: CallRequestRepository(), memberId: user.uid),
      child: const _MyRequestsView(),
    );
  }
}

class _MyRequestsView extends StatelessWidget {
  const _MyRequestsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Requests')),
      body: RefreshIndicator(
        onRefresh: () => context.read<MyRequestsCubit>().load(),
        child: BlocBuilder<MyRequestsCubit, ApiStatus<List<CallRequestEntity>>>(
          builder: (ctx, state) {
            return switch (state) {
              ApiInitial() || ApiLoading() => const SkeletonList(itemCount: 4),
              ApiFailure(:final error) => ErrorRetryWidget(
                  message: error.message,
                  onRetry: () => ctx.read<MyRequestsCubit>().load(),
                ),
              ApiSuccess(data: final list) when list.isEmpty =>
                const Center(child: Text('No requests yet.', style: AppTypography.body)),
              ApiSuccess(data: final list) => ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (_, i) => _RequestTile(request: list[i]),
                ),
              _ => const SizedBox.shrink(),
            };
          },
        ),
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  final CallRequestEntity request;
  const _RequestTile({required this.request});

  ({Color bg, Color fg, String label, IconData icon}) _badge() {
    if (request.isPending) {
      return (bg: AppColors.warning, fg: Colors.white, label: 'Pending ⏳', icon: Icons.access_time);
    }
    if (request.isApproved) {
      return (bg: AppColors.success, fg: Colors.white, label: 'Approved ✓', icon: Icons.check);
    }
    if (request.isDeclined) {
      return (
        bg: AppColors.error,
        fg: Colors.white,
        label: 'Declined${request.declineReason != null ? ': ${request.declineReason}' : ''}',
        icon: Icons.cancel_outlined,
      );
    }
    return (bg: AppColors.textSecondary, fg: Colors.white, label: request.status, icon: Icons.help_outline);
  }

  @override
  Widget build(BuildContext context) {
    final b = _badge();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${request.scheduledFor.toDateLabel()} · ${request.scheduledFor.toSlotLabel()}',
                    style: AppTypography.body,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: b.bg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(b.label, style: AppTypography.label.copyWith(color: b.fg)),
                ),
              ],
            ),
            if (request.note.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                request.note,
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
            ],
            if (canJoinCall(request)) ...[
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () => requestCallAndNavigate(
                    context,
                    callRequestId: request.id,
                    role: 'member',
                  ),
                  icon: const Icon(Icons.videocam),
                  label: const Text('Join Call'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
