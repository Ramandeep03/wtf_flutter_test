import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/shared.dart';

import '../bloc/requests_bloc.dart';

class RequestsPage extends StatelessWidget {
  const RequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthCubit>().state.userOrNull;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return BlocProvider(
      create: (_) => RequestsBloc(
        repo: CallRequestRepository(),
        rooms: RoomRepository(),
        trainerUid: user.uid,
      )..add(const RequestsLoaded()),
      child: const _RequestsView(),
    );
  }
}

class _RequestsView extends StatelessWidget {
  const _RequestsView();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Requests'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Pending'), Tab(text: 'All')],
          ),
        ),
        body: BlocConsumer<RequestsBloc, RequestsState>(
          listenWhen: (p, c) => p.lastError != c.lastError && c.lastError != null,
          listener: (ctx, state) {
            SnackbarHelper.showError(ctx, state.lastError!);
          },
          builder: (ctx, state) {
            return switch (state.list) {
              ApiInitial() || ApiLoading() => const SkeletonList(itemCount: 4),
              ApiFailure(:final error) => ErrorRetryWidget(
                  message: error.message,
                  onRetry: () => ctx.read<RequestsBloc>().add(const RequestsLoaded()),
                ),
              ApiSuccess(data: final list) => TabBarView(
                  children: [
                    _RequestList(
                      requests: list.where((r) => r.isPending).toList(),
                      processingIds: state.processingIds,
                      emptyText: 'No pending requests.',
                    ),
                    _RequestList(
                      requests: list,
                      processingIds: state.processingIds,
                      emptyText: 'No requests yet.',
                    ),
                  ],
                ),
              _ => const SizedBox.shrink(),
            };
          },
        ),
      ),
    );
  }
}

class _RequestList extends StatelessWidget {
  final List<CallRequestEntity> requests;
  final Set<String> processingIds;
  final String emptyText;

  const _RequestList({
    required this.requests,
    required this.processingIds,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return Center(child: Text(emptyText, style: AppTypography.body));
    }
    return RefreshIndicator(
      onRefresh: () async =>
          context.read<RequestsBloc>().add(const RequestsLoaded()),
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: requests.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, i) => _RequestTile(
          request: requests[i],
          processing: processingIds.contains(requests[i].id),
        ),
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  final CallRequestEntity request;
  final bool processing;

  const _RequestTile({required this.request, required this.processing});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.trainerPrimary,
                  child: Text('D', style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('DK', style: AppTypography.body),
                      Text(
                        'Requested ${request.requestedAt.toRelativeString()}',
                        style: AppTypography.label.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (request.note.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(request.note, style: AppTypography.bodySmall),
            ],
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${request.scheduledFor.toDateLabel()} · ${request.scheduledFor.toSlotLabel()}',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
            if (request.isPending) ...[
              const SizedBox(height: AppSpacing.md),
              if (processing)
                const Center(child: CircularProgressIndicator())
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _openDeclineSheet(context),
                        child: const Text('Decline'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => context
                            .read<RequestsBloc>()
                            .add(RequestApproved(request)),
                        child: const Text('Approve'),
                      ),
                    ),
                  ],
                ),
            ] else if (request.isApproved && canJoinCall(request)) ...[
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () => requestCallAndNavigate(
                    context,
                    callRequestId: request.id,
                    role: 'trainer',
                    memberId: request.memberId,
                    trainerId: request.trainerId,
                  ),
                  icon: const Icon(Icons.videocam),
                  label: const Text('Join Call'),
                ),
              ),
            ] else if (request.isDeclined && request.declineReason != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Declined: ${request.declineReason}',
                style: AppTypography.label.copyWith(color: AppColors.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openDeclineSheet(BuildContext context) {
    final bloc = context.read<RequestsBloc>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + AppSpacing.lg,
        ),
        child: _DeclineForm(
          onConfirm: (reason) {
            Navigator.of(sheetCtx).pop();
            bloc.add(RequestDeclined(request, reason));
          },
        ),
      ),
    );
  }
}

class _DeclineForm extends StatefulWidget {
  final void Function(String reason) onConfirm;
  const _DeclineForm({required this.onConfirm});

  @override
  State<_DeclineForm> createState() => _DeclineFormState();
}

class _DeclineFormState extends State<_DeclineForm> {
  final _ctrl = TextEditingController();
  String _text = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Reason for declining', style: AppTypography.h2),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _ctrl,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Tell DK why you can\'t make it…',
            border: OutlineInputBorder(),
          ),
          onChanged: (v) => setState(() => _text = v),
        ),
        const SizedBox(height: AppSpacing.md),
        ElevatedButton(
          onPressed: _text.trim().isEmpty
              ? null
              : () => widget.onConfirm(_text.trim()),
          child: const Text('Confirm Decline'),
        ),
      ],
    );
  }
}
