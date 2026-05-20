import 'package:equatable/equatable.dart';

class SessionLogEntity extends Equatable {
  final String id;
  final String memberId;
  final String trainerId;
  final DateTime startedAt;
  final DateTime endedAt;
  final int durationSec;
  final int? rating;
  final String? memberNotes;
  final String? trainerNotes;

  const SessionLogEntity({
    required this.id,
    required this.memberId,
    required this.trainerId,
    required this.startedAt,
    required this.endedAt,
    required this.durationSec,
    this.rating,
    this.memberNotes,
    this.trainerNotes,
  });

  factory SessionLogEntity.fromJson(Map<String, dynamic> j) => SessionLogEntity(
        id: j['id'] as String,
        memberId: j['memberId'] as String,
        trainerId: j['trainerId'] as String,
        // Backend stores ISO-UTC; convert to local so timestamps render
        // in the user's timezone (see CallRequestEntity for the same fix).
        startedAt: DateTime.parse(j['startedAt'] as String).toLocal(),
        endedAt: DateTime.parse(j['endedAt'] as String).toLocal(),
        durationSec: j['durationSec'] as int,
        rating: j['rating'] as int?,
        memberNotes: j['memberNotes'] as String?,
        trainerNotes: j['trainerNotes'] as String?,
      );

  @override
  List<Object?> get props => [
        id, memberId, trainerId, startedAt, endedAt, durationSec,
        rating, memberNotes, trainerNotes,
      ];
}
