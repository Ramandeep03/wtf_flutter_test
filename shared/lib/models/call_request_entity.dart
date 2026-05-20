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

  const CallRequestEntity({
    required this.id,
    required this.memberId,
    required this.trainerId,
    required this.note,
    required this.status,
    required this.requestedAt,
    required this.scheduledFor,
    this.declineReason,
  });

  factory CallRequestEntity.fromJson(Map<String, dynamic> j) => CallRequestEntity(
        id: j['id'] as String,
        memberId: j['memberId'] as String,
        trainerId: j['trainerId'] as String,
        note: (j['note'] ?? '') as String,
        status: j['status'] as String,
        declineReason: j['declineReason'] as String?,
        requestedAt: DateTime.parse(j['requestedAt'] as String),
        scheduledFor: DateTime.parse(j['scheduledFor'] as String),
      );

  bool get isPending  => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isDeclined => status == 'declined';
  bool get isCancelled => status == 'cancelled';

  @override
  List<Object?> get props =>
      [id, memberId, trainerId, note, status, requestedAt, scheduledFor, declineReason];
}

bool canJoinCall(CallRequestEntity r) =>
    r.isApproved &&
    DateTime.now().isAfter(
      r.scheduledFor.subtract(Duration(minutes: AppConstants.joinCallWindowMinutes)),
    );
