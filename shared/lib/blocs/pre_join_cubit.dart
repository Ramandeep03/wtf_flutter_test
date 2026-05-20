import 'package:api_state/api_state.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../services/api_client.dart';
import '../utils/app_logger.dart';

/// State for the pre-join screen.
///
/// `loadStatus` carries the fetched `hmsRoomId` once `ApiSuccess<String>`.
/// `isMicOn` / `isCameraOn` are pre-call device preferences — the actual
/// hardware track toggles happen once the call starts (P13).
class PreJoinState extends Equatable {
  final ApiStatus<String> loadStatus;
  final bool isMicOn;
  final bool isCameraOn;

  const PreJoinState({
    this.loadStatus = const ApiInitial(),
    this.isMicOn = true,
    this.isCameraOn = true,
  });

  PreJoinState copyWith({
    ApiStatus<String>? loadStatus,
    bool? isMicOn,
    bool? isCameraOn,
  }) =>
      PreJoinState(
        loadStatus: loadStatus ?? this.loadStatus,
        isMicOn: isMicOn ?? this.isMicOn,
        isCameraOn: isCameraOn ?? this.isCameraOn,
      );

  @override
  List<Object?> get props => [loadStatus, isMicOn, isCameraOn];
}

class PreJoinCubit extends Cubit<PreJoinState> {
  final String callRequestId;
  final String role; // 'member' | 'trainer'
  final ApiClient _api;

  PreJoinCubit({
    required this.callRequestId,
    required this.role,
    ApiClient? api,
  })  : _api = api ?? ApiClient.instance,
        super(const PreJoinState()) {
    _loadRoom();
  }

  Future<void> _loadRoom() async {
    emit(state.copyWith(loadStatus: const ApiLoading()));
    try {
      final data = await _api.get('/rooms?callRequestId=$callRequestId');
      final roomId = data['hmsRoomId'] as String;
      AppLogger.log(LogTag.rtc, 'room loaded: $roomId');
      emit(state.copyWith(loadStatus: ApiSuccess(roomId)));
    } on ApiException catch (e) {
      emit(state.copyWith(
        loadStatus: ApiFailure<String>(_RoomFailure(e.message, code: e.statusCode)),
      ));
    } catch (e) {
      emit(state.copyWith(
        loadStatus: ApiFailure<String>(_RoomFailure(e.toString())),
      ));
    }
  }

  void toggleMic()    => emit(state.copyWith(isMicOn: !state.isMicOn));
  void toggleCamera() => emit(state.copyWith(isCameraOn: !state.isCameraOn));
}

class _RoomFailure extends Failure {
  const _RoomFailure(super.message, {super.code});
}
