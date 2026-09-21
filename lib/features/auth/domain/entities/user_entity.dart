import 'package:equatable/equatable.dart';

enum UserRole { user, owner, admin }

enum UserStatus { active, pending, rejected, locked }

class UserEntity extends Equatable {
  final String uid;
  final String email;
  final String displayName;
  final String phone;
  final UserRole role;
  final UserStatus status;
  final String? rejectReason;
  final String? avatarUrl;
  final DateTime createdAt;

  const UserEntity({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.phone,
    required this.role,
    required this.status,
    this.rejectReason,
    this.avatarUrl,
    required this.createdAt,
  });

  UserEntity copyWith({UserStatus? status}) {
    return UserEntity(
      uid: uid,
      email: email,
      displayName: displayName,
      phone: phone,
      role: role,
      status: status ?? this.status,
      rejectReason: rejectReason,
      avatarUrl: avatarUrl,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
    uid,
    email,
    displayName,
    phone,
    role,
    status,
    rejectReason,
    avatarUrl,
    createdAt,
  ];
}
