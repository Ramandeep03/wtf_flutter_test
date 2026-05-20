import 'package:api_state/api_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../blocs/auth_cubit.dart';
import '../blocs/session_logs_cubit.dart';
import '../models/session_log_entity.dart';
import '../utils/app_theme.dart';
import '../utils/extensions.dart';
import 'error_retry_widget.dart';
import 'skeleton_list.dart';

class SessionsView extends StatelessWidget {
  const SessionsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sessions')),
      body: BlocBuilder<SessionLogsCubit, SessionLogsState>(
        builder: (ctx, state) {
          return Column(
            children: [
              _FilterChips(active: state.filter, onChange: ctx.read<SessionLogsCubit>().setFilter),
              Expanded(child: _body(ctx, state)),
            ],
          );
        },
      ),
    );
  }

  Widget _body(BuildContext ctx, SessionLogsState state) {
    return switch (state.listStatus) {
      ApiInitial() || ApiLoading() => const SkeletonList(itemCount: 4),
      ApiFailure(:final error) => ErrorRetryWidget(
          message: error.message,
          onRetry: () => ctx.read<SessionLogsCubit>().load(),
        ),
      ApiSuccess() when state.displayed.isEmpty => const _EmptyState(),
      ApiSuccess() => RefreshIndicator(
          onRefresh: () => ctx.read<SessionLogsCubit>().load(),
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: state.displayed.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (_, i) => _SessionLogTile(log: state.displayed[i]),
          ),
        ),
      _ => const SizedBox.shrink(),
    };
  }
}

class _FilterChips extends StatelessWidget {
  final LogFilter active;
  final void Function(LogFilter) onChange;
  const _FilterChips({required this.active, required this.onChange});

  static const _items = [
    (LogFilter.all,       'All'),
    (LogFilter.last7Days, 'Last 7 days'),
    (LogFilter.thisMonth, 'This Month'),
  ];

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: _items
              .map((it) => Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: ChoiceChip(
                      label: Text(it.$2),
                      selected: active == it.$1,
                      onSelected: (_) => onChange(it.$1),
                    ),
                  ))
              .toList(),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthCubit>().state.userOrNull;
    final showCta = user?.isMember ?? false;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.md),
            const Text('No sessions yet.', style: AppTypography.body),
            if (showCta) ...[
              const SizedBox(height: AppSpacing.md),
              const Text('Schedule your first call.', style: AppTypography.bodySmall),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: () => context.go('/scheduler'),
                child: const Text('Schedule a call'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SessionLogTile extends StatelessWidget {
  final SessionLogEntity log;
  const _SessionLogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: () => _openDetail(context, log),
        title: Text(log.startedAt.toDateLabel(), style: AppTypography.body),
        subtitle: Text(
          'Duration: ${log.durationSec.toMMSS()}',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        trailing: log.rating == null
            ? const Text('—', style: AppTypography.bodySmall)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < log.rating! ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 16,
                  ),
                ),
              ),
      ),
    );
  }

  void _openDetail(BuildContext context, SessionLogEntity log) {
    final cubit = context.read<SessionLogsCubit>();
    final user = context.read<AuthCubit>().state.userOrNull;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          child: _DetailContent(
            log: log,
            isMember: user?.isMember ?? false,
            onUpdate: ({rating, memberNotes, trainerNotes}) async {
              await cubit.updateLog(
                log.id,
                rating: rating,
                memberNotes: memberNotes,
                trainerNotes: trainerNotes,
              );
              if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
            },
          ),
        ),
      ),
    );
  }
}

class _DetailContent extends StatefulWidget {
  final SessionLogEntity log;
  final bool isMember;
  final Future<void> Function({int? rating, String? memberNotes, String? trainerNotes}) onUpdate;

  const _DetailContent({
    required this.log,
    required this.isMember,
    required this.onUpdate,
  });

  @override
  State<_DetailContent> createState() => _DetailContentState();
}

class _DetailContentState extends State<_DetailContent> {
  int? _rating;
  late final TextEditingController _noteCtrl;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.log.rating;
    final initial = widget.isMember
        ? widget.log.memberNotes
        : widget.log.trainerNotes;
    _noteCtrl = TextEditingController(text: initial ?? '');
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final log = widget.log;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Session — ${log.startedAt.toDateLabel()}',
                  style: AppTypography.h2,
                ),
              ),
              Text(
                'Duration: ${log.durationSec.toMMSS()}',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: List.generate(
              5,
              (i) => Icon(
                i < (log.rating ?? 0) ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 20,
              ),
            ),
          ),
          const Divider(height: AppSpacing.lg * 2),
          const Text('Member Notes:', style: AppTypography.label),
          const SizedBox(height: 4),
          Text(
            (log.memberNotes != null && log.memberNotes!.isNotEmpty)
                ? log.memberNotes!
                : 'No notes added.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          const Text('Trainer Notes:', style: AppTypography.label),
          const SizedBox(height: 4),
          Text(
            (log.trainerNotes != null && log.trainerNotes!.isNotEmpty)
                ? log.trainerNotes!
                : 'No notes added.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (widget.isMember && log.rating == null) ...[
            const Text('Rate Now', style: AppTypography.label),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                5,
                (i) => IconButton(
                  onPressed: () => setState(() => _rating = i + 1),
                  icon: Icon(
                    i < (_rating ?? 0) ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 28,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ElevatedButton(
              onPressed: _rating == null
                  ? null
                  : () => widget.onUpdate(rating: _rating),
              child: const Text('Save Rating'),
            ),
          ],
          if (!widget.isMember || _editing) ...[
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _noteCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: widget.isMember ? 'Edit your note' : 'Edit session notes',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ElevatedButton(
              onPressed: () => widget.onUpdate(
                memberNotes:  widget.isMember ? _noteCtrl.text.trim() : null,
                trainerNotes: !widget.isMember ? _noteCtrl.text.trim() : null,
              ),
              child: const Text('Save Notes'),
            ),
          ] else if (widget.isMember && log.memberNotes == null) ...[
            TextButton.icon(
              onPressed: () => setState(() => _editing = true),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Add a note'),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }
}
