import 'package:equatable/equatable.dart';

/// Carried via `GoRouter` extra from the in-call screen to `/post-call`
/// so the post-call screen can POST `/session-logs` with the right times.
class SessionLogDraft extends Equatable {
  final DateTime joinedAt;
  final DateTime endedAt;
  final String? memberId;
  final String? trainerId;

  const SessionLogDraft({
    required this.joinedAt,
    required this.endedAt,
    this.memberId,
    this.trainerId,
  });

  int get durationSec => endedAt.difference(joinedAt).inSeconds;

  @override
  List<Object?> get props => [joinedAt, endedAt, memberId, trainerId];
}
