import 'package:equatable/equatable.dart';

import '../utils/constants.dart';

class CallRequestEntity extends Equatable {
  final String id;
  final String memberId;
  final String trainerId;
  final String note;
  final String status; // pending | approved | declined | cancelled
  final DateTime requestedAt;
  final DateTime scheduledFor;
  final String? declineReason;
  final DateTime? endedAt;

  const CallRequestEntity({
    required this.id,
    required this.memberId,
    required this.trainerId,
    required this.note,
    required this.status,
    required this.requestedAt,
    required this.scheduledFor,
    this.declineReason,
    this.endedAt,
  });

  factory CallRequestEntity.fromJson(Map<String, dynamic> j) => CallRequestEntity(
        id: j['id'] as String,
        memberId: j['memberId'] as String,
        trainerId: j['trainerId'] as String,
        note: (j['note'] ?? '') as String,
        status: j['status'] as String,
        declineReason: j['declineReason'] as String?,
        // Backend stores ISO-UTC; convert to local so .hour/.minute and
        // extensions like toSlotLabel/toDateLabel render in the user's tz.
        requestedAt: DateTime.parse(j['requestedAt'] as String).toLocal(),
        scheduledFor: DateTime.parse(j['scheduledFor'] as String).toLocal(),
        endedAt: j['endedAt'] != null
            ? DateTime.parse(j['endedAt'] as String).toLocal()
            : null,
      );

  bool get isPending   => status == 'pending';
  bool get isApproved  => status == 'approved';
  bool get isDeclined  => status == 'declined';
  bool get isCancelled => status == 'cancelled';

  /// Trainer has ended the call — neither side can rejoin.
  bool get isEnded => endedAt != null;

  @override
  List<Object?> get props => [
        id, memberId, trainerId, note, status,
        requestedAt, scheduledFor, declineReason, endedAt,
      ];
}

/// Show "Join Call" iff the request is approved, the trainer hasn't ended
/// it, and we're within the join window (10 min before scheduledFor → on).
bool canJoinCall(CallRequestEntity r) =>
    r.isApproved &&
    !r.isEnded &&
    DateTime.now().isAfter(
      r.scheduledFor.subtract(Duration(minutes: AppConstants.joinCallWindowMinutes)),
    );
