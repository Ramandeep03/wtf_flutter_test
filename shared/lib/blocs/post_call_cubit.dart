import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../models/session_log_draft.dart';
import '../models/session_log_entity.dart';
import '../services/session_log_repository.dart';
import '../utils/app_logger.dart';

enum PostCallPhase {
  /// POST /session-logs in flight (initial log creation).
  creating,
  /// Log created — user can edit rating / notes.
  ready,
  /// PATCH /session-logs/:id in flight.
  saving,
  /// PATCH succeeded — show snackbar + navigate to /sessions.
  saved,
  /// Either initial create or final PATCH failed; `error` is set.
  failed,
}

class PostCallState extends Equatable {
  final PostCallPhase phase;
  final SessionLogEntity? log;
  final int? rating;
  final String memberNote;
  final String trainerNote;
  final String? error;

  const PostCallState({
    this.phase = PostCallPhase.creating,
    this.log,
    this.rating,
    this.memberNote = '',
    this.trainerNote = '',
    this.error,
  });

  PostCallState copyWith({
    PostCallPhase? phase,
    SessionLogEntity? log,
    int? rating,
    String? memberNote,
    String? trainerNote,
    String? error,
    bool clearError = false,
  }) =>
      PostCallState(
        phase: phase ?? this.phase,
        log: log ?? this.log,
        rating: rating ?? this.rating,
        memberNote: memberNote ?? this.memberNote,
        trainerNote: trainerNote ?? this.trainerNote,
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props => [phase, log, rating, memberNote, trainerNote, error];
}

class PostCallCubit extends Cubit<PostCallState> {
  final SessionLogRepository _repo;
  final SessionLogDraft _draft;
  final String memberId;
  final String trainerId;

  PostCallCubit({
    required SessionLogRepository repo,
    required SessionLogDraft draft,
    required this.memberId,
    required this.trainerId,
    bool autoCreate = true,
  })  : _repo = repo,
        _draft = draft,
        super(const PostCallState()) {
    if (autoCreate) _createLog();
  }

  Future<void> _createLog() async {
    emit(state.copyWith(phase: PostCallPhase.creating, clearError: true));
    final res = await _repo.create(_draft, memberId: memberId, trainerId: trainerId);
    res.fold(
      (f) => emit(state.copyWith(phase: PostCallPhase.failed, error: f.message)),
      (log) {
        AppLogger.i(LogTag.rtc, 'session log created id=${log.id}');
        emit(state.copyWith(phase: PostCallPhase.ready, log: log));
      },
    );
  }

  void setRating(int r)         => emit(state.copyWith(rating: r));
  void setMemberNote(String n)  => emit(state.copyWith(memberNote: n));
  void setTrainerNote(String n) => emit(state.copyWith(trainerNote: n));

  Future<void> save() async {
    final log = state.log;
    if (log == null) return;
    emit(state.copyWith(phase: PostCallPhase.saving, clearError: true));
    final res = await _repo.update(
      log.id,
      rating: state.rating,
      memberNotes:  state.memberNote.trim().isNotEmpty  ? state.memberNote.trim()  : null,
      trainerNotes: state.trainerNote.trim().isNotEmpty ? state.trainerNote.trim() : null,
    );
    res.fold(
      (f) => emit(state.copyWith(phase: PostCallPhase.failed, error: f.message)),
      (updated) {
        AppLogger.i(LogTag.rtc, 'session log saved id=${updated.id}');
        emit(state.copyWith(phase: PostCallPhase.saved, log: updated));
      },
    );
  }
}
