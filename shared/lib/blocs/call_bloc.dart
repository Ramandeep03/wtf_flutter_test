import 'package:api_state/api_state.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../utils/app_logger.dart';

/// Stub event for the join action — full 100ms wiring lands in P13.
sealed class CallEvent extends Equatable {
  const CallEvent();
  @override
  List<Object?> get props => [];
}

class CallJoinRequested extends CallEvent {
  final String roomId;
  final String userId;
  final String userName;
  final String role;

  const CallJoinRequested({
    required this.roomId,
    required this.userId,
    required this.userName,
    required this.role,
  });

  @override
  List<Object?> get props => [roomId, userId, userName, role];
}

/// `ApiStatus<Unit>`-shaped state — same idiom as `StreamChatCubit`.
/// P13 will swap this for a richer state once the 100ms SDK is wired.
typedef CallState = ApiStatus<Unit>;

class CallBloc extends Bloc<CallEvent, CallState> {
  CallBloc() : super(const ApiInitial()) {
    on<CallJoinRequested>(_onJoin);
  }

  Future<void> _onJoin(CallJoinRequested e, Emitter<CallState> emit) async {
    emit(const ApiLoading());
    // P13 will:
    //   1. GET /hms-token?roomId=&role=
    //   2. HMSSDK.join(...) with the returned token
    //   3. Listen to HMSUpdateListener and emit success on join.
    // For now, simulate a successful join so router/UX glue can be tested
    // before the SDK is wired.
    AppLogger.log(LogTag.rtc, 'CallJoinRequested room=${e.roomId} role=${e.role} (stub)');
    emit(const ApiSuccess(unit));
  }
}
