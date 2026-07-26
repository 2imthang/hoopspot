import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';

/// Maps [UserEntity] to/from the `users/{uid}` Firestore document. `uid` is
/// the document ID, not a stored field, so it's passed in separately on read.
class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    required super.email,
    required super.displayName,
    required super.role,
    required super.status,
    super.rejectReason,
    super.avatarUrl,
    required super.createdAt,
  });

  factory UserModel.fromFirestore(String uid, Map<String, dynamic> data) {
    return UserModel(
      uid: uid,
      email: data['email'] as String,
      displayName: data['displayName'] as String,
      role: UserRole.values.byName(data['role'] as String),
      status: UserStatus.values.byName(data['status'] as String),
      rejectReason: data['rejectReason'] as String?,
      avatarUrl: data['avatarUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'role': role.name,
      'status': status.name,
      'rejectReason': rejectReason,
      'avatarUrl': avatarUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
