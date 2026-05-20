import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hmssdk_flutter/hmssdk_flutter.dart';

import '../services/api_client.dart';
import '../services/call_request_repository.dart';
import '../utils/app_logger.dart';
import '../utils/log_mask.dart';

// ─── Phases ───
enum CallPhase {
  /// Bloc created, no join attempt yet — pre-join screen visible.
  idle,
  /// `CallJoinRequested` in flight, or in-call connection reconnecting.
  joining,
  /// Connected and (potentially) rendering peers.
  inCall,
  /// `CallEndRequested` fired; the page should navigate to /post-call.
  ended,
  /// Terminal HMS error; the page should navigate back or show error.
  failed,
}

// ─── State ───
class CallState extends Equatable {
  final CallPhase phase;
  final List<HMSPeer> peers;
  final bool isMuted;
  final bool isVideoOff;
  final DateTime? joinedAt;
  final String? errorMessage;

  const CallState({
    this.phase = CallPhase.idle,
    this.peers = const [],
    this.isMuted = false,
    this.isVideoOff = false,
    this.joinedAt,
    this.errorMessage,
  });

  CallState copyWith({
    CallPhase? phase,
    List<HMSPeer>? peers,
    bool? isMuted,
    bool? isVideoOff,
    DateTime? joinedAt,
    String? errorMessage,
    bool clearError = false,
  }) =>
      CallState(
        phase: phase ?? this.phase,
        peers: peers ?? this.peers,
        isMuted: isMuted ?? this.isMuted,
        isVideoOff: isVideoOff ?? this.isVideoOff,
        joinedAt: joinedAt ?? this.joinedAt,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );

  @override
  List<Object?> get props => [phase, peers, isMuted, isVideoOff, joinedAt, errorMessage];
}

// ─── Events ───
sealed class CallEvent extends Equatable {
  const CallEvent();
  @override
  List<Object?> get props => [];
}

class CallJoinRequested extends CallEvent {
  final String callRequestId;
  final String roomId;
  final String userId;
  final String userName;
  final String role; // 'member' | 'trainer'
  const CallJoinRequested({
    required this.callRequestId,
    required this.roomId,
    required this.userId,
    required this.userName,
    required this.role,
  });
  @override
  List<Object?> get props => [callRequestId, roomId, userId, userName, role];
}

class CallEndRequested  extends CallEvent { const CallEndRequested(); }
class CallMuteToggled   extends CallEvent { const CallMuteToggled(); }
class CallVideoToggled  extends CallEvent { const CallVideoToggled(); }
class CallCameraFlipped extends CallEvent { const CallCameraFlipped(); }

// Internal — fired from HMS listener callbacks. Public so tests can poke them.
class CallHmsConnected    extends CallEvent { const CallHmsConnected(); }
class CallHmsPeersUpdated extends CallEvent {
  final List<HMSPeer> peers;
  const CallHmsPeersUpdated(this.peers);
  @override
  List<Object?> get props => [peers];
}
class CallHmsReconnecting extends CallEvent { const CallHmsReconnecting(); }
class CallHmsReconnected  extends CallEvent { const CallHmsReconnected(); }
class CallHmsFailed extends CallEvent {
  final String message;
  final bool isTerminal;
  const CallHmsFailed(this.message, {this.isTerminal = false});
  @override
  List<Object?> get props => [message, isTerminal];
}

// ─── Bloc ───
class CallBloc extends Bloc<CallEvent, CallState> implements HMSUpdateListener {
  final ApiClient _api;
  final CallRequestRepository _callRequests;
  final HMSSDK Function() _sdkFactory;
  HMSSDK? _sdk;

  /// Captured from CallJoinRequested so _onEnd knows which request to
  /// mark as ended and whether this side is the trainer.
  String? _callRequestId;
  String? _role;

  CallBloc({
    ApiClient? api,
    CallRequestRepository? callRequests,
    HMSSDK Function()? sdkFactory,
  })  : _api = api ?? ApiClient.instance,
        _callRequests = callRequests ?? CallRequestRepository(),
        _sdkFactory = sdkFactory ?? HMSSDK.new,
        super(const CallState()) {
    on<CallJoinRequested>(_onJoin);
    on<CallEndRequested>(_onEnd);

    on<CallMuteToggled>((_, emit) async {
      await _sdk?.toggleMicMuteState();
      emit(state.copyWith(isMuted: !state.isMuted));
    });
    on<CallVideoToggled>((_, emit) async {
      await _sdk?.toggleCameraMuteState();
      emit(state.copyWith(isVideoOff: !state.isVideoOff));
    });
    on<CallCameraFlipped>((_, __) async => _sdk?.switchCamera());

    on<CallHmsConnected>((_, emit) => emit(state.copyWith(
          phase: CallPhase.inCall,
          joinedAt: state.joinedAt ?? DateTime.now(),
          clearError: true,
        )));
    on<CallHmsPeersUpdated>((e, emit) => emit(state.copyWith(peers: e.peers)));
    on<CallHmsReconnecting>((_, emit) => emit(state.copyWith(phase: CallPhase.joining)));
    on<CallHmsReconnected>((_, emit) => emit(state.copyWith(phase: CallPhase.inCall)));
    on<CallHmsFailed>((e, emit) {
      AppLogger.w(LogTag.rtc, 'HMS error: ${e.message} terminal=${e.isTerminal}');
      if (e.isTerminal) {
        emit(state.copyWith(phase: CallPhase.failed, errorMessage: e.message));
      }
    });
  }

  Future<void> _onJoin(CallJoinRequested e, Emitter<CallState> emit) async {
    _callRequestId = e.callRequestId;
    _role = e.role;
    emit(state.copyWith(phase: CallPhase.joining, clearError: true));
    try {
      final data = await _api.get('/hms-token?roomId=${e.roomId}&role=${e.role}');
      final token = data['token'] as String;
      AppLogger.i(LogTag.rtc,
          'hms token received: ${LogMask.token(token)}; joining roomId=${e.roomId} uid=${LogMask.uid(e.userId)}');

      _sdk = _sdkFactory();
      await _sdk!.build();
      _sdk!.addUpdateListener(listener: this);
      await _sdk!.join(config: HMSConfig(authToken: token, userName: e.userName));
    } catch (err) {
      AppLogger.e(LogTag.rtc, 'join failed: $err');
      emit(state.copyWith(phase: CallPhase.failed, errorMessage: err.toString()));
    }
  }

  Future<void> _onEnd(CallEndRequested _, Emitter<CallState> emit) async {
    await _sdk?.leave();
    emit(state.copyWith(phase: CallPhase.ended));
    AppLogger.i(LogTag.rtc, 'call ended (role=$_role)');

    // Only the trainer pressing End Call closes the request for everyone.
    // A guru leaving just drops them from the room; the trainer can stay.
    if (_role == 'trainer' && _callRequestId != null) {
      final res = await _callRequests.end(_callRequestId!);
      res.fold(
        (f) => AppLogger.w(LogTag.schedule,
            'failed to mark call ended: ${f.message}'),
        (r) => AppLogger.i(LogTag.schedule,
            'call request ${r.id} marked ended at ${r.endedAt}'),
      );
    }
  }

  // ─── HMSUpdateListener ───
  @override
  void onJoin({required HMSRoom room}) {
    AppLogger.i(LogTag.rtc, 'joined roomId=${room.id}');
    add(const CallHmsConnected());
  }

  @override
  void onPeerUpdate({required HMSPeer peer, required HMSPeerUpdate update}) {
    final list = List<HMSPeer>.from(state.peers);
    switch (update) {
      case HMSPeerUpdate.peerJoined:
        list.add(peer);
      case HMSPeerUpdate.peerLeft:
        list.removeWhere((p) => p.peerId == peer.peerId);
      default:
        final i = list.indexWhere((p) => p.peerId == peer.peerId);
        if (i >= 0) {
          list[i] = peer;
        } else {
          list.add(peer);
        }
    }
    add(CallHmsPeersUpdated(list));
  }

  @override
  void onPeerListUpdate({
    required List<HMSPeer> addedPeers,
    required List<HMSPeer> removedPeers,
  }) {
    final list = List<HMSPeer>.from(state.peers)
      ..removeWhere((p) => removedPeers.any((r) => r.peerId == p.peerId))
      ..addAll(addedPeers);
    add(CallHmsPeersUpdated(list));
  }

  @override
  void onHMSError({required HMSException error}) {
    add(CallHmsFailed(
      error.message ?? 'HMS Error',
      isTerminal: error.isTerminal,
    ));
  }

  @override
  void onReconnecting() => add(const CallHmsReconnecting());

  @override
  void onReconnected() => add(const CallHmsReconnected());

  // Unused listener methods — must be present to satisfy the interface.
  @override
  void onRoomUpdate({required HMSRoom room, required HMSRoomUpdate update}) {}
  @override
  void onTrackUpdate({
    required HMSTrack track,
    required HMSTrackUpdate trackUpdate,
    required HMSPeer peer,
  }) {
    // Track changes can affect mute / video-off rendering; rebuild peer
    // list so the UI re-evaluates videoTrack/audioTrack.
    final list = List<HMSPeer>.from(state.peers);
    final i = list.indexWhere((p) => p.peerId == peer.peerId);
    if (i >= 0) list[i] = peer;
    add(CallHmsPeersUpdated(list));
  }
  @override
  void onMessage({required HMSMessage message}) {}
  @override
  void onUpdateSpeakers({required List<HMSSpeaker> updateSpeakers}) {}
  @override
  void onRoleChangeRequest({required HMSRoleChangeRequest roleChangeRequest}) {}
  @override
  void onChangeTrackStateRequest({
    required HMSTrackChangeRequest hmsTrackChangeRequest,
  }) {}
  @override
  void onRemovedFromRoom({
    required HMSPeerRemovedFromPeer hmsPeerRemovedFromPeer,
  }) {
    add(const CallHmsFailed('Removed from room', isTerminal: true));
  }
  @override
  void onAudioDeviceChanged({
    HMSAudioDevice? currentAudioDevice,
    List<HMSAudioDevice>? availableAudioDevice,
  }) {}
  @override
  void onSessionStoreAvailable({HMSSessionStore? hmsSessionStore}) {}

  @override
  Future<void> close() async {
    await _sdk?.leave();
    return super.close();
  }
}
