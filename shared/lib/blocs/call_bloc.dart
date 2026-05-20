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

  /// Video tracks keyed by peerId. Populated from the `track` parameter
  /// in `onTrackUpdate` — we don't rely on `HMSPeer.videoTrack` because
  /// it can lag behind the SDK's track-update events.
  final Map<String, HMSVideoTrack> videoTracks;

  final bool isMuted;
  final bool isVideoOff;
  final DateTime? joinedAt;
  final String? errorMessage;

  const CallState({
    this.phase = CallPhase.idle,
    this.peers = const [],
    this.videoTracks = const {},
    this.isMuted = false,
    this.isVideoOff = false,
    this.joinedAt,
    this.errorMessage,
  });

  CallState copyWith({
    CallPhase? phase,
    List<HMSPeer>? peers,
    Map<String, HMSVideoTrack>? videoTracks,
    bool? isMuted,
    bool? isVideoOff,
    DateTime? joinedAt,
    String? errorMessage,
    bool clearError = false,
  }) =>
      CallState(
        phase: phase ?? this.phase,
        peers: peers ?? this.peers,
        videoTracks: videoTracks ?? this.videoTracks,
        isMuted: isMuted ?? this.isMuted,
        isVideoOff: isVideoOff ?? this.isVideoOff,
        joinedAt: joinedAt ?? this.joinedAt,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );

  /// Signature that changes when peer membership OR track state changes.
  /// `HMSPeer.==` is peerId-only, so without this the bloc's distinct filter
  /// drops emits where the only difference is "remote peer got a video track".
  String get _tracksSignature => videoTracks.entries
      .map((e) => '${e.key}|${e.value.trackId}:${e.value.isMute}')
      .join(',');

  @override
  List<Object?> get props => [
        phase,
        peers.map((p) => p.peerId).join(','),
        _tracksSignature,
        isMuted,
        isVideoOff,
        joinedAt,
        errorMessage,
      ];
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
  final bool startWithMicOff;
  final bool startWithCameraOff;
  const CallJoinRequested({
    required this.callRequestId,
    required this.roomId,
    required this.userId,
    required this.userName,
    required this.role,
    this.startWithMicOff = false,
    this.startWithCameraOff = false,
  });
  @override
  List<Object?> get props => [
        callRequestId, roomId, userId, userName, role,
        startWithMicOff, startWithCameraOff,
      ];
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

/// Video track set/unset for a peer. `track == null` means the peer's
/// video was removed (or muted-and-removed).
class CallHmsVideoTrack extends CallEvent {
  final String peerId;
  final HMSVideoTrack? track;
  const CallHmsVideoTrack(this.peerId, this.track);
  @override
  List<Object?> get props => [peerId, track?.trackId];
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

  /// Exposed so the `CallView` widget can attach its own
  /// HMSUpdateListener on the same SDK instance for setState-based peer
  /// / track rendering (mirrors the 100ms quickstart pattern).
  HMSSDK? get sdk => _sdk;

  /// Captured from CallJoinRequested so _onEnd knows which request to
  /// mark as ended and whether this side is the trainer.
  String? _callRequestId;
  String? _role;
  bool _pendingMicOff = false;
  bool _pendingCameraOff = false;

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

    on<CallHmsConnected>((_, emit) async {
      // Flip the state FIRST so PreJoinView swaps to CallView. Any failure
      // applying the pre-join mic/cam preferences after this must not be
      // allowed to swallow the inCall transition.
      emit(state.copyWith(
        phase: CallPhase.inCall,
        joinedAt: state.joinedAt ?? DateTime.now(),
        isMuted: _pendingMicOff,
        isVideoOff: _pendingCameraOff,
        clearError: true,
      ));
      AppLogger.i(LogTag.rtc,
          'phase=inCall (pendingMicOff=$_pendingMicOff pendingCamOff=$_pendingCameraOff)');

      // Apply pre-join preferences. Wrapped in try/catch so a flaky SDK
      // toggle doesn't bubble up and kill the bloc.
      try {
        if (_pendingMicOff) {
          await _sdk?.toggleMicMuteState();
        }
        if (_pendingCameraOff) {
          await _sdk?.toggleCameraMuteState();
        }
      } catch (e) {
        AppLogger.w(LogTag.rtc, 'failed to apply pre-join mic/cam: $e');
      } finally {
        _pendingMicOff = false;
        _pendingCameraOff = false;
      }
    });
    on<CallHmsPeersUpdated>((e, emit) {
      // Drop video tracks for peers that left.
      final live = e.peers.map((p) => p.peerId).toSet();
      final pruned = {
        for (final entry in state.videoTracks.entries)
          if (live.contains(entry.key)) entry.key: entry.value,
      };
      emit(state.copyWith(peers: e.peers, videoTracks: pruned));
    });

    on<CallHmsVideoTrack>((e, emit) {
      final next = Map<String, HMSVideoTrack>.from(state.videoTracks);
      if (e.track == null) {
        next.remove(e.peerId);
      } else {
        next[e.peerId] = e.track!;
      }
      emit(state.copyWith(videoTracks: next));
    });
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
    _pendingMicOff = e.startWithMicOff;
    _pendingCameraOff = e.startWithCameraOff;
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
    // Either side ending = "End for all". Both peers leave the room and
    // the call request is marked endedAt so the Join Call button hides
    // for both. The other peer receives onRemovedFromRoom which navigates
    // them to /post-call automatically.
    //
    // endRoom requires `end_room` permission on the 100ms role. Trainer
    // template usually grants it; member's template may not. If endRoom
    // is denied, we fall back to leave() — the local user still exits,
    // and the endedAt PATCH below still hides the Join Call button on
    // both apps so the room is effectively dead.
    try {
      await _sdk?.endRoom(lock: false, reason: '$_role ended the call');
    } catch (e) {
      AppLogger.w(LogTag.rtc, 'endRoom failed, leaving instead: $e');
      await _sdk?.leave();
    }

    // Release native HMS resources so the *next* HMSSDK() instance can
    // initialise cleanly. Without destroy() the platform layer holds the
    // previous session and subsequent joins silently fail until the app
    // is fully relaunched.
    _sdk?.destroy();
    _sdk = null;

    emit(state.copyWith(phase: CallPhase.ended));
    AppLogger.i(LogTag.rtc, 'call ended (role=$_role)');

    // Close the call request — Join Call button disappears on both apps
    // because canJoinCall checks !r.isEnded.
    if (_callRequestId != null) {
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
    AppLogger.t(
      LogTag.rtc,
      'track ${trackUpdate.name} kind=${track.kind} peer=${peer.peerId}',
    );

    // Make sure the peer is in our peers list — sometimes track events
    // race ahead of peerJoined.
    final list = List<HMSPeer>.from(state.peers);
    if (list.indexWhere((p) => p.peerId == peer.peerId) < 0) {
      list.add(peer);
      add(CallHmsPeersUpdated(list));
    }

    // Mirror the quickstart: capture the video track passed to this
    // callback directly (don't rely on peer.videoTrack which can be stale).
    if (track.kind == HMSTrackKind.kHMSTrackKindVideo) {
      if (trackUpdate == HMSTrackUpdate.trackRemoved) {
        add(CallHmsVideoTrack(peer.peerId, null));
      } else {
        add(CallHmsVideoTrack(peer.peerId, track as HMSVideoTrack));
      }
    }
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
    _sdk?.destroy();
    _sdk = null;
    return super.close();
  }
}
