import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hmssdk_flutter/hmssdk_flutter.dart';

import '../blocs/call_bloc.dart';
import '../utils/app_theme.dart';
import '../utils/extensions.dart';

class CallView extends StatelessWidget {
  const CallView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CallBloc, CallState>(
      builder: (ctx, state) {
        final local  = state.peers.firstWhereOrNull((p) => p.isLocal);
        final remote = state.peers.firstWhereOrNull((p) => !p.isLocal);
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // Remote — full screen
              _RemoteView(remote: remote),

              // Local — PiP
              Positioned(
                right: 12,
                bottom: 96,
                child: SizedBox(
                  width: 100,
                  height: 140,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: state.isVideoOff || local?.videoTrack == null
                        ? Container(
                            color: Colors.grey[800],
                            child: const Icon(Icons.person, color: Colors.white, size: 40),
                          )
                        : HMSTextureView(track: local!.videoTrack!, setMirror: true),
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
                    if (remote != null)
                      Text(
                        remote.name,
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
                        Text(
                          'Reconnecting…',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
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
        );
      },
    );
  }

}

class _RemoteView extends StatelessWidget {
  final HMSPeer? remote;
  const _RemoteView({required this.remote});

  @override
  Widget build(BuildContext context) {
    final track = remote?.videoTrack;
    if (track == null) {
      return const Center(
        child: Text(
          'Waiting for other participant…',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      );
    }
    return HMSTextureView(track: track);
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
