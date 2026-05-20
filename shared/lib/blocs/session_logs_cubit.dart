import 'package:api_state/api_state.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../models/session_log_entity.dart';
import '../services/session_log_repository.dart';

enum LogFilter { all, last7Days, thisMonth }

class SessionLogsState extends Equatable {
  final ApiStatus<List<SessionLogEntity>> listStatus;
  final LogFilter filter;
  final String? lastUpdateError;

  const SessionLogsState({
    this.listStatus = const ApiInitial(),
    this.filter = LogFilter.all,
    this.lastUpdateError,
  });

  /// Logs after applying `filter`, sorted newest first.
  List<SessionLogEntity> get displayed {
    final all = switch (listStatus) {
      ApiSuccess(:final data) => data,
      ApiRefresh(:final data) => data,
      _ => const <SessionLogEntity>[],
    };
    final now = DateTime.now();
    final filtered = switch (filter) {
      LogFilter.all => all,
      LogFilter.last7Days => all
          .where((l) => l.startedAt.isAfter(now.subtract(const Duration(days: 7))))
          .toList(),
      LogFilter.thisMonth => all
          .where((l) => l.startedAt.year == now.year && l.startedAt.month == now.month)
          .toList(),
    };
    return [...filtered]..sort((a, b) => b.startedAt.compareTo(a.startedAt));
  }

  SessionLogsState copyWith({
    ApiStatus<List<SessionLogEntity>>? listStatus,
    LogFilter? filter,
    String? lastUpdateError,
    bool clearError = false,
  }) =>
      SessionLogsState(
        listStatus: listStatus ?? this.listStatus,
        filter: filter ?? this.filter,
        lastUpdateError:
            clearError ? null : (lastUpdateError ?? this.lastUpdateError),
      );

  @override
  List<Object?> get props => [listStatus, filter, lastUpdateError];
}

class SessionLogsCubit extends Cubit<SessionLogsState> {
  final SessionLogRepository _repo;
  final String userId;

  SessionLogsCubit({required SessionLogRepository repo, required this.userId})
      : _repo = repo,
        super(const SessionLogsState()) {
    load();
  }

  Future<void> load() async {
    emit(state.copyWith(listStatus: const ApiLoading()));
    final res = await _repo.getForUser(userId);
    res.fold(
      (f) => emit(state.copyWith(
        listStatus: ApiFailure<List<SessionLogEntity>>(f),
      )),
      (l) => emit(state.copyWith(listStatus: ApiSuccess(l))),
    );
  }

  void setFilter(LogFilter f) => emit(state.copyWith(filter: f));

  Future<void> updateLog(
    String id, {
    int? rating,
    String? memberNotes,
    String? trainerNotes,
  }) async {
    final res = await _repo.update(
      id,
      rating: rating,
      memberNotes: memberNotes,
      trainerNotes: trainerNotes,
    );
    res.fold(
      (f) => emit(state.copyWith(lastUpdateError: f.message)),
      (_) => load(),
    );
  }
}
