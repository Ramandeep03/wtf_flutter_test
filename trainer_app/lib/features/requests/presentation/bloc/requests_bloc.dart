import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/shared.dart';

// ───────── Events ─────────

sealed class RequestsEvent extends Equatable {
  const RequestsEvent();
  @override
  List<Object?> get props => [];
}

class RequestsLoaded extends RequestsEvent {
  const RequestsLoaded();
}

class RequestApproved extends RequestsEvent {
  final CallRequestEntity request;
  const RequestApproved(this.request);
  @override
  List<Object?> get props => [request];
}

class RequestDeclined extends RequestsEvent {
  final CallRequestEntity request;
  final String reason;
  const RequestDeclined(this.request, this.reason);
  @override
  List<Object?> get props => [request, reason];
}

// ───────── State ─────────

class RequestsState extends Equatable {
  final ApiStatus<List<CallRequestEntity>> list;
  final Set<String> processingIds;
  final String? lastError;

  const RequestsState({
    this.list = const ApiInitial(),
    this.processingIds = const {},
    this.lastError,
  });

  RequestsState copyWith({
    ApiStatus<List<CallRequestEntity>>? list,
    Set<String>? processingIds,
    String? lastError,
    bool clearError = false,
  }) =>
      RequestsState(
        list: list ?? this.list,
        processingIds: processingIds ?? this.processingIds,
        lastError: clearError ? null : (lastError ?? this.lastError),
      );

  @override
  List<Object?> get props => [list, processingIds, lastError];
}

// ───────── Bloc ─────────

class RequestsBloc extends Bloc<RequestsEvent, RequestsState> {
  final CallRequestRepository _repo;
  final RoomRepository _rooms;
  final String trainerUid;

  RequestsBloc({
    required CallRequestRepository repo,
    required RoomRepository rooms,
    required this.trainerUid,
  })  : _repo = repo,
        _rooms = rooms,
        super(const RequestsState()) {
    on<RequestsLoaded>(_onLoaded);
    on<RequestApproved>(_onApproved);
    on<RequestDeclined>(_onDeclined);
  }

  Future<void> _onLoaded(RequestsLoaded _, Emitter<RequestsState> emit) async {
    emit(state.copyWith(list: const ApiLoading()));
    final res = await _repo.getForTrainer(trainerUid);
    res.fold(
      (f) => emit(state.copyWith(list: ApiFailure<List<CallRequestEntity>>(f))),
      (l) => emit(state.copyWith(list: ApiSuccess(l))),
    );
  }

  Future<void> _onApproved(RequestApproved e, Emitter<RequestsState> emit) async {
    emit(state.copyWith(
      processingIds: {...state.processingIds, e.request.id},
      clearError: true,
    ));

    // 1) POST /rooms → roomMeta (hmsRoomId). Required by the call flow.
    final roomRes = await _rooms.create(e.request.id);
    if (roomRes.isLeft()) {
      final fail = roomRes.fold((f) => f, (_) => null)!;
      AppLogger.log(LogTag.schedule, 'approve failed at /rooms: ${fail.message}');
      emit(state.copyWith(
        processingIds: {...state.processingIds}..remove(e.request.id),
        lastError: 'Could not create call room: ${fail.message}',
      ));
      return;
    }

    // 2) PATCH /call-requests/:id { status:'approved' }
    final patchRes =
        await _repo.updateStatus(e.request.id, 'approved');
    if (patchRes.isLeft()) {
      final fail = patchRes.fold((f) => f, (_) => null)!;
      emit(state.copyWith(
        processingIds: {...state.processingIds}..remove(e.request.id),
        lastError: 'Could not approve: ${fail.message}',
      ));
      return;
    }

    // 3) Stream Chat system message in the DK↔Aarav channel.
    try {
      await sendSystemMessage(
        memberUid: e.request.memberId,
        trainerUid: e.request.trainerId,
        text: 'Call approved for '
            '${e.request.scheduledFor.toSlotLabel()} on '
            '${e.request.scheduledFor.toDateLabel()}.',
      );
    } catch (err) {
      AppLogger.log(LogTag.chat, 'system msg failed (approve): $err');
    }

    // 4) Local notification to DK lives in P14 (cross-app push not in scope).

    // 5) Reload list.
    emit(state.copyWith(
      processingIds: {...state.processingIds}..remove(e.request.id),
    ));
    add(const RequestsLoaded());
  }

  Future<void> _onDeclined(RequestDeclined e, Emitter<RequestsState> emit) async {
    emit(state.copyWith(
      processingIds: {...state.processingIds, e.request.id},
      clearError: true,
    ));

    final patchRes = await _repo.updateStatus(
      e.request.id,
      'declined',
      declineReason: e.reason,
    );
    if (patchRes.isLeft()) {
      final fail = patchRes.fold((f) => f, (_) => null)!;
      emit(state.copyWith(
        processingIds: {...state.processingIds}..remove(e.request.id),
        lastError: 'Could not decline: ${fail.message}',
      ));
      return;
    }

    try {
      await sendSystemMessage(
        memberUid: e.request.memberId,
        trainerUid: e.request.trainerId,
        text: 'Call request declined. Reason: ${e.reason}',
      );
    } catch (err) {
      AppLogger.log(LogTag.chat, 'system msg failed (decline): $err');
    }

    emit(state.copyWith(
      processingIds: {...state.processingIds}..remove(e.request.id),
    ));
    add(const RequestsLoaded());
  }
}
