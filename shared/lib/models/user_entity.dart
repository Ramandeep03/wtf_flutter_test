import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String? assignedTrainerId;

  const UserEntity({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.assignedTrainerId,
  });

  factory UserEntity.fromJson(Map<String, dynamic> j) => UserEntity(
        uid: (j['uid'] ?? j['id'] ?? '') as String,
        name: (j['name'] ?? '') as String,
        email: (j['email'] ?? '') as String,
        role: (j['role'] ?? 'member') as String,
        assignedTrainerId: j['assignedTrainerId'] as String?,
      );

  bool get isTrainer => role == 'trainer';
  bool get isMember  => role == 'member';

  @override
  List<Object?> get props => [uid, name, email, role, assignedTrainerId];
}
