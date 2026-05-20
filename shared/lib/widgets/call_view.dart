import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hmssdk_flutter/hmssdk_flutter.dart';

import '../blocs/call_bloc.dart';
import '../utils/app_logger.dart';
import '../utils/app_theme.dart';
import '../utils/extensions.dart';

/// Mirrors the 100ms Flutter quickstart pattern: this widget owns its own
/// HMSUpdateListener subscription on top of the SDK already created by
/// `CallBloc`, tracks local + remote peer + tracks via setState, and
/// renders them with `HMSVideoView`.
///
/// Two listeners on the same SDK is fine — `addUpdateListener` accumulates,
/// each gets the callbacks. CallBloc still handles phase transitions
/// (joining → inCall → ended/failed) so PreJoinView knows when to swap us
/// in; this widget handles only the actual peer/track UI.
class CallView extends StatefulWidget {
  const CallView({super.key});

  @override
  State<CallView> createState() => _CallViewState();
}

class _CallViewState extends State<CallView> implements HMSUpdateListener {
  HMSSDK? _sdk;

  HMSPeer? localPeer;
  HMSPeer? remotePeer;
  HMSVideoTrack? localPeerVideoTrack;
  HMSVideoTrack? remotePeerVideoTrack;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<CallBloc>();
    final sdk = bloc.sdk;
    _sdk = sdk;
    if (sdk == null) return;
    sdk.addUpdateListener(listener: this);
    // Backfill in case onJoin / onPeerUpdate already fired before we mounted.
    _backfillFromSdk(sdk);
  }

  Future<void> _backfillFromSdk(HMSSDK sdk) async {
    final local = await sdk.getLocalPeer();
    final remotes = await sdk.getRemotePeers();
    if (!mounted) return;
    setState(() {
      if (local != null) {
        localPeer = local;
        localPeerVideoTrack = local.videoTrack;
      }
      if (remotes != null && remotes.isNotEmpty) {
        remotePeer = remotes.first;
        remotePeerVideoTrack = remotes.first.videoTrack;
      }
    });
  }

  @override
  void dispose() {
    _sdk?.removeUpdateListener(listener: this);
    super.dispose();
  }

  // ─── HMSUpdateListener ───
  @override
  void onJoin({required HMSRoom room}) {
    AppLogger.t(LogTag.rtc, 'CallView.onJoin room=${room.id} peers=${room.peers?.length}');
    room.peers?.forEach((peer) {
      if (peer.isLocal) {
        if (!mounted) return;
        setState(() {
          localPeer = peer;
          if (peer.videoTrack != null) localPeerVideoTrack = peer.videoTrack;
        });
      } else {
        if (!mounted) return;
        setState(() {
          remotePeer = peer;
          if (peer.videoTrack != null) remotePeerVideoTrack = peer.videoTrack;
        });
      }
    });
  }

  @override
  void onPeerUpdate({required HMSPeer peer, required HMSPeerUpdate update}) {
    AppLogger.t(LogTag.rtc,
        'CallView.onPeerUpdate ${update.name} peer=${peer.peerId} local=${peer.isLocal}');
    switch (update) {
      case HMSPeerUpdate.peerJoined:
        if (!peer.isLocal && mounted) {
          setState(() => remotePeer = peer);
        }
        break;
      case HMSPeerUpdate.peerLeft:
        if (!peer.isLocal && mounted) {
          setState(() {
            remotePeer = null;
            remotePeerVideoTrack = null;
          });
        }
        break;
      case HMSPeerUpdate.networkQualityUpdated:
        return;
      default:
        // No-op for other peer updates.
        break;
    }
  }

  @override
  void onTrackUpdate({
    required HMSTrack track,
    required HMSTrackUpdate trackUpdate,
    required HMSPeer peer,
  }) {
    AppLogger.t(LogTag.rtc,
        'CallView.onTrackUpdate ${trackUpdate.name} kind=${track.kind} peer=${peer.peerId}');
    if (track.kind != HMSTrackKind.kHMSTrackKindVideo) return;
    switch (trackUpdate) {
      case HMSTrackUpdate.trackRemoved:
        if (!mounted) return;
        setState(() {
          if (peer.isLocal) {
            localPeerVideoTrack = null;
          } else {
            remotePeerVideoTrack = null;
          }
        });
        return;
      default:
        if (!mounted) return;
        setState(() {
          if (peer.isLocal) {
            localPeerVideoTrack = track as HMSVideoTrack;
          } else {
            remotePeer ??= peer;
            remotePeerVideoTrack = track as HMSVideoTrack;
          }
        });
    }
  }

  // Other required HMSUpdateListener methods — no-ops, CallBloc handles them.
  @override
  void onHMSError({required HMSException error}) {}
  @override
  void onMessage({required HMSMessage message}) {}
  @override
  void onReconnecting() {}
  @override
  void onReconnected() {}
  @override
  void onRoomUpdate({required HMSRoom room, required HMSRoomUpdate update}) {}
  @override
  void onUpdateSpeakers({required List<HMSSpeaker> updateSpeakers}) {}
  @override
  void onRoleChangeRequest({required HMSRoleChangeRequest roleChangeRequest}) {}
  @override
  void onChangeTrackStateRequest({required HMSTrackChangeRequest hmsTrackChangeRequest}) {}
  @override
  void onRemovedFromRoom({required HMSPeerRemovedFromPeer hmsPeerRemovedFromPeer}) {}
  @override
  void onAudioDeviceChanged({
    HMSAudioDevice? currentAudioDevice,
    List<HMSAudioDevice>? availableAudioDevice,
  }) {}
  @override
  void onSessionStoreAvailable({HMSSessionStore? hmsSessionStore}) {}
  @override
  void onPeerListUpdate({
    required List<HMSPeer> addedPeers,
    required List<HMSPeer> removedPeers,
  }) {
    if (!mounted) return;
    setState(() {
      for (final p in addedPeers) {
        if (p.isLocal) {
          localPeer = p;
          if (p.videoTrack != null) localPeerVideoTrack = p.videoTrack;
        } else {
          remotePeer = p;
          if (p.videoTrack != null) remotePeerVideoTrack = p.videoTrack;
        }
      }
      for (final p in removedPeers) {
        if (!p.isLocal && p.peerId == remotePeer?.peerId) {
          remotePeer = null;
          remotePeerVideoTrack = null;
        }
      }
    });
  }

  // ─── UI ───
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CallBloc, CallState>(
      builder: (ctx, state) => Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Remote — full screen
            Positioned.fill(child: _peerTile(remotePeerVideoTrack, remotePeer, isLocal: false)),

            // Local — PiP
            Positioned(
              right: 12,
              bottom: 96,
              child: SizedBox(
                width: 100,
                height: 140,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _peerTile(localPeerVideoTrack, localPeer, isLocal: true),
                ),
              ),
            ),

            // Name + timer
            Positioned(
              top: 52,
              left: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (remotePeer != null)
                    Text(
                      remotePeer!.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  _DurationTimer(joinedAt: state.joinedAt),
                ],
              ),
            ),

            // Reconnecting overlay
            if (state.phase == CallPhase.joining && state.joinedAt != null)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text('Reconnecting…',
                          style: TextStyle(color: Colors.white, fontSize: 16)),
                    ],
                  ),
                ),
              ),

            // Controls
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _CallControls(state: state),
            ),
          ],
        ),
      ),
    );
  }

  Widget _peerTile(HMSVideoTrack? videoTrack, HMSPeer? peer, {required bool isLocal}) {
    if (videoTrack != null && !videoTrack.isMute) {
      return HMSVideoView(
        key: ValueKey('${isLocal ? 'local' : 'remote'}-${videoTrack.trackId}'),
        track: videoTrack,
        setMirror: isLocal,
      );
    }
    final initial = (peer?.name.isNotEmpty ?? false)
        ? peer!.name.substring(0, 1).toUpperCase()
        : '?';
    return Container(
      color: Colors.grey[850],
      child: Center(
        child: CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.guruPrimary.withValues(alpha: 0.2),
          child: Text(
            initial,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _CallControls extends StatelessWidget {
  final CallState state;
  const _CallControls({required this.state});

  @override
  Widget build(BuildContext context) => Container(
        color: Colors.black87,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _Btn(
              icon: state.isMuted ? Icons.mic_off : Icons.mic,
              active: !state.isMuted,
              onTap: () => context.read<CallBloc>().add(const CallMuteToggled()),
            ),
            _Btn(
              icon: state.isVideoOff ? Icons.videocam_off : Icons.videocam,
              active: !state.isVideoOff,
              onTap: () => context.read<CallBloc>().add(const CallVideoToggled()),
            ),
            _Btn(
              icon: Icons.flip_camera_android,
              active: true,
              onTap: () => context.read<CallBloc>().add(const CallCameraFlipped()),
            ),
            _Btn(
              icon: Icons.call_end,
              active: false,
              color: AppColors.error,
              onTap: () => context.read<CallBloc>().add(const CallEndRequested()),
            ),
          ],
        ),
      );
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  final Color? color;

  const _Btn({
    required this.icon,
    required this.active,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color ?? (active ? Colors.white24 : Colors.white12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 26),
        ),
      );
}

class _DurationTimer extends StatefulWidget {
  final DateTime? joinedAt;
  const _DurationTimer({required this.joinedAt});

  @override
  State<_DurationTimer> createState() => _DurationTimerState();
}

class _DurationTimerState extends State<_DurationTimer> {
  Timer? _t;
  int _s = 0;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      final joined = widget.joinedAt;
      if (joined == null) return;
      if (!mounted) return;
      setState(() => _s = DateTime.now().difference(joined).inSeconds);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text(
        _s.toMMSS(),
        style: const TextStyle(color: Colors.white70, fontSize: 13),
      );
}
